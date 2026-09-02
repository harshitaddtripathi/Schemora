import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schemora_frontend/core/network/api_client.dart';
import 'package:schemora_frontend/features/saved_schemes/domain/saved_scheme_model.dart';

abstract class SavedSchemeRepository {
  Future<SavedSchemeItemModel> toggleSave(String schemeId);
  Future<List<SavedSchemeItemModel>> listSavedSchemes();
  Future<SavedSchemeItemModel> updateStatus(String schemeId, String status, {String? notes});
  Future<void> createReminder(String schemeId, String title, String reminderDate);
  Future<void> logPortalEvent(String schemeId);
}

class SavedSchemeRepositoryImpl implements SavedSchemeRepository {
  final Dio _dio;

  static final Set<String> _localSavedIds = {
    'sch-central-csss-001',
    'sch-central-pmis-003',
  };

  static final List<SavedSchemeItemModel> _fallbackSavedItems = [
    SavedSchemeItemModel(
      id: 'sav-001',
      schemeId: 'sch-central-csss-001',
      schemeTitle: 'Central Sector Scheme of Scholarship for College Students',
      provider: 'Ministry of Education',
      jurisdiction: 'Central',
      status: 'Saved',
      updatedAt: '2026-09-01T12:00:00Z',
    ),
    SavedSchemeItemModel(
      id: 'sav-002',
      schemeId: 'sch-central-pmis-003',
      schemeTitle: 'PM Internship Scheme (MY Bharat)',
      provider: 'Ministry of Corporate Affairs',
      jurisdiction: 'Central',
      status: 'AppliedOnOfficialPortal',
      updatedAt: '2026-09-01T12:00:00Z',
    ),
  ];

  SavedSchemeRepositoryImpl(this._dio);

  @override
  Future<SavedSchemeItemModel> toggleSave(String schemeId) async {
    try {
      final response = await _dio.post('/saved-schemes/$schemeId/toggle-save');
      return SavedSchemeItemModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (_) {
      if (_localSavedIds.contains(schemeId)) {
        _localSavedIds.remove(schemeId);
      } else {
        _localSavedIds.add(schemeId);
      }
      return SavedSchemeItemModel(
        id: 'sav-local-$schemeId',
        schemeId: schemeId,
        schemeTitle: 'Saved Scheme',
        provider: 'Government',
        jurisdiction: 'Central',
        status: 'Saved',
        updatedAt: '2026-09-01T12:00:00Z',
      );
    }
  }

  @override
  Future<List<SavedSchemeItemModel>> listSavedSchemes() async {
    try {
      final response = await _dio.get('/saved-schemes');
      final list = response.data['data'] as List<dynamic>;
      return list.map((item) => SavedSchemeItemModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return _fallbackSavedItems.where((item) => _localSavedIds.contains(item.schemeId)).toList();
    }
  }

  @override
  Future<SavedSchemeItemModel> updateStatus(String schemeId, String status, {String? notes}) async {
    try {
      final response = await _dio.put(
        '/saved-schemes/$schemeId/status',
        data: {'status': status, if (notes != null) 'notes': notes},
      );
      return SavedSchemeItemModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (_) {
      return SavedSchemeItemModel(
        id: 'sav-local-$schemeId',
        schemeId: schemeId,
        schemeTitle: 'Saved Scheme',
        provider: 'Government',
        jurisdiction: 'Central',
        status: status,
        updatedAt: '2026-09-01T12:00:00Z',
      );
    }
  }

  @override
  Future<void> createReminder(String schemeId, String title, String reminderDate) async {
    try {
      await _dio.post(
        '/saved-schemes/$schemeId/reminders',
        data: {'title': title, 'reminder_date': reminderDate},
      );
    } catch (_) {}
  }

  @override
  Future<void> logPortalEvent(String schemeId) async {
    try {
      await _dio.post(
        '/analytics/event',
        data: {
          'event_type': 'OfficialPortalOpened',
          'scheme_id': schemeId,
        },
      );
    } catch (_) {}
  }
}

final savedSchemeRepositoryProvider = Provider<SavedSchemeRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return SavedSchemeRepositoryImpl(dio);
});

final savedSchemeIdsProvider =
    StateNotifierProvider<SavedSchemeIdsNotifier, AsyncValue<Set<String>>>((ref) {
  final repo = ref.watch(savedSchemeRepositoryProvider);
  return SavedSchemeIdsNotifier(repo);
});

class SavedSchemeIdsNotifier extends StateNotifier<AsyncValue<Set<String>>> {
  final SavedSchemeRepository _repo;

  SavedSchemeIdsNotifier(this._repo) : super(const AsyncValue.loading()) {
    loadSavedSchemes();
  }

  Future<void> loadSavedSchemes() async {
    try {
      final list = await _repo.listSavedSchemes();
      final ids = list.map((item) => item.schemeId).toSet();
      state = AsyncValue.data(ids);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> toggleSave(String schemeId) async {
    final currentIds = state.value ?? {};
    final isSaved = currentIds.contains(schemeId);

    // Optimistic UI update
    final newSet = Set<String>.from(currentIds);
    if (isSaved) {
      newSet.remove(schemeId);
    } else {
      newSet.add(schemeId);
    }
    state = AsyncValue.data(newSet);

    try {
      await _repo.toggleSave(schemeId);
      await loadSavedSchemes(); // Re-sync with server
      return !isSaved;
    } catch (e) {
      // Rollback state on error
      state = AsyncValue.data(currentIds);
      rethrow;
    }
  }
}

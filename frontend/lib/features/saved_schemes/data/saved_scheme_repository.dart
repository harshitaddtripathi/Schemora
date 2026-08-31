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

  SavedSchemeRepositoryImpl(this._dio);

  @override
  Future<SavedSchemeItemModel> toggleSave(String schemeId) async {
    final response = await _dio.post('/saved-schemes/$schemeId/toggle-save');
    return SavedSchemeItemModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<List<SavedSchemeItemModel>> listSavedSchemes() async {
    final response = await _dio.get('/saved-schemes');
    final list = response.data['data'] as List<dynamic>;
    return list.map((item) => SavedSchemeItemModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  @override
  Future<SavedSchemeItemModel> updateStatus(String schemeId, String status, {String? notes}) async {
    final response = await _dio.put(
      '/saved-schemes/$schemeId/status',
      data: {'status': status, if (notes != null) 'notes': notes},
    );
    return SavedSchemeItemModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> createReminder(String schemeId, String title, String reminderDate) async {
    await _dio.post(
      '/saved-schemes/$schemeId/reminders',
      data: {'title': title, 'reminder_date': reminderDate},
    );
  }

  @override
  Future<void> logPortalEvent(String schemeId) async {
    await _dio.post(
      '/analytics/event',
      data: {
        'event_type': 'OfficialPortalOpened',
        'scheme_id': schemeId,
      },
    );
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

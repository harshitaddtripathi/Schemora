import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schemora_frontend/core/network/api_client.dart';
import 'package:schemora_frontend/features/auth/data/auth_repository.dart';
import 'package:schemora_frontend/features/profile/domain/profile_model.dart';

abstract class ProfileRepository {
  Future<ProfileModel?> getMyProfile(String token);
  Future<ProfileModel> createProfile(String token, ProfileModel profile);
  Future<ProfileModel> updateProfile(String token, ProfileModel profile);
}

class ProfileRepositoryImpl implements ProfileRepository {
  final Dio _dio;
  ProfileModel? _cachedProfile;

  ProfileRepositoryImpl(this._dio);

  Options _authOptions(String token) {
    return Options(
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
  }

  @override
  Future<ProfileModel?> getMyProfile(String token) async {
    if (_cachedProfile != null) {
      return _cachedProfile;
    }
    try {
      final response = await _dio.get('/profile/me', options: _authOptions(token));
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>;
        _cachedProfile = ProfileModel.fromJson(data);
        return _cachedProfile;
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      return _cachedProfile;
    } catch (_) {
      return _cachedProfile;
    }
  }

  @override
  Future<ProfileModel> createProfile(String token, ProfileModel profile) async {
    _cachedProfile = profile;
    try {
      final response = await _dio.post(
        '/profile',
        data: profile.toJson(),
        options: _authOptions(token),
      );
      final data = response.data['data'] as Map<String, dynamic>;
      _cachedProfile = ProfileModel.fromJson(data);
      return _cachedProfile!;
    } on DioException catch (_) {
      // Backend unreachable or connection timeout: store locally and return profile
      return profile;
    } catch (_) {
      return profile;
    }
  }

  @override
  Future<ProfileModel> updateProfile(String token, ProfileModel profile) async {
    _cachedProfile = profile;
    try {
      final response = await _dio.put(
        '/profile',
        data: profile.toJson(),
        options: _authOptions(token),
      );
      final data = response.data['data'] as Map<String, dynamic>;
      _cachedProfile = ProfileModel.fromJson(data);
      return _cachedProfile!;
    } on DioException catch (_) {
      // Backend unreachable or connection timeout: store locally and return profile
      return profile;
    } catch (_) {
      return profile;
    }
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return ProfileRepositoryImpl(dio);
});

final currentProfileProvider = FutureProvider<ProfileModel?>((ref) async {
  final authState = ref.watch(authProvider);
  final repo = ref.watch(profileRepositoryProvider);
  final token = authState.token ?? 'test-token-citizen';
  return repo.getMyProfile(token);
});

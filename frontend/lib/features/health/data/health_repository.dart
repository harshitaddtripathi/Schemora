import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schemora_frontend/core/network/api_client.dart';
import 'package:schemora_frontend/features/health/domain/health_status.dart';

abstract class HealthRepository {
  Future<HealthStatus> checkHealth();
}

class HealthRepositoryImpl implements HealthRepository {
  final Dio _dio;

  HealthRepositoryImpl(this._dio);

  @override
  Future<HealthStatus> checkHealth() async {
    final response = await _dio.get('/health');
    if (response.statusCode == 200 && response.data != null) {
      final data = response.data['data'] as Map<String, dynamic>;
      return HealthStatus.fromJson(data);
    } else {
      throw Exception('Failed to connect to Schemora API: ${response.statusCode}');
    }
  }
}

final healthRepositoryProvider = Provider<HealthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return HealthRepositoryImpl(dio);
});

final healthStatusProvider = FutureProvider<HealthStatus>((ref) async {
  final repo = ref.watch(healthRepositoryProvider);
  return repo.checkHealth();
});

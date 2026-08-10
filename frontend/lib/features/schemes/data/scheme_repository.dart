import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schemora_frontend/core/network/api_client.dart';
import 'package:schemora_frontend/features/auth/data/auth_repository.dart';
import 'package:schemora_frontend/features/schemes/domain/scheme_model.dart';

abstract class SchemeRepository {
  Future<List<SchemeModel>> getSchemes({String? query, String? jurisdiction});
  Future<SchemeModel> getSchemeDetails(String schemeId);
  Future<List<RecommendationItemModel>> getTop3Recommendations(String token);
}

class SchemeRepositoryImpl implements SchemeRepository {
  final Dio _dio;

  SchemeRepositoryImpl(this._dio);

  @override
  Future<List<SchemeModel>> getSchemes({String? query, String? jurisdiction}) async {
    final response = await _dio.get(
      '/schemes',
      queryParameters: {
        if (query != null && query.isNotEmpty) 'q': query,
        if (jurisdiction != null && jurisdiction.isNotEmpty) 'jurisdiction': jurisdiction,
      },
    );
    final data = response.data['data'] as List<dynamic>;
    return data.map((e) => SchemeModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<SchemeModel> getSchemeDetails(String schemeId) async {
    final response = await _dio.get('/schemes/$schemeId');
    final data = response.data['data'] as Map<String, dynamic>;
    return SchemeModel.fromJson(data);
  }

  @override
  Future<List<RecommendationItemModel>> getTop3Recommendations(String token) async {
    final response = await _dio.post(
      '/schemes/recommendations',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    final data = response.data['data']['top3_recommendations'] as List<dynamic>;
    return data.map((e) => RecommendationItemModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}

final schemeRepositoryProvider = Provider<SchemeRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return SchemeRepositoryImpl(dio);
});

final top3RecommendationsProvider = FutureProvider<List<RecommendationItemModel>>((ref) async {
  final authState = ref.watch(authProvider);
  final token = authState.token ?? 'test-token-citizen';
  final repo = ref.watch(schemeRepositoryProvider);
  return repo.getTop3Recommendations(token);
});

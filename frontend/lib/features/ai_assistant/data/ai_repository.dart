import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schemora_frontend/core/network/api_client.dart';

abstract class AIRepository {
  Future<Map<String, dynamic>> askAssistant(String question, {String? schemeId, String language = 'en'});
}

class AIRepositoryImpl implements AIRepository {
  final Dio _dio;

  AIRepositoryImpl(this._dio);

  @override
  Future<Map<String, dynamic>> askAssistant(String question, {String? schemeId, String language = 'en'}) async {
    final response = await _dio.post(
      '/ai/chat',
      data: {
        'question': question,
        if (schemeId != null) 'scheme_id': schemeId,
        'language': language,
      },
    );
    return response.data['data'] as Map<String, dynamic>;
  }
}

final aiRepositoryProvider = Provider<AIRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return AIRepositoryImpl(dio);
});

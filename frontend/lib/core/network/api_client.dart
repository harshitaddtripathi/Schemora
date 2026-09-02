import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schemora_frontend/core/config/env_config.dart';

final dioProvider = Provider<Dio>((ref) {
  final activeBaseUrl = EnvConfig.baseUrl;

  debugPrint('===========================================================');
  debugPrint('[Schemora API Client] Base URL: $activeBaseUrl');
  debugPrint('===========================================================');

  final dio = Dio(
    BaseOptions(
      baseUrl: activeBaseUrl,
      connectTimeout: const Duration(milliseconds: EnvConfig.connectTimeoutMs),
      receiveTimeout: const Duration(milliseconds: EnvConfig.receiveTimeoutMs),
      sendTimeout: const Duration(milliseconds: EnvConfig.sendTimeoutMs),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (options.path.startsWith('/')) {
          options.path = options.path.substring(1);
        }
        debugPrint('[HTTP REQUEST] ${options.method} ${options.uri}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint('[HTTP RESPONSE] ${response.statusCode} ${response.requestOptions.uri}');
        return handler.next(response);
      },
      onError: (DioException error, handler) {
        debugPrint('[HTTP ERROR] ${error.type} ${error.requestOptions.uri}: ${error.message}');
        return handler.next(error);
      },
    ),
  );

  return dio;
});

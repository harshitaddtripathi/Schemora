import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schemora_frontend/core/config/env_config.dart';

final dioProvider = Provider<Dio>((ref) {
  final activeBaseUrl = EnvConfig.baseUrl;

  debugPrint('===========================================================');
  debugPrint('[Schemora API Client] Active Base URL: $activeBaseUrl');
  debugPrint('===========================================================');

  final dio = Dio(
    BaseOptions(
      baseUrl: activeBaseUrl,
      connectTimeout: const Duration(milliseconds: EnvConfig.connectTimeoutMs),
      receiveTimeout: const Duration(milliseconds: EnvConfig.receiveTimeoutMs),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        // Strip leading slash from relative paths when baseUrl has a path prefix (/api/v1/).
        if (options.path.startsWith('/')) {
          options.path = options.path.substring(1);
        }
        final fullUri = options.uri;
        debugPrint('[HTTP REQUEST] ${options.method} $fullUri');
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

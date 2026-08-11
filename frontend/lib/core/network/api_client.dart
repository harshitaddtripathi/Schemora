import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schemora_frontend/core/config/env_config.dart';

final dioProvider = Provider<Dio>((ref) {
  // EnvConfig.baseUrl is a runtime getter — evaluated here so Platform.isAndroid
  // is read after the Flutter engine is initialized (not as a compile-time const).
  final dio = Dio(
    BaseOptions(
      baseUrl: EnvConfig.baseUrl,
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
        // Option to add authorization token when available
        return handler.next(options);
      },
      onError: (DioException error, handler) {
        return handler.next(error);
      },
    ),
  );

  return dio;
});

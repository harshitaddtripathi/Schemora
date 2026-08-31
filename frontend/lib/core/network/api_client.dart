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
      onError: (DioException error, handler) async {
        debugPrint('[HTTP ERROR] ${error.type} ${error.requestOptions.uri}: ${error.message}');

        // Auto-fallback for connection errors (unreachable LAN IP / firewall / USB / emulator)
        if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.connectionError) {
          final candidates = [
            '127.0.0.1',           // USB ADB reverse port forwarding (Instant, bypasses Wi-Fi firewall)
            EnvConfig.devHostIp,   // Active Wi-Fi IP (192.168.3.148)
            '10.0.2.2',            // Android Emulator
          ];

          for (final candidateHost in candidates) {
            final testBaseUrl = 'http://$candidateHost:${EnvConfig.devPort}/api/v1/';
            if (error.requestOptions.baseUrl == testBaseUrl) continue; // Skip same failing URL

            try {
              debugPrint('[HTTP RETRY] Trying fallback host: $candidateHost');
              final retryOptions = error.requestOptions.copyWith(
                baseUrl: testBaseUrl,
              );

              final response = await dio.fetch(retryOptions);
              EnvConfig.setResolvedHost(candidateHost);
              debugPrint('[HTTP RETRY SUCCESS] Successfully connected to fallback host: $candidateHost');
              return handler.resolve(response);
            } catch (_) {
              // Try next candidate
            }
          }
        }

        return handler.next(error);
      },
    ),
  );

  return dio;
});

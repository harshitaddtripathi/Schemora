import 'package:flutter/foundation.dart';

class EnvConfig {
  static const String appName = 'Schemora';
  static const String appVersion = '1.0.0';

  // ---------------------------------------------------------------------------
  // DEVELOPMENT API CONFIGURATION FOR PHYSICAL ANDROID PHONE / LOCAL PC
  // ---------------------------------------------------------------------------
  // ⚠️ PHYSICAL DEVICE: Use PC's LAN IP so the phone can reach the backend over WiFi.
  // For emulator use: 10.0.2.2  |  For web/desktop use: 127.0.0.1
  static const String devHostIp = '192.168.3.160'; // PC's LAN IP
  static const String devPort = '8000';

  // Production or runtime override injected via --dart-define=API_BASE_URL=...
  static const String _overrideBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  /// Dynamically computes the local development base URL.
  static String get _localBaseUrl {
    final host = kIsWeb ? '127.0.0.1' : (devHostIp.trim().isNotEmpty ? devHostIp.trim() : '127.0.0.1');
    return 'http://$host:$devPort/api/v1/';
  }

  /// The active API Base URL used by Dio.
  static String get baseUrl {
    final rawUrl =
        _overrideBaseUrl.isNotEmpty ? _overrideBaseUrl : _localBaseUrl;
    return rawUrl.endsWith('/') ? rawUrl : '$rawUrl/';
  }

  // Optimized timeouts to prevent app freezing and provide fast UI responses/fallbacks
  static const int connectTimeoutMs = 4000;
  static const int receiveTimeoutMs = 8000;
}


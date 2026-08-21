import 'package:flutter/foundation.dart';

class EnvConfig {
  static const String appName = 'Schemora';
  static const String appVersion = '1.0.0';

  // ---------------------------------------------------------------------------
  // DEVELOPMENT API CONFIGURATION FOR PHYSICAL ANDROID PHONE / LOCAL PC
  // ---------------------------------------------------------------------------
  static const String devHostIp = '127.0.0.1'; // Default fast localhost for Web/Desktop/Emulator
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

  // Fast performance timeouts with instant failover
  static const int connectTimeoutMs = 2000;
  static const int receiveTimeoutMs = 4000;
}


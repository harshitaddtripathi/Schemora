import 'package:flutter/foundation.dart';

class EnvConfig {
  static const String appName = 'Schemora';
  static const String appVersion = '1.0.0';

  // ---------------------------------------------------------------------------
  // DEVELOPMENT API CONFIGURATION FOR PHYSICAL ANDROID PHONE / LOCAL PC
  // ---------------------------------------------------------------------------
  // USB Mode (ADB Reverse): 127.0.0.1 (Fastest & immune to IP changes)
  // Wi-Fi Mode: 192.168.3.148 (Active PC Wi-Fi IP)
  // Emulator: 10.0.2.2
  static const String devHostIp = '192.168.3.148'; // Active PC Wi-Fi IP
  static const String devPort = '8000';

  static String? _resolvedHost;

  /// Remembers a verified working host IP across requests.
  static void setResolvedHost(String host) {
    _resolvedHost = host;
  }

  // Production or runtime override injected via --dart-define=API_BASE_URL=...
  static const String _overrideBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  /// Dynamically computes the local development base URL.
  static String get _localBaseUrl {
    final host = _resolvedHost ??
        (kIsWeb ? '127.0.0.1' : devHostIp);
    return 'http://$host:$devPort/api/v1/';
  }

  /// The active API Base URL used by Dio.
  static String get baseUrl {
    final rawUrl =
        _overrideBaseUrl.isNotEmpty ? _overrideBaseUrl : _localBaseUrl;
    return rawUrl.endsWith('/') ? rawUrl : '$rawUrl/';
  }

  // Timeout settings (15s connect, 60s receive)
  static const int connectTimeoutMs = 15000;
  static const int receiveTimeoutMs = 60000;
}


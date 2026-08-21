class EnvConfig {
  static const String appName = 'Schemora';
  static const String appVersion = '1.0.0';

  // ---------------------------------------------------------------------------
  // DEVELOPMENT API CONFIGURATION FOR PHYSICAL ANDROID PHONE / LOCAL PC
  // ---------------------------------------------------------------------------
  // 1. Enter your PC's LAN IPv4 address here (e.g. '192.168.3.150').
  // 2. OR run ADB port reverse: `adb reverse tcp:8000 tcp:8000` and use '127.0.0.1'.
  // 3. OR pass at run time via CLI:
  //    flutter run --dart-define=API_BASE_URL=http://192.168.x.x:8000/api/v1
  // ---------------------------------------------------------------------------
  static const String devHostIp =
      '192.168.3.129'; // Set to PC's LAN IP address (192.168.3.129) for physical Android devices
  static const String devPort = '8000';

  // Production or runtime override injected via --dart-define=API_BASE_URL=...
  static const String _overrideBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  /// Dynamically computes the local development base URL.
  static String get _localBaseUrl {
    final host = devHostIp.trim().isNotEmpty ? devHostIp.trim() : '127.0.0.1';
    return 'http://$host:$devPort/api/v1/';
  }

  /// The active API Base URL used by Dio.
  /// Priority:
  /// 1. `--dart-define=API_BASE_URL=...` CLI argument
  /// 2. Configured `devHostIp` / `_localBaseUrl`
  static String get baseUrl {
    final rawUrl =
        _overrideBaseUrl.isNotEmpty ? _overrideBaseUrl : _localBaseUrl;
    return rawUrl.endsWith('/') ? rawUrl : '$rawUrl/';
  }

  static const int connectTimeoutMs = 15000;
  static const int receiveTimeoutMs = 30000;
}

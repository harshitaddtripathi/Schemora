import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class EnvConfig {
  static const String appName = 'Schemora';
  static const String appVersion = '1.0.0';

  // Production URL injected at build time via:
  //   flutter run --dart-define=API_BASE_URL=https://your-api.onrender.com/api/v1
  // Leave empty to auto-select the correct local development URL.
  static const String _productionBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  // Local development URL with port 8000
  static String get _localBaseUrl {
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://192.168.3.150:8000/api/v1/';
    }
    return 'http://127.0.0.1:8000/api/v1/';
  }

  /// The base URL in use for this run.
  /// Priority: --dart-define override → auto-detected local URL.
  /// Always guarantees a trailing slash so Dio relative path resolution works properly.
  static String get baseUrl {
    final rawUrl =
        _productionBaseUrl.isNotEmpty ? _productionBaseUrl : _localBaseUrl;
    return rawUrl.endsWith('/') ? rawUrl : '$rawUrl/';
  }

  static const int connectTimeoutMs = 15000;
  static const int receiveTimeoutMs = 15000;
}

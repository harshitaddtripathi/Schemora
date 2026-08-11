import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class EnvConfig {
  static const String appName = 'Schemora';
  static const String appVersion = '1.0.0';

  // Production URL injected at build time via:
  //   flutter run --dart-define=API_BASE_URL=https://your-api.onrender.com/api/v1
  // Leave empty to auto-select the correct local development URL.
  static const String _productionBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');

  // Android emulator routes 10.0.2.2 → host machine's localhost.
  // All other platforms (web, desktop, iOS simulator) use 127.0.0.1.
  static String get _localBaseUrl {
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api/v1';
    }
    return 'http://127.0.0.1:8000/api/v1';
  }

  /// The base URL in use for this run.
  /// Priority: --dart-define override → auto-detected local URL.
  static String get baseUrl =>
      _productionBaseUrl.isNotEmpty ? _productionBaseUrl : _localBaseUrl;

  static const int connectTimeoutMs = 15000;
  static const int receiveTimeoutMs = 15000;
}

class EnvConfig {
  static const String appName = 'Schemora';
  static const String appVersion = '1.0.0';

  // Base API URL - default to localhost for desktop/web and 10.0.2.2 for Android emulator
  static const String defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api/v1',
  );

  static String baseUrl = defaultBaseUrl;

  static const int connectTimeoutMs = 10000;
  static const int receiveTimeoutMs = 10000;
}

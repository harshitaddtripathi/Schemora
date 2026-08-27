import 'package:flutter_test/flutter_test.dart';
import 'package:schemora_frontend/core/config/env_config.dart';

void main() {
  group('EnvConfig Unit Tests', () {
    test('default constants match expected baseline', () {
      expect(EnvConfig.appName, equals('Schemora'));
      expect(EnvConfig.appVersion, equals('1.0.0'));
      expect(EnvConfig.connectTimeoutMs, equals(8000));
      expect(EnvConfig.receiveTimeoutMs, equals(60000));
    });

    test('baseUrl contains /api/v1', () {
      // baseUrl is a runtime getter; in the test environment (non-Android)
      // it should resolve to the local 127.0.0.1 URL.
      expect(EnvConfig.baseUrl, contains('/api/v1'));
    });
  });
}

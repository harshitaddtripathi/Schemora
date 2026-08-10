import 'package:flutter_test/flutter_test.dart';
import 'package:schemora_frontend/core/config/env_config.dart';

void main() {
  group('EnvConfig Unit Tests', () {
    test('default constants match expected baseline', () {
      expect(EnvConfig.appName, equals('Schemora'));
      expect(EnvConfig.appVersion, equals('1.0.0'));
      expect(EnvConfig.connectTimeoutMs, equals(10000));
      expect(EnvConfig.receiveTimeoutMs, equals(10000));
    });

    test('defaultBaseUrl contains api/v1', () {
      expect(EnvConfig.defaultBaseUrl, contains('/api/v1'));
    });
  });
}

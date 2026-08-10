import 'package:flutter_test/flutter_test.dart';
import 'package:schemora_frontend/features/health/domain/health_status.dart';

void main() {
  group('HealthStatus Unit Tests', () {
    test('HealthStatus.fromJson parses valid JSON data correctly', () {
      final json = {
        'status': 'healthy',
        'version': '0.1.0',
        'environment': 'development',
        'database_connected': true,
        'latency_ms': 12.45,
      };

      final health = HealthStatus.fromJson(json);

      expect(health.status, equals('healthy'));
      expect(health.version, equals('0.1.0'));
      expect(health.environment, equals('development'));
      expect(health.databaseConnected, isTrue);
      expect(health.latencyMs, equals(12.45));
    });

    test('HealthStatus.fromJson handles missing optional fields with defaults', () {
      final json = <String, dynamic>{};

      final health = HealthStatus.fromJson(json);

      expect(health.status, equals('unknown'));
      expect(health.version, equals('0.0.0'));
      expect(health.environment, equals('unknown'));
      expect(health.databaseConnected, isFalse);
      expect(health.latencyMs, equals(0.0));
    });

    test('HealthStatus.fromJson casts int latency to double safely', () {
      final json = {
        'status': 'healthy',
        'version': '0.1.0',
        'environment': 'test',
        'database_connected': true,
        'latency_ms': 15,
      };

      final health = HealthStatus.fromJson(json);

      expect(health.latencyMs, equals(15.0));
    });
  });
}

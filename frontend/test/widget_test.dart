import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schemora_frontend/features/health/data/health_repository.dart';
import 'package:schemora_frontend/features/health/domain/health_status.dart';
import 'package:schemora_frontend/main.dart';

void main() {
  testWidgets('SchemoraApp smoke test with health override', (WidgetTester tester) async {
    final mockHealth = HealthStatus(
      status: 'healthy',
      version: '0.1.0',
      environment: 'test',
      databaseConnected: true,
      latencyMs: 5.0,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          healthStatusProvider.overrideWith((ref) async => mockHealth),
        ],
        child: const SchemoraApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Schemora API Diagnostic'), findsOneWidget);
    expect(find.text('Backend Fully Operational'), findsOneWidget);
    expect(find.text('0.1.0'), findsOneWidget);
  });
}

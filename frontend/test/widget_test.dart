import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schemora_frontend/main.dart';

void main() {
  testWidgets('SchemoraApp smoke test launches to LoginScreen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SchemoraApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Schemora — Citizen Login'), findsOneWidget);
    expect(find.text('Mobile Verification'), findsOneWidget);
    expect(find.text('Get Verification OTP'), findsOneWidget);
  });
}

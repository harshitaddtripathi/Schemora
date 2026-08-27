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

    expect(find.text('Schemora'), findsOneWidget);
    expect(find.text('Government Scheme Discovery Portal'), findsOneWidget);
    expect(find.text('Send OTP'), findsOneWidget);
  });
}

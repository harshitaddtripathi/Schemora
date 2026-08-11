import 'package:flutter_test/flutter_test.dart';
import 'package:schemora_frontend/features/auth/data/auth_repository.dart';
import 'package:schemora_frontend/features/auth/domain/auth_state.dart';

void main() {
  group('AuthNotifier Unit Tests', () {
    test('initial state is unauthenticated', () {
      final notifier = AuthNotifier();
      expect(notifier.state.status, equals(AuthStatus.unauthenticated));
      expect(notifier.state.token, isNull);
    });

    test('sendOtp updates state to otpSent', () async {
      final notifier = AuthNotifier();
      await notifier.sendOtp('9876543210');
      expect(notifier.state.status, equals(AuthStatus.otpSent));
      expect(notifier.state.phoneNumber, equals('9876543210'));
    });

    // TEST CASE 1 — OTP 123456
    test('verifyOtp with 123456 authenticates user and sets token', () async {
      final notifier = AuthNotifier();
      await notifier.sendOtp('9876543210');
      await notifier.verifyOtp('123456');

      expect(notifier.state.status, equals(AuthStatus.authenticated));
      expect(notifier.state.token, isNotNull);
      expect(notifier.state.errorMessage, isNull);
    });

    // TEST CASE 2 — OTP 000000
    test('verifyOtp with 000000 also authenticates user and sets token', () async {
      final notifier = AuthNotifier();
      await notifier.sendOtp('9876543210');
      await notifier.verifyOtp('000000');

      expect(notifier.state.status, equals(AuthStatus.authenticated));
      expect(notifier.state.token, isNotNull);
      expect(notifier.state.errorMessage, isNull);
    });

    // TEST CASE 3 — Invalid OTP
    test('verifyOtp with invalid code produces error state and keeps user on screen', () async {
      final notifier = AuthNotifier();
      await notifier.sendOtp('9876543210');
      await notifier.verifyOtp('111111');

      expect(notifier.state.status, equals(AuthStatus.error));
      expect(notifier.state.token, isNull);
      expect(notifier.state.errorMessage, contains('Invalid OTP'));
    });

    test('verifyOtp transitions through authenticating state before resolving', () async {
      final notifier = AuthNotifier();
      await notifier.sendOtp('9876543210');

      // Start verify but don't await — capture intermediate state
      final future = notifier.verifyOtp('123456');
      // The first synchronous state update inside verifyOtp sets authenticating
      expect(notifier.state.status, equals(AuthStatus.authenticating));

      await future;
      expect(notifier.state.status, equals(AuthStatus.authenticated));
    });

    test('authenticated state carries the correct token value', () async {
      final notifier = AuthNotifier();
      await notifier.sendOtp('9876543210');
      await notifier.verifyOtp('123456');

      expect(notifier.state.token, equals('test-token-citizen'));
    });

    test('logout resets state to initial unauthenticated', () async {
      final notifier = AuthNotifier();
      await notifier.sendOtp('9876543210');
      await notifier.verifyOtp('123456');
      expect(notifier.state.status, equals(AuthStatus.authenticated));

      notifier.logout();
      expect(notifier.state.status, equals(AuthStatus.unauthenticated));
      expect(notifier.state.token, isNull);
    });
  });
}

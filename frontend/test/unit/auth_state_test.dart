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

    test('verifyOtp with valid code authenticates user', () async {
      final notifier = AuthNotifier();
      await notifier.sendOtp('9876543210');
      await notifier.verifyOtp('123456');

      expect(notifier.state.status, equals(AuthStatus.authenticated));
      expect(notifier.state.token, isNotNull);
    });

    test('verifyOtp with invalid code produces error state', () async {
      final notifier = AuthNotifier();
      await notifier.sendOtp('9876543210');
      await notifier.verifyOtp('000111');

      expect(notifier.state.status, equals(AuthStatus.error));
      expect(notifier.state.errorMessage, contains('Invalid OTP'));
    });
  });
}

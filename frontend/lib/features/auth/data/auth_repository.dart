import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schemora_frontend/features/auth/domain/auth_state.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  Future<void> sendOtp(String phoneNumber) async {
    state = state.copyWith(
      status: AuthStatus.authenticating,
      phoneNumber: phoneNumber,
      errorMessage: null,
    );

    await Future.delayed(const Duration(milliseconds: 500));

    state = state.copyWith(
      status: AuthStatus.otpSent,
      verificationId: 'v-id-12345',
    );
  }

  Future<void> verifyOtp(String otp) async {
    state = state.copyWith(
      status: AuthStatus.authenticating,
      errorMessage: null,
    );

    await Future.delayed(const Duration(milliseconds: 500));

    if (otp == '123456' || otp == '000000') {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        token: 'test-token-citizen',
      );
    } else {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Invalid OTP code. Please enter 123456.',
      );
    }
  }

  void logout() {
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

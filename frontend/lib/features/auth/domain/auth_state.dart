enum AuthStatus {
  unauthenticated,
  otpSent,
  authenticating,
  authenticated,
  error,
}

class AuthState {
  final AuthStatus status;
  final String? phoneNumber;
  final String? verificationId;
  final String? token;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.unauthenticated,
    this.phoneNumber,
    this.verificationId,
    this.token,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? phoneNumber,
    String? verificationId,
    String? token,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      verificationId: verificationId ?? this.verificationId,
      token: token ?? this.token,
      errorMessage: errorMessage,
    );
  }
}

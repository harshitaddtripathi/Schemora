import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:schemora_frontend/core/theme/app_theme.dart';
import 'package:schemora_frontend/core/widgets/dashboard_button.dart';
import 'package:schemora_frontend/features/auth/data/auth_repository.dart';
import 'package:schemora_frontend/features/auth/domain/auth_state.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController(text: '9876543210');
  final _otpController = TextEditingController(text: '123456');

  bool _isNavigating = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  /// Deterministic direct OTP verification & navigation flow.
  /// Triggered directly by the "Verify OTP & Continue" button.
  Future<void> _handleVerifyOtp() async {
    if (_isNavigating) return;

    final otp = _otpController.text.trim();

    debugPrint('[AUTH] Verify OTP started');
    await ref.read(authProvider.notifier).verifyOtp(otp);
    debugPrint('[AUTH] OTP verification completed');

    if (!mounted) return;

    final authState = ref.read(authProvider);
    debugPrint('[AUTH] Auth status: ${authState.status}');
    debugPrint('[AUTH] Token: ${authState.token}');

    if (authState.status != AuthStatus.authenticated) {
      // Unauthenticated / invalid OTP error: remain on screen, UI displays authState.errorMessage
      return;
    }

    final token = authState.token;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authentication succeeded but no token was received.'),
        ),
      );
      return;
    }

    debugPrint('[NAV] OTP verified successfully. Navigating to /dashboard first');
    _isNavigating = true;
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schemora — Citizen Login'),
        actions: const [
          DashboardButton(),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Icon(
                Icons.mark_email_read_outlined,
                size: 64,
                color: AppTheme.primaryBlue,
              ),
              const SizedBox(height: 16),
              Text(
                'Mobile Verification',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 26),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your 10-digit mobile number to access government schemes matched to your profile.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (authState.status != AuthStatus.otpSent) ...[
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Mobile Number',
                    hintText: '9876543210',
                    prefixIcon: Icon(Icons.phone_android_rounded),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: authState.status == AuthStatus.authenticating
                      ? null
                      : () => ref.read(authProvider.notifier).sendOtp(_phoneController.text),
                  child: authState.status == AuthStatus.authenticating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Get Verification OTP'),
                ),
              ] else ...[
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'Enter 6-Digit OTP',
                    hintText: '123456',
                    prefixIcon: Icon(Icons.lock_clock_rounded),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: (authState.status == AuthStatus.authenticating || _isNavigating)
                      ? null
                      : _handleVerifyOtp,
                  child: authState.status == AuthStatus.authenticating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Verify OTP & Continue'),
                ),
              ],
              if (authState.errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  authState.errorMessage!,
                  style: const TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 32),
              Card(
                color: AppTheme.primaryBlue.withAlpha(13),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Demo Credentials',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Phone: 9876543210 | OTP: 123456',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

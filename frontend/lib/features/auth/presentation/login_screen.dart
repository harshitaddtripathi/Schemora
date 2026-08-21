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

  Future<void> _handleVerifyOtp() async {
    if (_isNavigating) return;

    final otp = _otpController.text.trim();

    debugPrint('[AUTH] Verify OTP started');
    await ref.read(authProvider.notifier).verifyOtp(otp);
    debugPrint('[AUTH] OTP verification completed');

    if (!mounted) return;

    final authState = ref.read(authProvider);

    if (authState.status != AuthStatus.authenticated) {
      return;
    }

    _isNavigating = true;
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Schemora Portal',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3),
        ),
        centerTitle: true,
        actions: const [
          DashboardButton(),
        ],
      ),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              alignment: Alignment.center,
              child: Column(

                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hero Graphic Banner Card
                  Container(
                    height: 210,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF2563EB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryNavy.withAlpha(60),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            'assets/images/schemora_hero.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Icon(Icons.account_balance_rounded, size: 80, color: Colors.white.withAlpha(150)),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withAlpha(180),
                                  Colors.transparent,
                                  Colors.black.withAlpha(200),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(45),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'AI-Powered Scheme Discovery Engine',
                                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Find Government Schemes Matched To You',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Modern Login Form Card
                  Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(12),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue.withAlpha(20),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.phone_iphone_rounded, color: AppTheme.primaryBlue, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Citizen Login',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                Text(
                                  'Instant OTP Verification',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 22),

                        if (authState.status != AuthStatus.otpSent) ...[
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Mobile Number',
                              hintText: '9876543210',
                              prefixIcon: Icon(Icons.phone_android_rounded, color: AppTheme.primaryBlue),
                            ),
                          ),
                          const SizedBox(height: 18),
                          ElevatedButton.icon(
                            onPressed: authState.status == AuthStatus.authenticating
                                ? null
                                : () => ref.read(authProvider.notifier).sendOtp(_phoneController.text),
                            icon: authState.status == AuthStatus.authenticating
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Icon(Icons.send_rounded, size: 18),
                            label: const Text('Get Verification OTP'),
                          ),
                        ] else ...[
                          TextField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            decoration: const InputDecoration(
                              labelText: 'Enter 6-Digit OTP',
                              hintText: '123456',
                              prefixIcon: Icon(Icons.lock_clock_rounded, color: AppTheme.primaryBlue),
                            ),
                          ),
                          const SizedBox(height: 18),
                          ElevatedButton.icon(
                            onPressed: (authState.status == AuthStatus.authenticating || _isNavigating)
                                ? null
                                : _handleVerifyOtp,
                            icon: authState.status == AuthStatus.authenticating
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Icon(Icons.check_circle_rounded, size: 18),
                            label: const Text('Verify OTP & Continue'),
                          ),
                        ],

                        if (authState.errorMessage != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.errorRed.withAlpha(20),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              authState.errorMessage!,
                              style: const TextStyle(color: AppTheme.errorRed, fontSize: 13, fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Quick Demo Credentials Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withAlpha(12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primaryBlue.withAlpha(30)),
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        const Icon(Icons.verified_rounded, size: 18, color: AppTheme.primaryBlue),
                        const Text(
                          'Demo Account:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryNavy),
                        ),
                        Text(
                          '9876543210 (OTP: 123456)',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.blue.shade800),
                        ),
                      ],
                    ),

                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


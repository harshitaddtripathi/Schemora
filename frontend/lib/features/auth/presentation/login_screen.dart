import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:schemora_frontend/core/theme/app_theme.dart';
import 'package:schemora_frontend/features/auth/data/auth_repository.dart';
import 'package:schemora_frontend/features/auth/domain/auth_state.dart';

// ─── Local enum to track which login method is selected ──────────────────────
enum _LoginMethod { phone, email }

// ─── Local enum to track Sign In vs Sign Up mode ─────────────────────────────
enum _AuthMode { signIn, signUp }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  // Controllers
  final _phoneController = TextEditingController(text: '9876543210');
  final _otpController = TextEditingController(text: '123456');
  final _emailController = TextEditingController(text: 'user@demo.com');
  final _passwordController = TextEditingController(text: 'demo123');
  final _nameController = TextEditingController();
  final _confirmPasswordController = TextEditingController(text: 'demo123');

  _LoginMethod _method = _LoginMethod.phone;
  _AuthMode _mode = _AuthMode.signIn;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isNavigating = false;
  String? _localError;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _switchMode(_AuthMode mode) {
    ref.read(authProvider.notifier).reset();
    setState(() {
      _mode = mode;
      _localError = null;
    });
    _fadeCtrl.forward(from: 0);
  }

  void _switchMethod(_LoginMethod method) {
    ref.read(authProvider.notifier).reset();
    setState(() {
      _method = method;
      _localError = null;
    });
    _fadeCtrl.forward(from: 0);
  }

  // ── Phone OTP flow ──────────────────────────────────────────────────────────
  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      setState(() => _localError = 'Please enter a valid 10-digit mobile number.');
      return;
    }
    setState(() => _localError = null);
    await ref.read(authProvider.notifier).sendOtp(phone);
  }

  Future<void> _verifyOtp() async {
    if (_isNavigating) return;
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      setState(() => _localError = 'Please enter the OTP sent to your number.');
      return;
    }
    setState(() => _localError = null);
    await ref.read(authProvider.notifier).verifyOtp(otp);
    if (!mounted) return;
    if (ref.read(authProvider).status == AuthStatus.authenticated) {
      _isNavigating = true;
      context.go('/dashboard');
    }
  }

  // ── Email flow ──────────────────────────────────────────────────────────────
  Future<void> _handleEmailAuth() async {
    if (_isNavigating) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _localError = 'Please enter a valid email address.');
      return;
    }
    if (password.length < 6) {
      setState(() => _localError = 'Password must be at least 6 characters.');
      return;
    }
    if (_mode == _AuthMode.signUp) {
      final name = _nameController.text.trim();
      if (name.isEmpty) {
        setState(() => _localError = 'Please enter your full name.');
        return;
      }
      if (_confirmPasswordController.text != password) {
        setState(() => _localError = 'Passwords do not match.');
        return;
      }
    }
    setState(() => _localError = null);
    // Simulate email auth — treat demo credentials as success
    await ref.read(authProvider.notifier).signInWithEmail(email, password);
    if (!mounted) return;
    if (ref.read(authProvider).status == AuthStatus.authenticated) {
      _isNavigating = true;
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.authenticating;
    final error = _localError ?? authState.errorMessage;
    final otpSent = authState.status == AuthStatus.otpSent;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 32.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Brand ──────────────────────────────────────────────
                    _BrandHeader(),

                    const SizedBox(height: 32),

                    // ── Sign In / Sign Up Toggle ───────────────────────────
                    _ModeToggle(
                      mode: _mode,
                      onChanged: _switchMode,
                    ),

                    const SizedBox(height: 20),

                    // ── Form Card ──────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(10),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── Method Tabs ──────────────────────────────────
                          if (!otpSent) _MethodTabs(
                            method: _method,
                            onChanged: _switchMethod,
                          ),

                          if (!otpSent) const SizedBox(height: 22),

                          // ── Phone Flow ───────────────────────────────────
                          if (_method == _LoginMethod.phone) ...[
                            if (!otpSent) ...[
                              // Sign Up extra field
                              if (_mode == _AuthMode.signUp) ...[
                                _InputField(
                                  controller: _nameController,
                                  label: 'Full Name',
                                  hint: 'Ramesh Kumar',
                                  icon: Icons.person_outline_rounded,
                                  keyboardType: TextInputType.name,
                                ),
                                const SizedBox(height: 14),
                              ],
                              _InputField(
                                controller: _phoneController,
                                label: 'Mobile Number',
                                hint: '9876543210',
                                icon: Icons.phone_android_rounded,
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 16),
                              _PrimaryButton(
                                label: _mode == _AuthMode.signIn
                                    ? 'Send OTP'
                                    : 'Create Account & Send OTP',
                                icon: Icons.send_rounded,
                                isLoading: isLoading,
                                onPressed: _sendOtp,
                              ),
                            ] else ...[
                              // OTP step
                              _OtpStep(
                                phone: authState.phoneNumber ?? '',
                                otpController: _otpController,
                                isLoading: isLoading,
                                onVerify: _verifyOtp,
                                onBack: () => ref.read(authProvider.notifier).reset(),
                              ),
                            ],
                          ],

                          // ── Email Flow ────────────────────────────────────
                          if (_method == _LoginMethod.email) ...[
                            if (_mode == _AuthMode.signUp) ...[
                              _InputField(
                                controller: _nameController,
                                label: 'Full Name',
                                hint: 'Ramesh Kumar',
                                icon: Icons.person_outline_rounded,
                                keyboardType: TextInputType.name,
                              ),
                              const SizedBox(height: 14),
                            ],
                            _InputField(
                              controller: _emailController,
                              label: 'Email Address',
                              hint: 'you@example.com',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 14),
                            _InputField(
                              controller: _passwordController,
                              label: 'Password',
                              hint: '••••••••',
                              icon: Icons.lock_outline_rounded,
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 18,
                                  color: Colors.grey.shade500,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            if (_mode == _AuthMode.signUp) ...[
                              const SizedBox(height: 14),
                              _InputField(
                                controller: _confirmPasswordController,
                                label: 'Confirm Password',
                                hint: '••••••••',
                                icon: Icons.lock_outline_rounded,
                                obscureText: _obscureConfirm,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirm
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 18,
                                    color: Colors.grey.shade500,
                                  ),
                                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                ),
                              ),
                            ],
                            if (_mode == _AuthMode.signIn) ...[
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {},
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    'Forgot password?',
                                    style: TextStyle(fontSize: 12, color: AppTheme.primaryBlue),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            _PrimaryButton(
                              label: _mode == _AuthMode.signIn ? 'Sign In' : 'Create Account',
                              icon: _mode == _AuthMode.signIn
                                  ? Icons.login_rounded
                                  : Icons.person_add_outlined,
                              isLoading: isLoading,
                              onPressed: _handleEmailAuth,
                            ),
                          ],

                          // ── Error Banner ──────────────────────────────────
                          if (error != null) ...[
                            const SizedBox(height: 14),
                            _ErrorBanner(message: error),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Account toggle footer ──────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _mode == _AuthMode.signIn
                              ? "Don't have an account? "
                              : 'Already have an account? ',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        ),
                        GestureDetector(
                          onTap: () => _switchMode(
                            _mode == _AuthMode.signIn ? _AuthMode.signUp : _AuthMode.signIn,
                          ),
                          child: Text(
                            _mode == _AuthMode.signIn ? 'Sign Up' : 'Sign In',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── Demo hint ──────────────────────────────────────────
                    _DemoHint(method: _method),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Sub-widgets
// ═══════════════════════════════════════════════════════════════════════════════

class _BrandHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withAlpha(60),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(Icons.account_balance_rounded, color: Colors.white, size: 30),
        ),
        const SizedBox(height: 16),
        const Text(
          'Schemora',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Government Scheme Discovery Portal',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ModeToggle extends StatelessWidget {
  final _AuthMode mode;
  final ValueChanged<_AuthMode> onChanged;
  const _ModeToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE8EDF5),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _ToggleTab(
            label: 'Sign In',
            active: mode == _AuthMode.signIn,
            onTap: () => onChanged(_AuthMode.signIn),
          ),
          _ToggleTab(
            label: 'Sign Up',
            active: mode == _AuthMode.signUp,
            onTap: () => onChanged(_AuthMode.signUp),
          ),
        ],
      ),
    );
  }
}

class _ToggleTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ToggleTab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: active
                ? [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 6, offset: const Offset(0, 2))]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? const Color(0xFF0F172A) : Colors.grey.shade500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _MethodTabs extends StatelessWidget {
  final _LoginMethod method;
  final ValueChanged<_LoginMethod> onChanged;
  const _MethodTabs({required this.method, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MethodChip(
          label: 'Phone & OTP',
          icon: Icons.phone_android_rounded,
          active: method == _LoginMethod.phone,
          onTap: () => onChanged(_LoginMethod.phone),
        ),
        const SizedBox(width: 10),
        _MethodChip(
          label: 'Email',
          icon: Icons.email_outlined,
          active: method == _LoginMethod.email,
          onTap: () => onChanged(_LoginMethod.email),
        ),
      ],
    );
  }
}

class _MethodChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _MethodChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppTheme.primaryBlue : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? AppTheme.primaryBlue : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: active ? Colors.white : Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;

  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: AppTheme.primaryBlue),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                  Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ],
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _OtpStep extends StatelessWidget {
  final String phone;
  final TextEditingController otpController;
  final bool isLoading;
  final VoidCallback onVerify;
  final VoidCallback onBack;

  const _OtpStep({
    required this.phone,
    required this.otpController,
    required this.isLoading,
    required this.onVerify,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, size: 20),
              onPressed: onBack,
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFF1F5F9),
                padding: const EdgeInsets.all(8),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter OTP',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                  ),
                  Text(
                    'Sent to +91 $phone',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _InputField(
          controller: otpController,
          label: '6-Digit OTP',
          hint: '123456',
          icon: Icons.lock_outline_rounded,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        _PrimaryButton(
          label: 'Verify & Continue',
          icon: Icons.check_circle_outline_rounded,
          isLoading: isLoading,
          onPressed: onVerify,
        ),
        const SizedBox(height: 10),
        Center(
          child: TextButton(
            onPressed: onBack,
            child: Text(
              'Resend OTP',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 16, color: Color(0xFFDC2626)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _DemoHint extends StatelessWidget {
  final _LoginMethod method;
  const _DemoHint({required this.method});

  @override
  Widget build(BuildContext context) {
    final hint = method == _LoginMethod.phone
        ? 'Demo: 9876543210  ·  OTP: 123456'
        : 'Demo: user@demo.com  ·  Pass: demo123';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline_rounded, size: 15, color: Color(0xFF0284C7)),
          const SizedBox(width: 8),
          Text(
            hint,
            style: const TextStyle(fontSize: 12, color: Color(0xFF0369A1), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

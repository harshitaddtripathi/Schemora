import 'package:flutter/material.dart';
import 'package:schemora_frontend/core/theme/app_theme.dart';
import 'package:schemora_frontend/core/widgets/dashboard_button.dart';

/// Admin login screen (P0-702).
/// In production this would validate admin email+password+OTP.
/// For the hackathon, we accept a test admin token shown via the drawer.
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _tokenCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  void _login() {
    final token = _tokenCtrl.text.trim();
    if (token.isEmpty) {
      setState(() => _error = 'Please enter admin token');
      return;
    }
    if (!token.contains('admin')) {
      setState(() => _error = 'Invalid admin token. Ensure token contains "admin".');
      return;
    }
    setState(() {
      _error = null;
      _loading = true;
    });
    // Simulate auth delay
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        setState(() => _loading = false);
        Navigator.pushReplacementNamed(context, '/admin/dashboard');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrator Access'),
        backgroundColor: AppTheme.primaryNavy,
        foregroundColor: Colors.white,
        actions: const [
          DashboardButton(color: Colors.white, tooltip: 'Back to Citizen Dashboard'),
        ],
      ),
      backgroundColor: AppTheme.primaryNavy,
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.admin_panel_settings_rounded, size: 48, color: AppTheme.primaryBlue),
                const SizedBox(height: 12),
                const Text('Admin Access', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Schemora Administrator Dashboard', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 24),
                TextField(
                  controller: _tokenCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Admin Bearer Token',
                    hintText: 'test-token-admin-evaluator',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.key_rounded),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      : const Text('Login as Administrator', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

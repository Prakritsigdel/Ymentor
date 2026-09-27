import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../checkout_screen.dart';
import 'register_screen.dart';
import '../../widgets/common/app_logo_avatar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _showSocialSignInNotice(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              '$provider sign-in is not configured yet. Use your email and password.')),
    );
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = context.read<AuthProvider>();
      await auth.login(_emailCtrl.text.trim(), _passwordCtrl.text);

      if (!mounted) return;

      // Auth guard: if a booking was pending before login, go straight to checkout.
      final pending = auth.pendingBooking;
      if (pending != null && auth.isMentee) {
        await auth.clearPendingBooking();
        if (!mounted) return;
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => CheckoutScreen(
            mentorId: pending.mentorId,
            durationMinutes: pending.durationMinutes,
            price: pending.price,
          ),
        ));
      } else {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('ApiException: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log In')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerLeft,
                child: AppLogoAvatar(
                  size: 76,
                  assetPath: 'assets/images/logo.png',
                  circular: false,
                ),
              ),
              const SizedBox(height: 10),
              const Text('Welcome back',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Sign in to continue learning with trusted mentors.',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => _showSocialSignInNotice('Google'),
                icon: const Icon(Icons.g_mobiledata, size: 24),
                label: const Text('Continue with Google'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => _showSocialSignInNotice('Apple'),
                icon: const Icon(Icons.phone_iphone, size: 20),
                label: const Text('Continue with Apple'),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.border)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('OR CONTINUE WITH EMAIL',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 10)),
                    ),
                    Expanded(child: Divider(color: AppColors.border)),
                  ],
                ),
              ),
              TextField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined,
                      color: AppColors.textSecondary),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _passwordCtrl,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon:
                      Icon(Icons.lock_outline, color: AppColors.textSecondary),
                ),
                obscureText: true,
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.redAccent, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                              color: Colors.redAccent, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Sign In'),
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                ),
                child: const Text("Don't have an account? Sign Up"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth/social_auth_button.dart';
import '../../widgets/common/app_logo_widget.dart';
import '../checkout_screen.dart';
import '../root_shell.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _showSocialFallback(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$provider Sign-In will be available in the upcoming production release. '
          'Please use Email/Password for this demo.',
        ),
      ),
    );
  }

  Future<void> _handleSocialSignIn(String provider) async {
    final configured = provider == 'Google'
        ? AuthService.hasGoogleConfiguration
        : AuthService.hasAppleConfiguration;
    if (!configured) {
      _showSocialFallback(provider);
      return;
    }

    try {
      if (provider == 'Google') {
        await AuthService.signInWithGoogle();
      } else {
        await AuthService.signInWithApple();
      }
    } catch (_) {
      if (mounted) _showSocialFallback(provider);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = context.read<AuthProvider>();
      final success =
          await auth.login(_emailCtrl.text.trim(), _passwordCtrl.text);
      if (!success || !mounted) return;
      await _continueAfterLogin(auth);
    } catch (error) {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      if (auth.isLoggedIn) {
        await _continueAfterLogin(auth);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Signed in, but this session could not be saved securely. '
              'You may need to sign in again after restarting the app.',
            ),
          ),
        );
      } else {
        setState(
          () => _error = error.toString().replaceFirst('ApiException: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _continueAfterLogin(AuthProvider auth) async {
    final pending = auth.pendingBooking;
    if (pending != null && auth.isMentee) {
      await auth.clearPendingBooking();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => CheckoutScreen(
            mentorId: pending.mentorId,
            durationMinutes: pending.durationMinutes,
            price: pending.price,
            planType: pending.monthlyPlan ? 'monthly' : 'hourly',
            monthlyPrice: pending.monthlyPlan ? pending.price : 0,
            scheduledTime: pending.scheduledTime,
          ),
        ),
      );
    } else {
      Navigator.of(context, rootNavigator: true)
          .popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Log In'),
          actions: [
            TextButton(
              onPressed: () {
                final navigator = Navigator.of(context);
                if (navigator.canPop()) {
                  navigator.pop();
                } else {
                  navigator.pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => const RootShell(),
                    ),
                  );
                }
              },
              child: const Text(
                'Browse First',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: AppLogoWidget(height: 76),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Welcome back',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Sign in to continue learning with trusted mentors.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email_outlined,
                          color: AppColors.textSecondary),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter your email address.';
                      }
                      if (!value.contains('@')) return 'Enter a valid email.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline,
                          color: AppColors.textSecondary),
                      suffixIcon: IconButton(
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                        icon: Icon(_obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off),
                        tooltip: _obscurePassword
                            ? 'Show password'
                            : 'Hide password',
                      ),
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Enter your password.'
                        : null,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.danger.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.danger, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(_error!,
                                  style: const TextStyle(
                                      color: AppColors.danger, fontSize: 13))),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Sign In'),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 22),
                    child: Row(
                      children: [
                        Expanded(child: Divider(color: AppColors.border)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('OR CONTINUE WITH',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 10)),
                        ),
                        Expanded(child: Divider(color: AppColors.border)),
                      ],
                    ),
                  ),
                  SocialAuthButton(
                    label: 'Continue with Google',
                    icon: Icons.g_mobiledata,
                    onPressed: () => _handleSocialSignIn('Google'),
                  ),
                  const SizedBox(height: 12),
                  SocialAuthButton(
                    label: 'Continue with Apple',
                    icon: Icons.phone_iphone,
                    onPressed: () => _handleSocialSignIn('Apple'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    ),
                    child: const Text(
                      "Don't have an account? Sign Up",
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

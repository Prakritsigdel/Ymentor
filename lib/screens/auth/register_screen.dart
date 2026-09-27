import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_logo_avatar.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _role = 'mentee'; // 'mentee', 'mentor', 'admin'
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty ||
        _passwordCtrl.text.isEmpty) {
      setState(() => _error = 'Please fill in all required fields.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await context.read<AuthProvider>().register(
            name: _nameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
            role: _role,
          );

      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('ApiException: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: AppLogoAvatar(
                  size: 64,
                  assetPath: 'assets/images/logo.png',
                  circular: false,
                ),
              ),
              const SizedBox(height: 16),
              const Text('Join Ymentor',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text(
                'Join as a Student (Mentee), Mentor, or Administrator.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),

              // 3-Role Selector Toggle
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _roleChoice('mentee', 'Student', Icons.school),
                    _roleChoice('mentor', 'Mentor', Icons.psychology),
                    _roleChoice('admin', 'Admin', Icons.security),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              if (_role == 'mentor')
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.mint.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.info_outline, size: 18, color: AppColors.mint),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Mentor profiles undergo admin review for identity and skill verification.',
                          style: TextStyle(fontSize: 12, color: AppColors.mint),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 18),

              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline,
                      color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 14),

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
                  child: Text(_error!,
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 13)),
                ),
              ],

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(
                        'Register as ${_role[0].toUpperCase()}${_role.substring(1)}'),
              ),

              const SizedBox(height: 14),

              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Already have an account? Log In'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleChoice(String roleValue, String label, IconData icon) {
    final selected = _role == roleValue;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _role = roleValue),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.mint : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: selected
                      ? AppColors.background
                      : AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color:
                      selected ? AppColors.background : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

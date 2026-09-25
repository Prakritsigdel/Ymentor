import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../checkout_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController(text: 'student.jordan@ymentor.com');
  final _passwordCtrl = TextEditingController(text: 'student123');
  String _selectedRole = 'mentee'; // 'mentee', 'mentor', 'admin'
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _onRoleSelected(String role) {
    setState(() {
      _selectedRole = role;
      if (role == 'admin') {
        _emailCtrl.text = 'admin@ymentor.com';
        _passwordCtrl.text = 'admin123';
      } else if (role == 'mentor') {
        _emailCtrl.text = 'mentor.sarah@ymentor.com';
        _passwordCtrl.text = 'mentor123';
      } else {
        _emailCtrl.text = 'student.jordan@ymentor.com';
        _passwordCtrl.text = 'student123';
      }
    });
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
              const Text('Welcome to Ymentor', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Select your role to sign in or explore demo credentials.',
                  style: TextStyle(color: AppColors.textSecondary)),
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
                    _roleTab('mentee', 'Student', Icons.school),
                    _roleTab('mentor', 'Mentor', Icons.psychology),
                    _roleTab('admin', 'Admin', Icons.security),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'you@example.com',
                  prefixIcon: Icon(Icons.email_outlined, color: AppColors.textSecondary),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),

              TextField(
                controller: _passwordCtrl,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline, color: AppColors.textSecondary),
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
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 13),
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
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text('Sign In as ${_selectedRole[0].toUpperCase()}${_selectedRole.substring(1)}'),
              ),

              const SizedBox(height: 14),

              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                ),
                child: const Text("Don't have an account? Sign Up"),
              ),

              const SizedBox(height: 16),
              const Divider(color: AppColors.border),
              const SizedBox(height: 8),

              // Demo credentials helper card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Baseline Demo Accounts:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.mint)),
                    const SizedBox(height: 6),
                    _demoRow('Admin', 'admin@ymentor.com', 'admin123'),
                    _demoRow('Mentor', 'mentor.sarah@ymentor.com', 'mentor123'),
                    _demoRow('Mentee', 'student.jordan@ymentor.com', 'student123'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleTab(String role, String label, IconData icon) {
    final selected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onRoleSelected(role),
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
              Icon(icon, size: 16, color: selected ? AppColors.background : AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? AppColors.background : AppColors.textSecondary,
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

  Widget _demoRow(String role, String email, String pwd) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        '$role: $email / $pwd',
        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontFamily: 'monospace'),
      ),
    );
  }
}

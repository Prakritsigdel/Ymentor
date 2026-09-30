import 'package:flutter/material.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  final _visible = <int>{};

  @override
  void dispose() {
    _current.dispose(); _next.dispose(); _confirm.dispose(); super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Change Password')),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _password(0, _current, 'Current password'),
              const SizedBox(height: 16),
              _password(1, _next, 'New password'),
              const SizedBox(height: 16),
              _password(2, _confirm, 'Confirm new password'),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  if (!(_formKey.currentState?.validate() ?? false)) return;
                  if (_next.text != _confirm.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('New passwords do not match.')),
                    );
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password update is ready for account verification.')),
                  );
                },
                child: const Text('Update Password'),
              ),
            ],
          ),
        ),
      );

  Widget _password(int index, TextEditingController controller, String label) =>
      TextFormField(
        controller: controller,
        obscureText: !_visible.contains(index),
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: IconButton(
            icon: Icon(_visible.contains(index) ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() {
              _visible.contains(index) ? _visible.remove(index) : _visible.add(index);
            }),
          ),
        ),
        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
      );
}

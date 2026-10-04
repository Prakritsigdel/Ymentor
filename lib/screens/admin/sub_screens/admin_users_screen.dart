import 'package:flutter/material.dart';
import '../../../widgets/admin_modules.dart';

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('User Management'),
        ),
        body: const AdminUsersModule(),
      );
}

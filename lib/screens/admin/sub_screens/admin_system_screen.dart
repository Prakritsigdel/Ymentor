import 'package:flutter/material.dart';
import '../../../widgets/admin_modules.dart';

class AdminSystemScreen extends StatelessWidget {
  const AdminSystemScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('System Settings'),
        ),
        body: const AdminSystemModule(),
      );
}

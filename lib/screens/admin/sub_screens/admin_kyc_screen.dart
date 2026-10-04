import 'package:flutter/material.dart';
import '../../../widgets/admin_modules.dart';

class AdminKycScreen extends StatelessWidget {
  const AdminKycScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('KYC Verifications'),
        ),
        body: const AdminKycModule(),
      );
}

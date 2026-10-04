import 'package:flutter/material.dart';
import '../../../widgets/admin_modules.dart';

class AdminPayoutsScreen extends StatelessWidget {
  const AdminPayoutsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Payout Management'),
        ),
        body: const AdminLedgerModule(),
      );
}

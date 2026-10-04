import 'package:flutter/material.dart';
import '../../../widgets/admin_modules.dart';

class AdminLedgerScreen extends StatelessWidget {
  const AdminLedgerScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Financial Ledger'),
        ),
        body: const AdminLedgerModule(),
      );
}

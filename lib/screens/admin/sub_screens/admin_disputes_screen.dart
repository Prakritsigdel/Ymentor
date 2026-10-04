import 'package:flutter/material.dart';
import '../../../widgets/admin_modules.dart';

class AdminDisputesScreen extends StatelessWidget {
  const AdminDisputesScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Dispute Resolution'),
        ),
        body: const AdminDisputesModule(),
      );
}

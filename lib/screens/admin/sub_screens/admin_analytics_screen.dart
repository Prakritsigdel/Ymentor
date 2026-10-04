import 'package:flutter/material.dart';
import '../../../widgets/admin_modules.dart';

class AdminAnalyticsScreen extends StatelessWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Platform Analytics'),
        ),
        body: const AdminAnalyticsModule(),
      );
}

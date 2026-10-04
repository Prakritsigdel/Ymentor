import 'package:flutter/material.dart';
import '../../../widgets/admin_modules.dart';

class AdminReviewsScreen extends StatelessWidget {
  const AdminReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Review Moderation'),
        ),
        body: const AdminReviewsModule(),
      );
}

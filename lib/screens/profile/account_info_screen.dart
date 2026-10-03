import 'package:flutter/material.dart';

class AccountInfoScreen extends StatelessWidget {
  final String title;
  final String description;

  const AccountInfoScreen({
    super.key,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Icon(Icons.verified_user_outlined,
              size: 48, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 20),
          Text(description, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.support_agent_outlined),
              title: const Text('Need help?'),
              subtitle: const Text('Contact support@ymentor.com'),
            ),
          ),
        ],
      ),
    );
  }
}

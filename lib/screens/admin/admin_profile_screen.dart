import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_controller.dart';
import '../auth/login_screen.dart';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  Future<void> _changePassword(BuildContext context) async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current password'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm new password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password change is not yet implemented.')),
              );
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );

    currentCtrl.dispose();
    newCtrl.dispose();
    confirmCtrl.dispose();
  }

  Future<void> _logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (shouldLogout != true || !context.mounted) return;

    await context.read<AuthProvider>().logout();
    if (!context.mounted) return;
    await Navigator.of(context).pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = context.watch<AuthProvider>().user;
    final themeController = context.watch<ThemeController>();

    final displayName = user?.name ?? 'Admin';
    final displayEmail = user?.email ?? '';
    final initials = displayName.isNotEmpty
        ? displayName.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : 'A';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // Avatar + name + badge
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: colorScheme.primary,
                  child: Text(
                    initials,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  displayName,
                  style: theme.textTheme.titleLarge,
                ),
                if (displayEmail.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    displayEmail,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'System Administrator',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Settings section
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                // Dark mode toggle
                SwitchListTile(
                  secondary: Icon(
                    themeController.isDark
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    color: colorScheme.primary,
                  ),
                  title: const Text('Dark Mode'),
                  subtitle: Text(
                    themeController.isDark ? 'Enabled' : 'Disabled',
                  ),
                  value: themeController.isDark,
                  onChanged: (_) => themeController.toggle(),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),

                // Change password
                ListTile(
                  leading: Icon(Icons.lock_outline_rounded,
                      color: colorScheme.primary),
                  title: const Text('Change Password'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _changePassword(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Logout button
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.red),
              title: const Text(
                'Log out',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () => _logout(context),
            ),
          ),
        ],
      ),
    );
  }
}

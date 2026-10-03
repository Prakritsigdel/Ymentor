import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_routes.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_controller.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/common/app_logo_avatar.dart';
import '../auth/login_screen.dart';
import 'account_info_screen.dart';
import 'policy_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().refreshUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    if (user == null) return const LoginScreen();
    final theme = context.watch<ThemeController>();
    final role = user.isMentor
        ? 'Mentor'
        : user.isAdmin
            ? 'Admin'
            : 'Mentee';
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
              child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(children: [
              Stack(children: [
                AppLogoAvatar(
                    size: 84,
                    imageUrl: user.avatarUrl,
                    fallbackText: _initials(user.name)),
                Positioned(
                    right: 0,
                    bottom: 0,
                    child: CircleAvatar(
                      radius: 15,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Icon(Icons.camera_alt,
                          size: 15,
                          color: Theme.of(context).colorScheme.onPrimary),
                    )),
              ]),
              const SizedBox(height: 10),
              Text(user.name, style: Theme.of(context).textTheme.titleLarge),
              Text(user.email),
              const SizedBox(height: 8),
              Chip(label: Text(role)),
              const Divider(height: 24),
              Row(children: [
                Expanded(
                    child: _action(
                        context,
                        theme.isDark ? Icons.light_mode : Icons.dark_mode,
                        theme.isDark ? 'Light mode' : 'Dark mode',
                        theme.toggle)),
                Expanded(
                    child: OutlinedButton.icon(
                  onPressed: () => _logout(context, auth),
                  icon: const Icon(Icons.logout, color: AppColors.danger),
                  label: const Text('Log out'),
                )),
              ]),
            ]),
          )),
          const SizedBox(height: 16),
          Row(children: [
            _stat(
                context, 'Wallet', CurrencyUtils.formatNPR(user.walletBalance)),
            _stat(context, 'Sessions', '${user.totalSessions}'),
            _stat(context, 'Plans', '0'),
          ]),
          const SizedBox(height: 16),
          _academicCard(context, user),
          _menu(context, 'SHORTCUTS', [
            _item(context, Icons.person_outline, 'Update Profile',
                () => Navigator.pushNamed(context, AppRoutes.updateProfile)),
            _item(context, Icons.lock_outline, 'Change Password',
                () => Navigator.pushNamed(context, AppRoutes.changePassword)),
            _item(
                context,
                Icons.badge_outlined,
                'Request ID Card',
                () => _openInfo(context, 'Request ID Card',
                    'Your identity-card request can be submitted to YMentor support. We will verify your account details and notify you when the card is ready.')),
            _item(
                context,
                Icons.notifications_none,
                'Your Notification',
                () => _openInfo(context, 'Your Notification',
                    'You are up to date. Booking, escrow, and mentorship updates will appear here.')),
          ]),
          _menu(context, 'SUPPORT', [
            _item(
                context,
                Icons.verified_outlined,
                'Certificate Verification',
                () => _openInfo(context, 'Certificate Verification',
                    'Upload verified qualifications through support to begin certificate review.')),
            _item(
                context,
                Icons.receipt_long_outlined,
                'Purchase History',
                () => _openInfo(context, 'Purchase History',
                    'Completed and active mentorship purchases are recorded in your booking and escrow history.')),
            _item(context, Icons.chat_outlined, 'WhatsApp',
                () => _openWhatsApp(context)),
          ]),
          _menu(context, 'OTHERS', [
            _item(
                context,
                Icons.shield_outlined,
                'Parent & Safety Settings',
                () => _openPolicy(context, 'Parent & Safety Settings', [
                      (
                        'Safe communication',
                        'Keep mentorship conversations inside YMentor and report suspicious requests to support.'
                      ),
                      (
                        'Escrow protection',
                        'Payments remain protected in escrow until the agreed session lifecycle is complete.'
                      ),
                    ])),
            _item(
                context,
                Icons.privacy_tip_outlined,
                'Privacy Policy',
                () => _openPolicy(context, 'Privacy Policy', [
                      (
                        'Data we use',
                        'YMentor uses account, booking, and communication data to provide mentorship services.'
                      ),
                      (
                        'Your choices',
                        'You may request account updates or deletion by contacting support@ymentor.com.'
                      ),
                    ])),
            _item(
                context,
                Icons.description_outlined,
                'Terms & Condition',
                () => _openPolicy(context, 'Terms & Conditions', [
                      (
                        'Using YMentor',
                        'Users must provide accurate account information and use the platform respectfully.'
                      ),
                      (
                        'Bookings',
                        'Bookings are confirmed only after the displayed amount is held in escrow.'
                      ),
                    ])),
            _item(
                context,
                Icons.assignment_return_outlined,
                'Return & Refund Policy',
                () => _openPolicy(context, 'Return & Refund Policy', [
                      (
                        'Cancellations',
                        'Refund eligibility depends on the booking status and the applicable dispute review.'
                      ),
                      (
                        'Disputes',
                        'Contact support promptly with booking details so the escrow team can review the matter.'
                      ),
                    ])),
          ]),
        ],
      ),
    );
  }

  void _openInfo(BuildContext context, String title, String description) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AccountInfoScreen(title: title, description: description),
    ));
  }

  void _openPolicy(
      BuildContext context, String title, List<(String, String)> sections) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PolicyScreen(title: title, sections: sections),
    ));
  }

  Widget _academicCard(BuildContext context, dynamic user) => Card(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mentorship & Academic Profile',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Text(
                    '${user.faculty.isEmpty ? 'Software Engineering' : user.faculty} · ${user.title.isEmpty ? 'Student' : user.title}'),
                const SizedBox(height: 6),
                Text(user.bio.isEmpty ? 'No bio added yet.' : user.bio),
                const SizedBox(height: 10),
                Wrap(
                    spacing: 8,
                    children: user.skillsOrInterests
                        .map<Widget>((s) => Chip(label: Text(s)))
                        .toList()),
              ],
            )),
      );

  Widget _menu(BuildContext context, String title, List<Widget> items) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: Theme.of(context).colorScheme.primary)),
          const SizedBox(height: 6),
          Card(child: Column(children: items)),
        ],
      );

  Widget _item(BuildContext context, IconData icon, String label,
          VoidCallback onTap) =>
      ListTile(
          leading: Icon(icon),
          title: Text(label),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap);

  Widget _stat(BuildContext context, String label, String value) => Expanded(
          child: Card(
        child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
            child: Column(children: [
              Text(value, style: Theme.of(context).textTheme.titleMedium),
              Text(label)
            ])),
      ));

  Widget _action(BuildContext context, IconData icon, String label,
          VoidCallback onTap) =>
      TextButton.icon(onPressed: onTap, icon: Icon(icon), label: Text(label));

  Future<void> _logout(BuildContext context, AuthProvider auth) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('Log out?'),
              content: const Text('You can sign in again at any time.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Log out'))
              ],
            ));
    if (confirmed != true) return;
    await auth.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    final uri = Uri.parse('https://wa.me/?text=Hello%20YMentor%20Support');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open WhatsApp.')),
      );
    }
  }

  String _initials(String name) => name
      .trim()
      .split(' ')
      .where((s) => s.isNotEmpty)
      .take(2)
      .map((s) => s[0])
      .join()
      .toUpperCase();
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../../widgets/admin_modules.dart';
import '../../services/api_service.dart';
import '../../utils/currency_formatter.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  Future<void> _showLogoutConfirmationDialog(BuildContext context) async {
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
  Widget build(BuildContext context) => DefaultTabController(
        length: 7,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Admin Control Center'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                tooltip: 'Logout',
                onPressed: () => _showLogoutConfirmationDialog(context),
              ),
            ],
            bottom: const TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: 'KYC'),
                Tab(text: 'Ledger'),
                Tab(text: 'Disputes'),
                Tab(text: 'Users'),
                Tab(text: 'Reviews'),
                Tab(text: 'Analytics'),
                Tab(text: 'System'),
              ],
            ),
          ),
          body: Column(
            children: [
              FutureBuilder<dynamic>(
                future: ApiService.adminGet('summary'),
                builder: (context, snapshot) {
                  final data = snapshot.data is Map
                      ? Map<String, dynamic>.from(snapshot.data as Map)
                      : const <String, dynamic>{};
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _metric(context, 'Pending KYC', data['pendingKyc'] ?? 0,
                            Icons.verified_user_outlined),
                        _metric(
                            context,
                            'Escrow locked',
                            CurrencyUtils.formatNPR(
                                (data['activeEscrow'] as num?) ?? 0),
                            Icons.lock_clock_outlined),
                        _metric(
                            context,
                            'GMV',
                            CurrencyUtils.formatNPR((data['gmv'] as num?) ?? 0),
                            Icons.trending_up_outlined),
                        _metric(context, 'Open disputes',
                            data['openDisputes'] ?? 0, Icons.gavel_outlined),
                        _metric(
                            context,
                            'Commission',
                            CurrencyUtils.formatNPR(
                                (data['commissionRevenue'] as num?) ?? 0),
                            Icons.account_balance_outlined),
                        _metric(
                            context,
                            'Released payouts',
                            CurrencyUtils.formatNPR(
                                (data['releasedPayouts'] as num?) ?? 0),
                            Icons.payments_outlined),
                      ],
                    ),
                  );
                },
              ),
              const Expanded(
                child: TabBarView(
                  children: [
                    AdminKycModule(),
                    AdminLedgerModule(),
                    AdminDisputesModule(),
                    AdminUsersModule(),
                    AdminReviewsModule(),
                    AdminAnalyticsModule(),
                    AdminSystemModule(),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.background,
        ),
      );

  Widget _metric(
    BuildContext context,
    String label,
    Object value,
    IconData icon,
  ) {
    return SizedBox(
      width: 165,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis),
                    Text('$value',
                        style: Theme.of(context).textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

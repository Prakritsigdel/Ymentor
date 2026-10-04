import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/currency_formatter.dart';
import 'admin_profile_screen.dart';
import 'sub_screens/admin_kyc_screen.dart';
import 'sub_screens/admin_users_screen.dart';
import 'sub_screens/admin_ledger_screen.dart';
import 'sub_screens/admin_disputes_screen.dart';
import 'sub_screens/admin_analytics_screen.dart';
import 'sub_screens/admin_reviews_screen.dart';
import 'sub_screens/admin_system_screen.dart';
import 'sub_screens/admin_payouts_screen.dart';

// ---------------------------------------------------------------------------
// Data model for a hub navigation card
// ---------------------------------------------------------------------------
class _HubCard {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Widget destination;

  const _HubCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.destination,
  });
}

// ---------------------------------------------------------------------------
// Admin Dashboard Screen — Navigation Hub
// ---------------------------------------------------------------------------
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  static final List<_HubCard> _cards = [
    _HubCard(
      title: 'KYC Verifications',
      subtitle: 'Review pending mentor applications',
      icon: Icons.verified_user_outlined,
      iconColor: AppColors.cyan,
      destination: const AdminKycScreen(),
    ),
    _HubCard(
      title: 'User Management',
      subtitle: 'Search, view & suspend accounts',
      icon: Icons.people_outlined,
      iconColor: AppColors.mint,
      destination: const AdminUsersScreen(),
    ),
    _HubCard(
      title: 'Financial Ledger',
      subtitle: 'GMV, escrow & payout transactions',
      icon: Icons.receipt_long_outlined,
      iconColor: AppColors.primary,
      destination: const AdminLedgerScreen(),
    ),
    _HubCard(
      title: 'Dispute Resolution',
      subtitle: 'Handle and resolve open disputes',
      icon: Icons.gavel_outlined,
      iconColor: AppColors.terracotta,
      destination: const AdminDisputesScreen(),
    ),
    _HubCard(
      title: 'Platform Analytics',
      subtitle: 'DAU, registrations & top skills',
      icon: Icons.bar_chart_rounded,
      iconColor: AppColors.star,
      destination: const AdminAnalyticsScreen(),
    ),
    _HubCard(
      title: 'Review Moderation',
      subtitle: 'Approve, edit or remove reviews',
      icon: Icons.star_outline_rounded,
      iconColor: AppColors.star,
      destination: const AdminReviewsScreen(),
    ),
    _HubCard(
      title: 'System Settings',
      subtitle: 'Fee policy & broadcast center',
      icon: Icons.settings_outlined,
      iconColor: AppColors.textSecondary,
      destination: const AdminSystemScreen(),
    ),
    _HubCard(
      title: 'Payout Management',
      subtitle: 'Release held escrow to mentors',
      icon: Icons.payments_outlined,
      iconColor: AppColors.mint,
      destination: const AdminPayoutsScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = context.watch<AuthProvider>().user;
    final initials = (user?.name ?? 'A')
        .trim()
        .split(' ')
        .map((w) => w[0])
        .take(2)
        .join()
        .toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Control Center'),
        actions: [
          // Profile avatar icon
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: GestureDetector(
              onTap: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const AdminProfileScreen(),
                ),
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: colorScheme.primary,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ----------------------------------------------------------------
          // Summary stats strip
          // ----------------------------------------------------------------
          FutureBuilder<dynamic>(
            future: ApiService.adminGet('summary'),
            builder: (context, snapshot) {
              final data = snapshot.data is Map
                  ? Map<String, dynamic>.from(snapshot.data as Map)
                  : const <String, dynamic>{};
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _metric(
                      context,
                      'Pending KYC',
                      data['pendingKyc'] ?? 0,
                      Icons.verified_user_outlined,
                    ),
                    _metric(
                      context,
                      'Escrow locked',
                      CurrencyUtils.formatNPR(
                          (data['activeEscrow'] as num?) ?? 0),
                      Icons.lock_clock_outlined,
                    ),
                    _metric(
                      context,
                      'GMV',
                      CurrencyUtils.formatNPR((data['gmv'] as num?) ?? 0),
                      Icons.trending_up_outlined,
                    ),
                    _metric(
                      context,
                      'Open disputes',
                      data['openDisputes'] ?? 0,
                      Icons.gavel_outlined,
                    ),
                    _metric(
                      context,
                      'Commission',
                      CurrencyUtils.formatNPR(
                          (data['commissionRevenue'] as num?) ?? 0),
                      Icons.account_balance_outlined,
                    ),
                    _metric(
                      context,
                      'Released payouts',
                      CurrencyUtils.formatNPR(
                          (data['releasedPayouts'] as num?) ?? 0),
                      Icons.payments_outlined,
                    ),
                  ],
                ),
              );
            },
          ),

          const Divider(height: 16),

          // ----------------------------------------------------------------
          // Navigation hub card list
          // ----------------------------------------------------------------
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16.0, vertical: 12.0),
              itemCount: _cards.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12.0),
              itemBuilder: (context, index) {
                final card = _cards[index];
                return _NavCard(card: card);
              },
            ),
          ),
        ],
      ),
    );
  }

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

// ---------------------------------------------------------------------------
// Navigation card widget
// ---------------------------------------------------------------------------
class _NavCard extends StatelessWidget {
  final _HubCard card;
  const _NavCard({required this.card});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push<void>(
          MaterialPageRoute<void>(builder: (_) => card.destination),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Left: rounded icon container
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: card.iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(card.icon, color: card.iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              // Middle: title + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.title,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      card.subtitle,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Right: chevron
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

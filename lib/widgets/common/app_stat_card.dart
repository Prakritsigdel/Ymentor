import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../config/theme.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AppStatCard — Compact metric / KPI display card
///
/// Used in mentor dashboards and admin panels to display a labelled
/// numeric stat with an accent colour and optional icon.
///
/// Usage:
///   AppStatCard(
///     label: 'Wallet Balance',
///     value: '\$320.00',
///     color: AppColors.mint,
///     icon: IconsaxPlusBold.wallet,
///   )
/// ─────────────────────────────────────────────────────────────────────────────
class AppStatCard extends StatelessWidget {
  const AppStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.icon,
    this.subtitle,
  });

  final String label;
  final String value;
  final Color color;
  final IconData? icon;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 4),
                Icon(icon, size: 15, color: color.withValues(alpha: 0.7)),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(
              subtitle!,
              style: const TextStyle(
                color: AppColors.textDisabled,
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// AppStatRow — Convenience widget rendering two AppStatCards in a Row
/// ─────────────────────────────────────────────────────────────────────────────
class AppStatRow extends StatelessWidget {
  const AppStatRow({super.key, required this.left, required this.right});

  final AppStatCard left;
  final AppStatCard right;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: 10),
        Expanded(child: right),
      ],
    );
  }
}

/// Convenience stat icons that map common Ymentor metrics to Iconsax icons
class AppStatIcons {
  static const IconData wallet       = IconsaxPlusBold.wallet;
  static const IconData escrow       = IconsaxPlusBold.lock;
  static const IconData sessions     = IconsaxPlusBold.people;
  static const IconData rating       = IconsaxPlusBold.star_1;
  static const IconData earnings     = IconsaxPlusBold.money;
  static const IconData leaderboard  = IconsaxPlusBold.ranking;
  static const IconData pendingUsers = IconsaxPlusBold.clock;
  static const IconData fees         = IconsaxPlusBold.percentage_circle;
}

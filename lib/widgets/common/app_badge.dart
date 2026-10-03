import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AppBadge — Compact role / status / label badge
///
/// Usage:
///   AppBadge(label: 'MENTOR', color: AppColors.mint)
///   AppBadge.role(role: 'admin')     ← auto-coloured role badge
///   AppBadge.status(status: 'active')← semantic status badge
/// ─────────────────────────────────────────────────────────────────────────────
class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.size = AppBadgeSize.md,
  });

  /// Auto-coloured role badge (admin/mentor/mentee)
  factory AppBadge.role(String role,
      {Key? key, AppBadgeSize size = AppBadgeSize.md}) {
    final (label, color) = switch (role.toLowerCase()) {
      'admin' => ('⚡ ADMIN', AppColors.roleAdmin),
      'mentor' => ('🎓 MENTOR', AppColors.roleMentor),
      _ => ('📚 MENTEE', AppColors.roleMentee),
    };
    return AppBadge(key: key, label: label, color: color, size: size);
  }

  /// Semantic status badge (active / pending_approval / suspended)
  factory AppBadge.status(String status,
      {Key? key, AppBadgeSize size = AppBadgeSize.sm}) {
    final (label, color) = switch (status.toLowerCase()) {
      'active' => ('● ACTIVE', AppColors.verified),
      'pending_approval' => ('◉ PENDING', AppColors.warning),
      'suspended' => ('✕ SUSPENDED', AppColors.error),
      _ => (status.toUpperCase(), AppColors.textSecondary),
    };
    return AppBadge(key: key, label: label, color: color, size: size);
  }

  final String label;
  final Color color;
  final Widget? icon;
  final AppBadgeSize size;

  double get _fontSize => switch (size) {
        AppBadgeSize.sm => 9.0,
        AppBadgeSize.md => 10.5,
        AppBadgeSize.lg => 12.0,
      };

  EdgeInsets get _padding => switch (size) {
        AppBadgeSize.sm =>
          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        AppBadgeSize.md =>
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        AppBadgeSize.lg =>
          const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: _padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppRadius.fullAll,
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            IconTheme(
              data: IconThemeData(color: color, size: _fontSize + 2),
              child: icon!,
            ),
            SizedBox(width: _fontSize * 0.35),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: _fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

enum AppBadgeSize { sm, md, lg }

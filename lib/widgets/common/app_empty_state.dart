import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../config/theme.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AppEmptyState — Zero-data empty state illustration + CTA
///
/// Usage:
///   AppEmptyState(
///     icon: IconsaxPlusBold.folder_open,
///     title: 'No workspaces yet',
///     subtitle: 'Book a session to create one.',
///     action: AppEmptyStateAction(label: 'Browse Mentors', onPressed: () {}),
///   )
/// ─────────────────────────────────────────────────────────────────────────────
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    this.icon = IconsaxPlusBold.folder_open,
    required this.title,
    this.subtitle,
    this.action,
    this.iconColor,
    this.iconSize = 56,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final AppEmptyStateAction? action;
  final Color? iconColor;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppColors.textDisabled;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with glow circle background
            Container(
              width: iconSize * 1.8,
              height: iconSize * 1.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.08),
                border: Border.all(color: color.withValues(alpha: 0.18), width: 1.5),
              ),
              child: Icon(icon, size: iconSize, color: color),
            )
                .animate()
                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), duration: 350.ms, curve: Curves.easeOut)
                .fadeIn(duration: 350.ms),

            const SizedBox(height: 20),

            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 80.ms, duration: 300.ms).slideY(begin: 0.1, end: 0),

            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 140.ms, duration: 300.ms),
            ],

            if (action != null) ...[
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: action!.onPressed,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.mint),
                  foregroundColor: AppColors.mint,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
                ),
                child: Text(
                  action!.label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
            ],
          ],
        ),
      ),
    );
  }
}

/// Optional CTA button spec for AppEmptyState
class AppEmptyStateAction {
  const AppEmptyStateAction({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;
}

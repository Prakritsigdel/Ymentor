import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AppCard — Ymentor surface card with optional glow, gradient, and tap ripple
///
/// Usage:
///   AppCard(child: ...)
///   AppCard.glow(child: ...)     ← mint drop-shadow glow
///   AppCard.gradient(child: ...) ← dark gradient background
/// ─────────────────────────────────────────────────────────────────────────────
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.showGlow = false,
    this.showGradient = false,
    this.borderColor,
    this.borderRadius,
  });

  /// Named constructor: mint glow variant
  const AppCard.glow({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.borderColor,
    this.borderRadius,
  })  : showGlow = true,
        showGradient = false;

  /// Named constructor: dark gradient fill
  const AppCard.gradient({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.borderColor,
    this.borderRadius,
  })  : showGlow = false,
        showGradient = true;

  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  final bool showGlow;
  final bool showGradient;
  final Color? borderColor;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppRadius.lgAll;
    final effectiveBorderColor = borderColor ?? AppColors.border;

    Widget content = Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: effectiveBorderColor),
        gradient: showGradient ? AppColors.cardGradient : null,
        color: showGradient ? null : AppColors.surface,
        boxShadow: showGlow ? AppShadows.mintGlow : AppShadows.card,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Padding(
          padding: padding ?? const EdgeInsets.all(AppSpacing.md),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          splashColor: AppColors.primary.withValues(alpha: 0.08),
          highlightColor: AppColors.primary.withValues(alpha: 0.04),
          child: content,
        ),
      );
    }

    return Container(
      margin: margin,
      child: content,
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.04, end: 0, duration: 250.ms);
  }
}

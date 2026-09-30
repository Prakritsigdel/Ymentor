import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';

/// Variant enum for AppButton style
enum AppButtonVariant { primary, secondary, outlined, ghost, danger }

/// ─────────────────────────────────────────────────────────────────────────────
/// AppButton — Ymentor design-system button component
///
/// Supports:
///   • primary (mint fill)  • secondary (surface fill)
///   • outlined (border)    • ghost (transparent)
///   • danger (red fill)
///   • loading spinner state
///   • optional leading / trailing icons
///   • press-scale micro-animation via flutter_animate
/// ─────────────────────────────────────────────────────────────────────────────
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.size = AppButtonSize.md,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final bool isLoading;
  final bool isFullWidth;
  final AppButtonSize size;

  @override
  State<AppButton> createState() => _AppButtonState();
}

enum AppButtonSize { sm, md, lg }

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  (Color bg, Color fg, Border? border) get _style {
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return (AppColors.primary, Colors.white, null);
      case AppButtonVariant.secondary:
        return (AppColors.surface, AppColors.textPrimary,
            Border.all(color: AppColors.border));
      case AppButtonVariant.outlined:
        return (Colors.transparent, AppColors.primary,
            Border.all(color: AppColors.primary, width: 1.5));
      case AppButtonVariant.ghost:
        return (Colors.transparent, AppColors.textSecondary, null);
      case AppButtonVariant.danger:
        return (AppColors.error, Colors.white, null);
    }
  }

  EdgeInsets get _padding {
    switch (widget.size) {
      case AppButtonSize.sm:
        return const EdgeInsets.symmetric(horizontal: 14, vertical: 8);
      case AppButtonSize.md:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 13);
      case AppButtonSize.lg:
        return const EdgeInsets.symmetric(horizontal: 28, vertical: 17);
    }
  }

  double get _fontSize {
    switch (widget.size) {
      case AppButtonSize.sm: return 12;
      case AppButtonSize.md: return 14;
      case AppButtonSize.lg: return 16;
    }
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = _style;
    final isDisabled = widget.onPressed == null || widget.isLoading;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        if (!isDisabled) widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedOpacity(
          opacity: isDisabled ? 0.5 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: Container(
            width: widget.isFullWidth ? double.infinity : null,
            padding: _padding,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: AppRadius.xlAll,
              border: border,
              boxShadow: null,
            ),
            child: Row(
              mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.isLoading) ...[
                  SizedBox(
                    width: _fontSize + 2,
                    height: _fontSize + 2,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: fg,
                    ),
                  ),
                  const SizedBox(width: 8),
                ] else if (widget.leadingIcon != null) ...[
                  IconTheme(
                    data: IconThemeData(color: fg, size: _fontSize + 2),
                    child: widget.leadingIcon!,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  widget.label,
                  style: TextStyle(
                    color: fg,
                    fontSize: _fontSize,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                  ),
                ),
                if (widget.trailingIcon != null && !widget.isLoading) ...[
                  const SizedBox(width: 6),
                  IconTheme(
                    data: IconThemeData(color: fg, size: _fontSize + 2),
                    child: widget.trailingIcon!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms);
  }
}

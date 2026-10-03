import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../config/theme.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AppSkeleton — Shimmer loading placeholders using `skeletonizer`
///
/// Usage:
///   AppSkeleton.card()           → rectangular card placeholder
///   AppSkeleton.listItem()       → avatar + two text lines
///   AppSkeleton.text(lines: 3)   → N lines of text shimmer
///   AppSkeleton.avatar(radius)   → circular avatar shimmer
///   AppSkeleton.statRow()        → two stat cards side by side
/// ─────────────────────────────────────────────────────────────────────────────
class AppSkeleton extends StatelessWidget {
  const AppSkeleton._({required this.child});

  final Widget child;

  /// Full-width card skeleton (height defaults to 100)
  factory AppSkeleton.card({double height = 100}) {
    return AppSkeleton._(
      child: _Wrap(
        child: _Bone(
          width: double.infinity,
          height: height,
          radius: AppRadius.lgAll,
        ),
      ),
    );
  }

  /// Avatar + two text lines (mimics a mentor list item)
  factory AppSkeleton.listItem() {
    return AppSkeleton._(
      child: _Wrap(
        child: Row(
          children: [
            _Bone(width: 48, height: 48, radius: AppRadius.fullAll),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Bone(width: 140, height: 14, radius: AppRadius.smAll),
                  const SizedBox(height: 8),
                  _Bone(width: 100, height: 11, radius: AppRadius.smAll),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// N horizontal text-line shimmer bars
  factory AppSkeleton.text({int lines = 3, double lineHeight = 13}) {
    return AppSkeleton._(
      child: _Wrap(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(lines, (i) {
            final width = i == lines - 1 ? 180.0 : double.infinity;
            return Padding(
              padding: EdgeInsets.only(bottom: i < lines - 1 ? 8.0 : 0),
              child: _Bone(
                  width: width, height: lineHeight, radius: AppRadius.smAll),
            );
          }),
        ),
      ),
    );
  }

  /// Circular avatar shimmer
  factory AppSkeleton.avatar({double radius = 24}) {
    return AppSkeleton._(
      child: _Wrap(
        child: _Bone(
            width: radius * 2, height: radius * 2, radius: AppRadius.fullAll),
      ),
    );
  }

  /// Two stat cards side by side
  factory AppSkeleton.statRow() {
    return AppSkeleton._(
      child: _Wrap(
        child: Row(
          children: [
            Expanded(
                child: _Bone(
                    width: double.infinity,
                    height: 72,
                    radius: AppRadius.lgAll)),
            const SizedBox(width: 10),
            Expanded(
                child: _Bone(
                    width: double.infinity,
                    height: 72,
                    radius: AppRadius.lgAll)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => child;
}

/// Internal wrapper that activates the Skeletonizer shimmer effect
class _Wrap extends StatelessWidget {
  const _Wrap({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      effect: ShimmerEffect(
        baseColor: AppColors.surface,
        highlightColor: AppColors.surfaceHigh,
        duration: const Duration(milliseconds: 1200),
      ),
      child: child,
    );
  }
}

/// Single shimmer bone shape
class _Bone extends StatelessWidget {
  const _Bone(
      {required this.width, required this.height, required this.radius});
  final double width;
  final double height;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: radius,
      ),
    );
  }
}

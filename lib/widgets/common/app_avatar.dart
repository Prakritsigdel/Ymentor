import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AppAvatar — Initials avatar with role-colour ring
///
/// Shows the user's photo (avatarUrl) if provided, otherwise renders
/// coloured initials derived from the name.  An optional ring / glow
/// border is drawn using the role accent colour.
///
/// Usage:
///   AppAvatar(name: 'Sarah Connor', role: 'mentor', radius: 24)
///   AppAvatar(name: 'Admin', role: 'admin', imageUrl: user.avatarUrl, radius: 28)
/// ─────────────────────────────────────────────────────────────────────────────
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.name,
    this.role = 'mentee',
    this.imageUrl,
    this.radius = 22,
    this.showRing = true,
    this.fontSize,
  });

  final String name;
  final String role;
  final String? imageUrl;
  final double radius;
  final bool showRing;
  final double? fontSize;

  Color get _roleColor => switch (role.toLowerCase()) {
    'admin'  => AppColors.roleAdmin,
    'mentor' => AppColors.roleMentor,
    _        => AppColors.roleMentee,
  };

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    final effectiveFontSize = fontSize ?? (radius * 0.6).clamp(10.0, 28.0);

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: showRing
            ? Border.all(
                color: _roleColor.withValues(alpha: 0.55),
                width: 2,
              )
            : null,
        boxShadow: showRing
            ? [
                BoxShadow(
                  color: _roleColor.withValues(alpha: 0.18),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: ClipOval(
        child: hasImage
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _initialsWidget(effectiveFontSize),
              )
            : _initialsWidget(effectiveFontSize),
      ),
    );
  }

  Widget _initialsWidget(double fSize) {
    return Container(
      color: _roleColor.withValues(alpha: 0.18),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          color: _roleColor,
          fontSize: fSize,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

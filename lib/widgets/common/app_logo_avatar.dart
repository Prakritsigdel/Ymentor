import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class AppLogoAvatar extends StatelessWidget {
  final double size;
  final String? assetPath;
  final String? imageUrl;
  final String? fallbackText;
  final Color backgroundColor;
  final Color foregroundColor;
  final BoxFit fit;
  final bool circular;

  const AppLogoAvatar({
    super.key,
    this.size = 44,
    this.assetPath,
    this.imageUrl,
    this.fallbackText,
    this.backgroundColor = AppColors.surfaceRaised,
    this.foregroundColor = AppColors.mint,
    this.fit = BoxFit.cover,
    this.circular = true,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = _fallback();
    final shape = circular ? BoxShape.circle : BoxShape.rectangle;
    final borderRadius = circular ? null : BorderRadius.circular(size * 0.22);
    final imageUri = imageUrl == null ? null : Uri.tryParse(imageUrl!);
    final canLoadNetworkImage = imageUri != null &&
        (imageUri.scheme == 'http' || imageUri.scheme == 'https') &&
        imageUri.host.isNotEmpty;

    Widget image;
    if (canLoadNetworkImage) {
      image = Image.network(
        imageUrl!,
        width: size,
        height: size,
        fit: fit,
        errorBuilder: (_, __, ___) => fallback,
      );
    } else if (assetPath != null && assetPath!.trim().isNotEmpty) {
      image = Image.asset(
        assetPath!,
        width: size,
        height: size,
        fit: fit,
        errorBuilder: (_, __, ___) => fallback,
      );
    } else {
      image = fallback;
    }

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: shape,
        borderRadius: borderRadius,
        border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
      ),
      child: image,
    );
  }

  Widget _fallback() {
    final text = fallbackText?.trim();
    final label = text == null || text.isEmpty ? 'Ym' : text;
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          style: GoogleFonts.playfairDisplay(
            color: foregroundColor,
            fontSize: size * (label == 'Ym' ? 0.42 : 0.38),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

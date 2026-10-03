import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class YmLogo extends StatelessWidget {
  final double size;
  final bool useImageAsset;

  const YmLogo({
    super.key,
    this.size = 120.0,
    this.useImageAsset = true, // Set to false if image asset is not added yet
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF07120D),
        border: Border.all(color: AppColors.primaryAccent, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryAccent.withValues(alpha: 0.3),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(
        child: useImageAsset
            ? Image.asset(
                'assets/images/app_logo.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildNativeLogo(),
              )
            : _buildNativeLogo(),
      ),
    );
  }

  // Native fallback matching the high-contrast Serif "Y" + Italic "m"
  Widget _buildNativeLogo() {
    return Center(
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: 'Y',
              style: GoogleFonts.playfairDisplay(
                fontSize: size * 0.42,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryAccent,
              ),
            ),
            TextSpan(
              text: 'm',
              style: GoogleFonts.playfairDisplay(
                fontSize: size * 0.42,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
                color: AppColors.primaryAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

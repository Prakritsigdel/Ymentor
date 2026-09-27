import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color background = Color(0xFF03120D);
  static const Color surface = Color(0xFF07281D);
  static const Color surfaceRaised = Color(0xFF0E382B);
  static const Color primary = Color(0xFF0084FF);
  static const Color mint = Color(0xFF00E699);
  static const Color star = Color(0xFFFFB800);
  static const Color terracotta = Color(0xFFFF5630);
  static const Color cream = Color(0xFFFAF8F5);
  static const Color textPrimary = Color(0xFFFAF8F5);
  static const Color textSecondary = Color(0xFFAAC0B7);
  static const Color border = Color(0xFF24483B);
  static const Color cyan = primary;
  static const Color verified = mint;
}

class AppTheme {
  static ThemeData get darkTheme {
    final body = GoogleFonts.plusJakartaSans();
    final headline = GoogleFonts.playfairDisplay();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.mint,
        surface: AppColors.surface,
        error: AppColors.terracotta,
      ),
      cardColor: AppColors.surface,
      dividerColor: Colors.white24,
      textTheme: TextTheme(
        displayLarge: headline.copyWith(
            color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        headlineLarge: headline.copyWith(
            color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        headlineMedium: headline.copyWith(
            color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        titleLarge: body.copyWith(
            color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        titleMedium: body.copyWith(
            color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        bodyLarge: body.copyWith(color: AppColors.textPrimary),
        bodyMedium: body.copyWith(color: AppColors.textSecondary),
        labelLarge: body.copyWith(
            color: AppColors.textPrimary, fontWeight: FontWeight.w700),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: body.copyWith(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: body.copyWith(color: AppColors.textSecondary),
        labelStyle: body.copyWith(color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary,
        labelStyle: body.copyWith(color: AppColors.textPrimary, fontSize: 12),
        secondaryLabelStyle: body.copyWith(color: Colors.white, fontSize: 12),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.mint,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// YMENTOR DESIGN SYSTEM — Dark Navy & Electric Mint
/// Palette: #0B0F12 (background) + #141C22 (surface) + #00E699 (primaryAccent)
/// Typography: Plus Jakarta Sans
/// ─────────────────────────────────────────────────────────────────────────────

class AppColors {
  // ── Core Requested Palette ──────────────────────────────────────────────────
  static const Color background = Color(0xFF0B0F12);
  static const Color surface = Color(0xFF141C22);
  static const Color surfaceBorder = Color(0x14FFFFFF); // Colors.white with 0.08 alpha
  static const Color primaryAccent = Color(0xFF00E699);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color danger = Color(0xFFFF5252);
  static const Color dangerSurface = Color(0xFF1E1014);

  // ── Aliases & Backward Compatibility ────────────────────────────────────────
  static const Color mint = primaryAccent;
  static const Color mintDim = Color(0xFF00B377);
  static const Color mintGlow = Color(0x3300E699);
  static const Color border = surfaceBorder;
  static const Color surfaceHigh = Color(0xFF1C2730);
  static const Color error = danger;
  static const Color cyan = Color(0xFF38BDF8);
  static const Color verified = Color(0xFF00E699);
  static const Color warning = Color(0xFFF59E0B);
  static const Color star = Color(0xFFF59E0B);
  static const Color info = Color(0xFF38BDF8);
  static const Color textDisabled = Color(0xFF64748B);

  // ── Role Badges ─────────────────────────────────────────────────────────────
  static const Color roleAdmin = Color(0xFFF59E0B);
  static const Color roleMentor = Color(0xFF00E699);
  static const Color roleMentee = Color(0xFF38BDF8);

  // ── Gradients ───────────────────────────────────────────────────────────────
  static const LinearGradient mintGradient = LinearGradient(
    colors: [Color(0xFF00E699), Color(0xFF00B377)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF141C22), Color(0xFF0B0F12)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

/// Shared border-radius tokens
class AppRadius {
  static const double xs = 6.0;
  static const double sm = 10.0;
  static const double md = 14.0;
  static const double lg = 18.0;
  static const double xl = 24.0;
  static const double full = 100.0;

  static BorderRadius get xsAll => BorderRadius.circular(xs);
  static BorderRadius get smAll => BorderRadius.circular(sm);
  static BorderRadius get mdAll => BorderRadius.circular(md);
  static BorderRadius get lgAll => BorderRadius.circular(lg);
  static BorderRadius get xlAll => BorderRadius.circular(xl);
  static BorderRadius get fullAll => BorderRadius.circular(full);
}

/// Shared spacing tokens (8-pt grid)
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

/// Shared elevation / shadow tokens
class AppShadows {
  static List<BoxShadow> get card => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get mintGlow => [
        BoxShadow(
          color: AppColors.primaryAccent.withValues(alpha: 0.25),
          blurRadius: 20,
          spreadRadius: 1,
        ),
      ];

  static List<BoxShadow> get none => [];
}

class AppTheme {
  static ThemeData get darkTheme {
    final baseDark = ThemeData.dark();
    final plusJakartaText = GoogleFonts.plusJakartaSansTextTheme(baseDark.textTheme);

    return baseDark.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primaryAccent,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.surface,
        primary: AppColors.primaryAccent,
        secondary: AppColors.cyan,
        error: AppColors.danger,
        onPrimary: AppColors.background,
        onSurface: AppColors.textPrimary,
        outline: Color(0x1FFFFFFF),
      ),
      textTheme: plusJakartaText.copyWith(
        displayLarge: plusJakartaText.displayLarge?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
        ),
        displayMedium: plusJakartaText.displayMedium?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        headlineLarge: plusJakartaText.headlineLarge?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: plusJakartaText.headlineMedium?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: plusJakartaText.titleLarge?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: plusJakartaText.titleMedium?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: plusJakartaText.bodyLarge?.copyWith(
          color: AppColors.textPrimary,
        ),
        bodyMedium: plusJakartaText.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
        ),
        bodySmall: plusJakartaText.bodySmall?.copyWith(
          color: AppColors.textSecondary,
        ),
        labelLarge: plusJakartaText.labelLarge?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardColor: AppColors.surface,
      dividerColor: AppColors.surfaceBorder,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryAccent,
          foregroundColor: AppColors.background,
          disabledBackgroundColor: AppColors.surfaceBorder,
          disabledForegroundColor: AppColors.textDisabled,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          elevation: 0,
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: BorderSide(color: AppColors.surfaceBorder, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textDisabled, fontSize: 14),
        labelStyle: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary, fontSize: 14),
        floatingLabelStyle: GoogleFonts.plusJakartaSans(color: AppColors.primaryAccent, fontSize: 12),
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: AppColors.surfaceBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: AppColors.surfaceBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: const BorderSide(color: AppColors.primaryAccent, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: const BorderSide(color: AppColors.danger, width: 1.8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primaryAccent,
        disabledColor: AppColors.surfaceHigh,
        labelStyle: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontSize: 12),
        secondaryLabelStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.background,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        side: BorderSide(color: AppColors.surfaceBorder),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.fullAll),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primaryAccent,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 11),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: BorderSide(color: AppColors.surfaceBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceHigh,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        indicatorColor: AppColors.primaryAccent,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: AppColors.primaryAccent,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 13),
        dividerColor: AppColors.surfaceBorder,
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.surfaceBorder,
        thickness: 1,
        space: 0,
      ),
    );
  }
}

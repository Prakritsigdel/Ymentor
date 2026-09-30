import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceRaised = Color(0xFFFAFAFA);
  static const Color primary = Color(0xFFB71C1C);
  static const Color crimsonLight = Color(0xFFC62828);
  static const Color softBlue = Color(0xFFE3F2FD);
  static const Color softRose = Color(0xFFFCE4EC);
  static const Color softPeach = Color(0xFFFFF3E0);
  static const Color softMint = Color(0xFFE8F5E9);
  static const Color softYellow = Color(0xFFFFFDE7);
  static const Color softLavender = Color(0xFFF3E5F5);
  static const Color mint = Color(0xFF2E7D32);
  static const Color star = Color(0xFFFFB800);
  static const Color terracotta = Color(0xFFD32F2F);
  static const Color cream = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1E1E1E);
  static const Color textSecondary = Color(0xFF666666);
  static const Color border = Color(0xFFE0E0E0);
  static const Color cyan = Color(0xFF0288D1);
  static const Color verified = mint;
  static const Color surfaceBorder = Color(0xFFE0E0E0);
  static const Color primaryAccent = primary;
  static const Color danger = terracotta;
  static const Color dangerSurface = Color(0xFFFFEBEE);
  static const Color error = terracotta;
  static const Color warning = star;
  static const Color info = cyan;
  static const Color textDisabled = Color(0xFF9E9E9E);
  static const Color surfaceHigh = surfaceRaised;
  static const Color roleAdmin = star;
  static const Color roleMentor = mint;
  static const Color roleMentee = cyan;

  static const LinearGradient mintGradient = LinearGradient(
    colors: [primary, crimsonLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [surface, surfaceRaised],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

class AppRadius {
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double full = 100;

  static BorderRadius get xsAll => BorderRadius.circular(xs);
  static BorderRadius get smAll => BorderRadius.circular(sm);
  static BorderRadius get mdAll => BorderRadius.circular(md);
  static BorderRadius get lgAll => BorderRadius.circular(lg);
  static BorderRadius get xlAll => BorderRadius.circular(xl);
  static BorderRadius get fullAll => BorderRadius.circular(full);
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class AppShadows {
  static List<BoxShadow> get card => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ];

  static List<BoxShadow> get mintGlow => [
        BoxShadow(
          color: AppColors.mint.withValues(alpha: 0.25),
          blurRadius: 20,
          spreadRadius: 1,
        ),
      ];

  static List<BoxShadow> get none => [];
}

class AppTheme {
  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color text,
    required Color muted,
    required Color primary,
  }) {
    final body = GoogleFonts.plusJakartaSans();
    final headline = GoogleFonts.playfairDisplay();

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: Colors.white,
        secondary: AppColors.cyan,
        onSecondary: Colors.white,
        surface: surface,
        onSurface: text,
        error: AppColors.terracotta,
        onError: Colors.white,
      ),
      cardColor: surface,
      dividerColor: muted.withValues(alpha: 0.2),
      textTheme: TextTheme(
        displayLarge: headline.copyWith(color: text, fontWeight: FontWeight.w700),
        headlineLarge: headline.copyWith(color: text, fontWeight: FontWeight.w700),
        headlineMedium: headline.copyWith(color: text, fontWeight: FontWeight.w700),
        titleLarge: body.copyWith(color: text, fontWeight: FontWeight.w700),
        titleMedium: body.copyWith(color: text, fontWeight: FontWeight.w600),
        bodyLarge: body.copyWith(color: text),
        bodyMedium: body.copyWith(color: muted),
        labelLarge: body.copyWith(color: text, fontWeight: FontWeight.w700),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: text,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          side: BorderSide(color: muted.withValues(alpha: 0.35)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: body.copyWith(color: muted),
        labelStyle: body.copyWith(color: muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: muted.withValues(alpha: 0.35)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: muted.withValues(alpha: 0.35)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: brightness == Brightness.dark ? const Color(0xFF2A2A2A) : AppColors.surfaceRaised,
        labelStyle: body.copyWith(color: text, fontSize: 12),
        side: BorderSide(color: muted.withValues(alpha: 0.25)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: AppColors.cyan,
        unselectedItemColor: muted,
      ),
      cardTheme: CardThemeData(
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: muted.withValues(alpha: 0.2)),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),
    );
  }

  static ThemeData get lightTheme => _build(
        brightness: Brightness.light,
        background: const Color(0xFFF8F9FA),
        surface: Colors.white,
        text: const Color(0xFF1A1A1A),
        muted: const Color(0xFF666666),
        primary: AppColors.primary,
      );

  static ThemeData get darkTheme => _build(
        brightness: Brightness.dark,
        background: const Color(0xFF0D0D0D),
        surface: const Color(0xFF1E1E1E),
        text: Colors.white,
        muted: const Color(0xFFBDBDBD),
        primary: const Color(0xFFE53935),
      );
}

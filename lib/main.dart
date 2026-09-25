import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'screens/root_shell.dart';
import 'screens/onboarding_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const YmentorApp());
}

class YmentorApp extends StatelessWidget {
  const YmentorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        title: 'Ymentor',
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AuthWrapper(),
      ),
    );
  }
}

/// Role-aware Router Widget:
/// - If isLoading -> loading splash indicator
/// - If not logged in -> RootShell (guests can browse Discover tab)
/// - If logged in:
///   - If admin -> AdminDashboardScreen
///   - If mentor/mentee & !isOnboarded -> OnboardingScreen
///   - If mentor/mentee & isOnboarded -> RootShell
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.mint.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.mint.withValues(alpha: 0.5), width: 2),
                ),
                child: const Icon(Icons.school, color: AppColors.mint, size: 36),
              ),
              const SizedBox(height: 18),
              const Text(
                'Ymentor',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Zero-Budget Micro-Mentorship Marketplace',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 24),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.mint),
              ),
            ],
          ),
        ),
      );
    }

    if (!auth.isLoggedIn || auth.user == null) {
      return const RootShell();
    }

    final user = auth.user!;

    // 1. ADMIN Routing
    if (user.isAdmin) {
      return const AdminDashboardScreen();
    }

    // 2. MENTOR / MENTEE with pending onboarding
    if (!user.isOnboarded) {
      return const OnboardingScreen();
    }

    // 3. MENTOR / MENTEE with completed onboarding
    return const RootShell();
  }
}

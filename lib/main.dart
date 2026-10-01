import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'config/app_routes.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_controller.dart';
import 'screens/root_shell.dart';
import 'screens/onboarding_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'widgets/common/app_logo_widget.dart';

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
  final themeController = ThemeController();
  runApp(
    ChangeNotifierProvider.value(
      value: themeController,
      child: const YmentorApp(),
    ),
  );
  themeController.load();
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
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: context.watch<ThemeController>().mode,
        routes: AppRoutes.routes,
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
              const AppLogoWidget(height: 72),
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
                'Find guidance. Grow with confidence.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 24),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: AppColors.mint),
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
    return RootShell(initialIndex: user.isMentor ? 4 : 0);
  }
}

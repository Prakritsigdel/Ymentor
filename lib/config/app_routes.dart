import 'package:flutter/material.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/update_profile_screen.dart';
import '../screens/profile/change_password_screen.dart';
import '../screens/root_shell.dart';
import '../screens/auth/login_screen.dart';

class AppRoutes {
  static const profile = '/profile';
  static const updateProfile = '/profile/update';
  static const changePassword = '/profile/change-password';
  static const rootShell = '/main';
  static const login = '/login';

  static Map<String, WidgetBuilder> get routes => {
        profile: (_) => const ProfileScreen(),
        updateProfile: (_) => const UpdateProfileScreen(),
        changePassword: (_) => const ChangePasswordScreen(),
        rootShell: (_) => const RootShell(),
        login: (_) => const LoginScreen(),
      };
}

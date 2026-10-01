import 'package:flutter/material.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/update_profile_screen.dart';
import '../screens/profile/change_password_screen.dart';

class AppRoutes {
  static const profile = '/profile';
  static const updateProfile = '/profile/update';
  static const changePassword = '/profile/change-password';

  static Map<String, WidgetBuilder> get routes => {
        profile: (_) => const ProfileScreen(),
        updateProfile: (_) => const UpdateProfileScreen(),
        changePassword: (_) => const ChangePasswordScreen(),
      };
}

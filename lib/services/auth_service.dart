class AuthService {
  const AuthService._();

  static bool get hasGoogleConfiguration => false;
  static bool get hasAppleConfiguration => false;

  static Future<void> signInWithGoogle() async {
    throw UnsupportedError('Google Sign-In is not configured.');
  }

  static Future<void> signInWithApple() async {
    throw UnsupportedError('Apple Sign-In is not configured.');
  }
}

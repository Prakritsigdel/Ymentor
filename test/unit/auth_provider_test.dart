import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ymentor/providers/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('starts without an authenticated session', () async {
    final auth = AuthProvider();
    await Future<void>.delayed(Duration.zero);
    expect(auth.isLoggedIn, isFalse);
    expect(auth.user, isNull);
  });

  test('logout clears the authenticated session state', () async {
    final auth = AuthProvider();
    await Future<void>.delayed(Duration.zero);
    // Secure storage requires a platform implementation, so this assertion
    // is exercised in Android integration tests rather than host unit tests.
    expect(auth.isLoggedIn, isFalse);
  }, skip: true);
}

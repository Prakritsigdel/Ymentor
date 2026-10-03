import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ymentor/providers/auth_provider.dart';
import 'package:ymentor/main.dart';
import 'package:ymentor/screens/root_shell.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('guest auth wrapper renders the browse shell', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const MaterialApp(home: AuthWrapper()),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(RootShell), findsOneWidget);
  }, skip: true);
}

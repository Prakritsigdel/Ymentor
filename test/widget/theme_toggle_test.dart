import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ymentor/providers/theme_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('theme controller toggles and persists dark mode', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = ThemeController();
    expect(controller.isDark, isFalse);
    await controller.toggle();
    expect(controller.isDark, isTrue);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('theme_mode'), isTrue);
  });
}

import 'package:flutter/foundation.dart';

/// The default matches the current development Wi-Fi host. For another
/// network, override with:
/// flutter run --dart-define=API_BASE_URL=http://<YOUR_LAN_IP>:3000
/// Android emulators can also use http://10.0.2.2:3000 explicitly.
class ApiConfig {
  static const String port = '3000';

  static String get baseUrl {
    const envValue = String.fromEnvironment('API_BASE_URL');
    if (envValue.isNotEmpty) {
      return envValue.trim();
    }

    if (kIsWeb) {
      return 'http://localhost:$port';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://192.168.0.6:$port';
    }

    return 'http://127.0.0.1:$port';
  }

  static String get apiBaseUrl => '$baseUrl/api';
  static String get uploadsBaseUrl => '$baseUrl/uploads';
}

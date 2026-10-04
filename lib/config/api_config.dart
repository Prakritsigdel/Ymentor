import 'package:flutter/foundation.dart';

class ApiConfig {
  // UPDATE THIS TO YOUR COMPUTER'S CURRENT LOCAL IP ADDRESS
  static const String _localIp = '192.168.0.3';
  static const String port = '3000';

  static String get baseUrl {
    const envValue = String.fromEnvironment('API_BASE_URL');
    if (envValue.isNotEmpty) {
      final trimmed = envValue.trim();
      return trimmed.endsWith('/api')
          ? trimmed.substring(0, trimmed.length - 4)
          : trimmed;
    }

    if (kIsWeb) {
      return 'http://localhost:$port';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://$_localIp:$port';
    }

    return 'http://127.0.0.1:$port';
  }

  static String get apiBaseUrl => '$baseUrl/api';
  static String get healthUrl => '$apiBaseUrl/health';
  static String get uploadsBaseUrl => '$baseUrl/uploads';
}

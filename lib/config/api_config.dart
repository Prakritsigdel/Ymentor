/// Backend runs locally and is reached via:
/// adb reverse tcp:3000 tcp:3000
class ApiConfig {
  static const String baseUrl = 'http://localhost:3000';
  static const String uploadsBaseUrl = '$baseUrl/uploads';
}

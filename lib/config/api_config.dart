/// Override with --dart-define=API_BASE_URL=http://<COMPUTER-LAN-IP>:3000
class ApiConfig {
  static const String hostIp = '192.168.0.4';
  // static const String hostIp = '10.10.9.15';
  static const String port = '3000';
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://$hostIp:$port',
  );
  static const String apiBaseUrl = '$baseUrl/api';
  static const String uploadsBaseUrl = '$baseUrl/uploads';
}

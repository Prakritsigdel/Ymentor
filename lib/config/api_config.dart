/// Centralized backend API configuration.
/// Network: netis_3F66B2 (main Wi-Fi)
///
/// To switch networks: run `ipconfig`, find "Wi-Fi IPv4 Address", update _host.
class ApiConfig {
  // ── Change ONLY this when switching Wi-Fi networks ───────────────────
  static const String _host = '192.168.0.2';
  // ─────────────────────────────────────────────────────────────────────

  static const String baseUrl = 'http://$_host:3000';
  static const String apiBaseUrl = '$baseUrl/api';
  static const String uploadsBaseUrl = '$baseUrl/uploads';
}

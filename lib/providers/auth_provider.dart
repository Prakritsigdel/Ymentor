import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

/// Holds a pending booking selection made while the user was logged out,
/// so we can send them straight back to checkout after login.
class PendingBooking {
  final String mentorId;
  final int durationMinutes;
  final double price;
  final String? slotId;

  PendingBooking({
    required this.mentorId,
    required this.durationMinutes,
    required this.price,
    this.slotId,
  });

  Map<String, dynamic> toJson() => {
        'mentorId': mentorId,
        'durationMinutes': durationMinutes,
        'price': price,
        'slotId': slotId,
      };

  factory PendingBooking.fromJson(Map<String, dynamic> json) => PendingBooking(
        mentorId: json['mentorId']?.toString() ?? '',
        durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 30,
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        slotId: json['slotId']?.toString(),
      );
}

class AuthProvider extends ChangeNotifier {
  AppUser? _user;
  String? _token;
  bool _isLoading = true;
  PendingBooking? _pendingBooking;

  AppUser? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null && _token != null && _token!.isNotEmpty;
  PendingBooking? get pendingBooking => _pendingBooking;

  // Role & status conveniences
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isMentor => _user?.isMentor ?? false;
  bool get isMentee => _user?.isMentee ?? false;
  bool get isOnboarded => _user?.isOnboarded ?? false;
  bool get isSuspended => _user?.isSuspended ?? false;

  static const _kToken = 'ymentor_token';
  static const _kUser = 'ymentor_user';
  static const _kPending = 'ymentor_pending_booking';
  static const _secureStorage = FlutterSecureStorage();

  AuthProvider() {
    // Configure API service 401 interceptor callback
    ApiService.onUnauthorized = () {
      logout();
    };
    _restore();
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var token = await _secureStorage.read(key: _kToken);
      var userJson = await _secureStorage.read(key: _kUser);

      final legacyToken = prefs.getString(_kToken);
      final legacyUserJson = prefs.getString(_kUser);
      if (token == null && legacyToken != null) {
        token = legacyToken;
        await _secureStorage.write(key: _kToken, value: legacyToken);
      }
      if (userJson == null && legacyUserJson != null) {
        userJson = legacyUserJson;
        await _secureStorage.write(key: _kUser, value: legacyUserJson);
      }
      await prefs.remove(_kToken);
      await prefs.remove(_kUser);

      if (token != null && userJson != null) {
        _token = token;
        ApiService.authToken = token;
        final decoded = jsonDecode(userJson);
        if (decoded is Map<String, dynamic>) {
          _user = AppUser.fromJson(decoded);
        }
      }

      final pendingJson = prefs.getString(_kPending);
      if (pendingJson != null) {
        _pendingBooking = PendingBooking.fromJson(jsonDecode(pendingJson));
      }
    } catch (e) {
      debugPrint('AuthProvider restore error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _persist() async {
    if (_token != null && _user != null) {
      ApiService.authToken = _token;
      await _secureStorage.write(key: _kToken, value: _token!);
      await _secureStorage.write(
        key: _kUser,
        value: jsonEncode(_user!.toJson()),
      );
    } else {
      ApiService.authToken = null;
      await _secureStorage.delete(key: _kToken);
      await _secureStorage.delete(key: _kUser);
    }
  }

  Future<void> login(String email, String password) async {
    final data = await ApiService.login(email: email, password: password);
    _token = data['token']?.toString();
    ApiService.authToken = _token;

    final userMap = data['user'] is Map ? data['user'] as Map<String, dynamic> : data;
    _user = AppUser.fromJson(userMap);

    await _persist();
    notifyListeners();
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? faculty,
    List<String> skillsOrInterests = const [],
    String? title,
    String? bio,
    double? hourlyRate,
  }) async {
    final data = await ApiService.register(
      name: name,
      email: email,
      password: password,
      role: role,
      faculty: faculty,
      skillsOrInterests: skillsOrInterests,
      title: title,
      bio: bio,
      hourlyRate: hourlyRate,
    );
    _token = data['token']?.toString();
    ApiService.authToken = _token;

    final userMap = data['user'] is Map ? data['user'] as Map<String, dynamic> : data;
    _user = AppUser.fromJson(userMap);

    await _persist();
    notifyListeners();
  }

  Future<void> completeOnboarding({
    required String faculty,
    required List<String> skillsOrInterests,
    String? title,
    String? bio,
    double? hourlyRate,
  }) async {
    final updatedUser = await ApiService.completeOnboarding(
      faculty: faculty,
      skillsOrInterests: skillsOrInterests,
      title: title,
      bio: bio,
      hourlyRate: hourlyRate,
    );
    _user = updatedUser;
    await _persist();
    notifyListeners();
  }

  Future<void> updateProfile({
    String? name,
    String? bio,
    String? title,
    String? faculty,
    List<String>? skillsOrInterests,
    double? hourlyRate,
    PricingTiers? pricingTiers,
    String? meetingUrl,
  }) async {
    final updated = await ApiService.updateProfile(
      name: name,
      bio: bio,
      title: title,
      faculty: faculty,
      skillsOrInterests: skillsOrInterests,
      hourlyRate: hourlyRate,
      pricingTiers: pricingTiers,
      meetingUrl: meetingUrl,
    );
    _user = updated;
    await _persist();
    notifyListeners();
  }

  Future<void> refreshUser() async {
    if (_user == null || _token == null) return;
    try {
      final me = await ApiService.getMe();
      _user = me;
      await _persist();
      notifyListeners();
    } catch (_) {
      // Non-fatal: keep cached user if network fails.
    }
  }

  Future<void> logout() async {
    _user = null;
    _token = null;
    ApiService.authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await _secureStorage.delete(key: _kToken);
    await _secureStorage.delete(key: _kUser);
    await prefs.remove(_kToken);
    await prefs.remove(_kUser);
    notifyListeners();
  }

  Future<void> savePendingBooking(PendingBooking booking) async {
    _pendingBooking = booking;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPending, jsonEncode(booking.toJson()));
    notifyListeners();
  }

  Future<void> clearPendingBooking() async {
    _pendingBooking = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPending);
    notifyListeners();
  }
}

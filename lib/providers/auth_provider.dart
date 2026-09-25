import 'dart:convert';
import 'package:flutter/foundation.dart';
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
        mentorId: json['mentorId'],
        durationMinutes: json['durationMinutes'],
        price: (json['price'] as num).toDouble(),
        slotId: json['slotId'],
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
  bool get isLoggedIn => _user != null;
  PendingBooking? get pendingBooking => _pendingBooking;

  static const _kToken = 'ymentor_token';
  static const _kUser = 'ymentor_user';
  static const _kPending = 'ymentor_pending_booking';

  AuthProvider() {
    _restore();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_kToken);
    final userJson = prefs.getString(_kUser);
    if (token != null && userJson != null) {
      _token = token;
      _user = AppUser.fromJson(jsonDecode(userJson));
    }
    final pendingJson = prefs.getString(_kPending);
    if (pendingJson != null) {
      _pendingBooking = PendingBooking.fromJson(jsonDecode(pendingJson));
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (_token != null && _user != null) {
      await prefs.setString(_kToken, _token!);
      await prefs.setString(_kUser, jsonEncode({
            '_id': _user!.id,
            'name': _user!.name,
            'email': _user!.email,
            'role': _user!.role,
            'walletBalance': _user!.walletBalance,
          }));
    }
  }

  Future<void> login(String email, String password) async {
    final data = await ApiService.login(email: email, password: password);
    _token = data['token'];
    _user = AppUser.fromJson(data['user']);
    await _persist();
    notifyListeners();
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final data = await ApiService.register(name: name, email: email, password: password, role: role);
    _token = data['token'];
    _user = AppUser.fromJson(data['user']);
    await _persist();
    notifyListeners();
  }

  Future<void> refreshUser() async {
    if (_user == null) return;
    try {
      final mentors = await ApiService.getMentors();
      final match = mentors.where((m) => m.id == _user!.id);
      if (match.isNotEmpty) {
        _user = match.first;
        notifyListeners();
      }
    } catch (_) {
      // Non-fatal: keep cached user if refresh fails.
    }
  }

  Future<void> logout() async {
    _user = null;
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kUser);
    notifyListeners();
  }

  Future<void> setPendingBooking(PendingBooking booking) async {
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

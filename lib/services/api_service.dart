import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user_model.dart';
import '../models/booking_model.dart';
import '../models/workspace_model.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);
  @override
  String toString() => message;
}

class ApiService {
  static final Uri _base = Uri.parse(ApiConfig.baseUrl);

  /// Global hook called when any request returns 401 Unauthorized
  static void Function()? onUnauthorized;

  /// Cached active auth token attached to headers
  static String? authToken;

  static Map<String, String> _headers([bool isJson = true]) {
    final map = <String, String>{};
    if (isJson) map['Content-Type'] = 'application/json';
    if (authToken != null && authToken!.isNotEmpty) {
      map['Authorization'] = 'Bearer $authToken';
    }
    return map;
  }

  static Map<String, dynamic> _decode(http.Response res) {
    if (res.statusCode == 401) {
      onUnauthorized?.call();
      final body = _tryParseJson(res.body);
      throw ApiException(
        body is Map ? (body['error'] ?? 'Unauthorized. Please log in again.') : 'Unauthorized.',
        401,
      );
    }

    final body = _tryParseJson(res.body);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body is Map<String, dynamic> ? body : {'data': body};
    }

    final errorMsg = body is Map
        ? (body['error'] ?? body['message'] ?? 'Request failed with code ${res.statusCode}')
        : 'Request failed with code ${res.statusCode}';
    throw ApiException(errorMsg.toString(), res.statusCode);
  }

  static List<dynamic> _decodeList(http.Response res) {
    if (res.statusCode == 401) {
      onUnauthorized?.call();
      throw ApiException('Unauthorized. Please log in again.', 401);
    }

    final body = _tryParseJson(res.body);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body is List ? body : [];
    }

    final errorMsg = body is Map
        ? (body['error'] ?? body['message'] ?? 'Request failed with code ${res.statusCode}')
        : 'Request failed with code ${res.statusCode}';
    throw ApiException(errorMsg.toString(), res.statusCode);
  }

  static dynamic _tryParseJson(String source) {
    if (source.trim().isEmpty) return {};
    try {
      return jsonDecode(source);
    } catch (_) {
      return {'raw': source};
    }
  }

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on SocketException {
      throw ApiException('Cannot reach Ymentor server at ${ApiConfig.baseUrl}. Is the backend running?');
    } on http.ClientException {
      throw ApiException('Network connection failed. Please check your network connection to ${ApiConfig.baseUrl}.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  // ---------------- AUTHENTICATION ----------------

  static Future<Map<String, dynamic>> register({
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
    return _guard(() async {
      final res = await http.post(
        _base.replace(path: '/api/auth/register'),
        headers: _headers(),
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'role': role,
          'faculty': faculty ?? '',
          'skillsOrInterests': skillsOrInterests,
          'title': title ?? '',
          'bio': bio ?? '',
          if (hourlyRate != null) 'hourlyRate': hourlyRate,
        }),
      );
      final data = _decode(res);
      if (data['token'] != null) {
        authToken = data['token'].toString();
      }
      return data;
    });
  }

  static Future<Map<String, dynamic>> login({required String email, required String password}) async {
    return _guard(() async {
      final res = await http.post(
        _base.replace(path: '/api/auth/login'),
        headers: _headers(),
        body: jsonEncode({'email': email, 'password': password}),
      );
      final data = _decode(res);
      if (data['token'] != null) {
        authToken = data['token'].toString();
      }
      return data;
    });
  }

  static Future<AppUser> getMe() async {
    return _guard(() async {
      final res = await http.get(
        _base.replace(path: '/api/auth/me'),
        headers: _headers(),
      );
      final data = _decode(res);
      final userMap = data['user'] is Map ? data['user'] as Map<String, dynamic> : data;
      return AppUser.fromJson(userMap);
    });
  }

  // ---------------- USER ONBOARDING & PROFILE ----------------

  static Future<AppUser> completeOnboarding({
    required String faculty,
    required List<String> skillsOrInterests,
    String? title,
    String? bio,
    double? hourlyRate,
  }) async {
    return _guard(() async {
      final res = await http.put(
        _base.replace(path: '/api/users/onboarding'),
        headers: _headers(),
        body: jsonEncode({
          'faculty': faculty,
          'skillsOrInterests': skillsOrInterests,
          'title': title ?? '',
          'bio': bio ?? '',
          if (hourlyRate != null) 'hourlyRate': hourlyRate,
        }),
      );
      final data = _decode(res);
      final userMap = data['user'] is Map ? data['user'] as Map<String, dynamic> : data;
      return AppUser.fromJson(userMap);
    });
  }

  static Future<AppUser> updateProfile({
    String? name,
    String? bio,
    String? title,
    String? faculty,
    List<String>? skillsOrInterests,
    double? hourlyRate,
    PricingTiers? pricingTiers,
    String? meetingUrl,
  }) async {
    return _guard(() async {
      final res = await http.put(
        _base.replace(path: '/api/users/profile'),
        headers: _headers(),
        body: jsonEncode({
          if (name != null) 'name': name,
          if (bio != null) 'bio': bio,
          if (title != null) 'title': title,
          if (faculty != null) 'faculty': faculty,
          if (skillsOrInterests != null) 'skillsOrInterests': skillsOrInterests,
          if (hourlyRate != null) 'hourlyRate': hourlyRate,
          if (pricingTiers != null) 'pricingTiers': pricingTiers.toJson(),
          if (meetingUrl != null) 'meetingUrl': meetingUrl,
        }),
      );
      final data = _decode(res);
      final userMap = data['user'] is Map ? data['user'] as Map<String, dynamic> : data;
      return AppUser.fromJson(userMap);
    });
  }

  // ---------------- MENTORS DISCOVERY ----------------

  static Future<List<AppUser>> getMentors({String? interests, String? skill, String? q}) async {
    return _guard(() async {
      final params = <String, String>{};
      if (interests != null && interests.isNotEmpty) params['interests'] = interests;
      if (skill != null && skill.isNotEmpty) params['skill'] = skill;
      if (q != null && q.isNotEmpty) params['q'] = q;

      final uri = _base.replace(path: '/api/users/mentors', queryParameters: params.isEmpty ? null : params);
      final res = await http.get(uri, headers: _headers());
      return _decodeList(res).map((e) => AppUser.fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  static Future<List<AppUser>> getLeaderboard({int limit = 10}) async {
    return _guard(() async {
      final uri = _base.replace(path: '/api/mentors/leaderboard', queryParameters: {'limit': '$limit'});
      final res = await http.get(uri, headers: _headers());
      return _decodeList(res).map((e) => AppUser.fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  static Future<Map<String, dynamic>> getMentorProfile(String mentorId) async {
    return _guard(() async {
      final res = await http.get(_base.replace(path: '/api/mentors/$mentorId'), headers: _headers());
      return _decode(res);
    });
  }

  static Future<AppUser> updateMentorConfig(
    String mentorId, {
    PricingTiers? pricingTiers,
    String? meetingUrl,
  }) async {
    return _guard(() async {
      final res = await http.patch(
        _base.replace(path: '/api/mentors/$mentorId/config'),
        headers: _headers(),
        body: jsonEncode({
          if (pricingTiers != null) 'pricingTiers': pricingTiers.toJson(),
          if (meetingUrl != null) 'meetingUrl': meetingUrl,
        }),
      );
      return AppUser.fromJson(_decode(res));
    });
  }

  // ---------------- BOOKINGS & ESCROW ----------------

  static Future<Map<String, dynamic>> checkout({
    required String menteeId,
    required String mentorId,
    required int durationMinutes,
    required double price,
    DateTime? scheduledTime,
  }) async {
    return _guard(() async {
      final res = await http.post(
        _base.replace(path: '/api/bookings/checkout'),
        headers: _headers(),
        body: jsonEncode({
          'menteeId': menteeId,
          'mentorId': mentorId,
          'durationMinutes': durationMinutes,
          'price': price,
          'scheduledTime': (scheduledTime ?? DateTime.now().add(const Duration(days: 1))).toIso8601String(),
        }),
      );
      return _decode(res);
    });
  }

  static Future<Map<String, dynamic>> completeBooking(
    String bookingId, {
    double rating = 5.0,
    String reviewNote = 'Outstanding mentorship session!',
  }) async {
    return _guard(() async {
      final res = await http.put(
        _base.replace(path: '/api/bookings/$bookingId/complete'),
        headers: _headers(),
        body: jsonEncode({'rating': rating, 'reviewNote': reviewNote}),
      );
      return _decode(res);
    });
  }

  static Future<List<Booking>> getUserBookings(String userId) async {
    return _guard(() async {
      final res = await http.get(
        _base.replace(path: '/api/bookings/user/$userId'),
        headers: _headers(),
      );
      return _decodeList(res).map((e) => Booking.fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  // ---------------- WORKSPACES & PDF NOTES ----------------

  static Future<List<Workspace>> getUserWorkspaces(String userId) async {
    return _guard(() async {
      final res = await http.get(
        _base.replace(path: '/api/workspaces/user/$userId'),
        headers: _headers(),
      );
      return _decodeList(res).map((e) => Workspace.fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  static Future<List<Note>> getWorkspaceNotes(String workspaceId) async {
    return _guard(() async {
      final res = await http.get(
        _base.replace(path: '/api/workspaces/$workspaceId/notes'),
        headers: _headers(),
      );
      return _decodeList(res).map((e) => Note.fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  static Future<Note> uploadNote({
    required String workspaceId,
    required String uploadedBy,
    required String title,
    String? description,
    String? dueDate,
    File? pdfFile,
  }) async {
    return _guard(() async {
      final uri = _base.replace(path: '/api/workspaces/$workspaceId/notes');
      final request = http.MultipartRequest('POST', uri);
      if (authToken != null && authToken!.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $authToken';
      }
      request.fields['title'] = title;
      request.fields['uploadedBy'] = uploadedBy;
      if (description != null) request.fields['description'] = description;
      if (dueDate != null) request.fields['dueDate'] = dueDate;
      if (pdfFile != null) {
        request.files.add(await http.MultipartFile.fromPath('pdf', pdfFile.path));
      }
      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);
      return Note.fromJson(_decode(res));
    });
  }

  static Future<NoteComment> postComment({
    required String noteId,
    required String senderId,
    required String senderName,
    required String message,
  }) async {
    return _guard(() async {
      final res = await http.post(
        _base.replace(path: '/api/workspaces/notes/$noteId/comments'),
        headers: _headers(),
        body: jsonEncode({'senderId': senderId, 'senderName': senderName, 'message': message}),
      );
      return NoteComment.fromJson(_decode(res));
    });
  }

  static Future<Note> toggleNote(String noteId) async {
    return _guard(() async {
      final res = await http.patch(
        _base.replace(path: '/api/workspaces/notes/$noteId/toggle'),
        headers: _headers(),
      );
      return Note.fromJson(_decode(res));
    });
  }

  // ---------------- ADMIN ENDPOINTS ----------------

  static Future<List<AppUser>> getPendingMentors() async {
    return _guard(() async {
      final res = await http.get(_base.replace(path: '/api/admin/pending-mentors'), headers: _headers());
      return _decodeList(res).map((e) => AppUser.fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  static Future<AppUser> approveMentor(String mentorId) async {
    return _guard(() async {
      final res = await http.put(_base.replace(path: '/api/admin/approve-mentor/$mentorId'), headers: _headers());
      final data = _decode(res);
      final userMap = data['user'] is Map ? data['user'] as Map<String, dynamic> : data;
      return AppUser.fromJson(userMap);
    });
  }

  static Future<AppUser> toggleUserStatus(String userId, {String? status}) async {
    return _guard(() async {
      final res = await http.put(
        _base.replace(path: '/api/admin/toggle-user-status/$userId'),
        headers: _headers(),
        body: status != null ? jsonEncode({'status': status}) : null,
      );
      final data = _decode(res);
      final userMap = data['user'] is Map ? data['user'] as Map<String, dynamic> : data;
      return AppUser.fromJson(userMap);
    });
  }

  static Future<Map<String, dynamic>> getEscrowTransactions() async {
    return _guard(() async {
      final res = await http.get(_base.replace(path: '/api/admin/escrow-transactions'), headers: _headers());
      return _decode(res);
    });
  }

  static Future<Map<String, dynamic>> releaseEscrowAdmin(String bookingId) async {
    return _guard(() async {
      final res = await http.put(_base.replace(path: '/api/admin/release-escrow/$bookingId'), headers: _headers());
      return _decode(res);
    });
  }

  static Future<List<dynamic>> getAuditLogs() async {
    return _guard(() async {
      final res = await http.get(_base.replace(path: '/api/admin/audit-logs'), headers: _headers());
      return _decodeList(res);
    });
  }

  static Future<List<AppUser>> getAllUsers() async {
    return _guard(() async {
      final res = await http.get(_base.replace(path: '/api/admin/users'), headers: _headers());
      return _decodeList(res).map((e) => AppUser.fromJson(e as Map<String, dynamic>)).toList();
    });
  }
}

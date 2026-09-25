import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user_model.dart';
import '../models/booking_model.dart';
import '../models/workspace_model.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  static final Uri _base = Uri.parse(ApiConfig.baseUrl);

  static Map<String, dynamic> _decode(http.Response res) {
    final body = res.body.isEmpty ? '{}' : jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body is Map<String, dynamic> ? body : {'data': body};
    }
    throw ApiException(body is Map ? (body['error'] ?? 'Request failed') : 'Request failed');
  }

  static List _decodeList(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final body = jsonDecode(res.body);
      return body is List ? body : [];
    }
    final body = res.body.isEmpty ? {} : jsonDecode(res.body);
    throw ApiException(body is Map ? (body['error'] ?? 'Request failed') : 'Request failed');
  }

  // ---------------- AUTH ----------------

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String role,
    List<String> skills = const [],
  }) async {
    final res = await http.post(
      _base.replace(path: '/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password, 'role': role, 'skills': skills}),
    );
    return _decode(res);
  }

  static Future<Map<String, dynamic>> login({required String email, required String password}) async {
    final res = await http.post(
      _base.replace(path: '/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _decode(res);
  }

  // ---------------- MENTORS ----------------

  static Future<List<AppUser>> getMentors({String? skill, String? q}) async {
    final params = <String, String>{};
    if (skill != null && skill.isNotEmpty) params['skill'] = skill;
    if (q != null && q.isNotEmpty) params['q'] = q;
    final uri = _base.replace(path: '/api/mentors', queryParameters: params.isEmpty ? null : params);
    final res = await http.get(uri);
    return _decodeList(res).map((e) => AppUser.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<List<AppUser>> getLeaderboard({int limit = 50}) async {
    final uri = _base.replace(path: '/api/mentors/leaderboard', queryParameters: {'limit': '$limit'});
    final res = await http.get(uri);
    return _decodeList(res).map((e) => AppUser.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<Map<String, dynamic>> getMentorProfile(String mentorId) async {
    final res = await http.get(_base.replace(path: '/api/mentors/$mentorId'));
    return _decode(res);
  }

  static Future<AppUser> updateMentorConfig(String mentorId,
      {PricingTiers? pricingTiers, String? meetingUrl}) async {
    final res = await http.patch(
      _base.replace(path: '/api/mentors/$mentorId/config'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        if (pricingTiers != null) 'pricingTiers': pricingTiers.toJson(),
        if (meetingUrl != null) 'meetingUrl': meetingUrl,
      }),
    );
    return AppUser.fromJson(_decode(res));
  }

  // ---------------- BOOKINGS / ESCROW ----------------

  static Future<Map<String, dynamic>> checkout({
    required String menteeId,
    required String mentorId,
    required int durationMinutes,
    required double price,
    DateTime? scheduledTime,
  }) async {
    final res = await http.post(
      _base.replace(path: '/api/bookings/checkout'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'menteeId': menteeId,
        'mentorId': mentorId,
        'durationMinutes': durationMinutes,
        'price': price,
        'scheduledTime': (scheduledTime ?? DateTime.now().add(const Duration(days: 1))).toIso8601String(),
      }),
    );
    return _decode(res);
  }

  static Future<Map<String, dynamic>> completeBooking(String bookingId,
      {double rating = 5.0, String reviewNote = 'Outstanding mentorship session!'}) async {
    final res = await http.put(
      _base.replace(path: '/api/bookings/$bookingId/complete'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'rating': rating, 'reviewNote': reviewNote}),
    );
    return _decode(res);
  }

  static Future<List<Booking>> getUserBookings(String userId) async {
    final res = await http.get(_base.replace(path: '/api/bookings/user/$userId'));
    return _decodeList(res).map((e) => Booking.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ---------------- WORKSPACES / NOTES ----------------

  static Future<List<Workspace>> getUserWorkspaces(String userId) async {
    final res = await http.get(_base.replace(path: '/api/workspaces/user/$userId'));
    return _decodeList(res).map((e) => Workspace.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<List<Note>> getWorkspaceNotes(String workspaceId) async {
    final res = await http.get(_base.replace(path: '/api/workspaces/$workspaceId/notes'));
    return _decodeList(res).map((e) => Note.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<Note> uploadNote({
    required String workspaceId,
    required String uploadedBy,
    required String title,
    String? description,
    String? dueDate,
    File? pdfFile,
  }) async {
    final uri = _base.replace(path: '/api/workspaces/$workspaceId/notes');
    final request = http.MultipartRequest('POST', uri);
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
  }

  static Future<NoteComment> postComment({
    required String noteId,
    required String senderId,
    required String senderName,
    required String message,
  }) async {
    final res = await http.post(
      _base.replace(path: '/api/workspaces/notes/$noteId/comments'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'senderId': senderId, 'senderName': senderName, 'message': message}),
    );
    return NoteComment.fromJson(_decode(res));
  }

  static Future<Note> toggleNote(String noteId) async {
    final res = await http.patch(_base.replace(path: '/api/workspaces/notes/$noteId/toggle'));
    return Note.fromJson(_decode(res));
  }
}

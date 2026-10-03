import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
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
  static final http.Client _client = http.Client();
  static const Duration _requestTimeout = Duration(seconds: 30);

  /// Global hook called when any request returns 401 Unauthorized
  static void Function()? onUnauthorized;

  /// Cached active auth token attached to headers
  static String? authToken;

  static Future<http.Response> _send(
    Uri uri,
    http.BaseRequest request,
  ) async {
    try {
      final streamed = await _client.send(request).timeout(_requestTimeout);
      return await http.Response.fromStream(streamed).timeout(_requestTimeout);
    } on SocketException catch (error, stackTrace) {
      debugPrint('API request failed: $uri\n$error\n$stackTrace');
      rethrow;
    } on TimeoutException catch (error, stackTrace) {
      debugPrint('API request timed out: $uri\n$error\n$stackTrace');
      rethrow;
    }
  }

  static Future<http.Response> _get(
    Uri uri, {
    Map<String, String>? headers,
  }) {
    final request = http.Request('GET', uri)
      ..headers.addAll(headers ?? const {});
    return _send(uri, request);
  }

  static Future<http.Response> _post(
    Uri uri, {
    Map<String, String>? headers,
    String? body,
  }) {
    final request = http.Request('POST', uri)
      ..headers.addAll(headers ?? const {})
      ..body = body ?? '';
    return _send(uri, request);
  }

  static Future<http.Response> _put(
    Uri uri, {
    Map<String, String>? headers,
    String? body,
  }) {
    final request = http.Request('PUT', uri)
      ..headers.addAll(headers ?? const {})
      ..body = body ?? '';
    return _send(uri, request);
  }

  static Future<http.Response> _patch(
    Uri uri, {
    Map<String, String>? headers,
    String? body,
  }) {
    final request = http.Request('PATCH', uri)
      ..headers.addAll(headers ?? const {})
      ..body = body ?? '';
    return _send(uri, request);
  }

  static Future<http.Response> _sendMultipart(
    http.MultipartRequest request,
  ) {
    request.headers.addAll(_buildHeaders(isMultipart: true));
    return _send(request.url, request);
  }

  static Map<String, String> _buildHeaders({bool isMultipart = false}) {
    final map = <String, String>{};
    if (!isMultipart) map['Content-Type'] = 'application/json';
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
        body is Map
            ? (body['error'] ?? 'Unauthorized. Please log in again.')
            : 'Unauthorized.',
        401,
      );
    }

    final body = _tryParseJson(res.body);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body is Map<String, dynamic> ? body : {'data': body};
    }

    final errorMsg = body is Map
        ? (body['error'] ??
            body['message'] ??
            'Request failed with code ${res.statusCode}')
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
        ? (body['error'] ??
            body['message'] ??
            'Request failed with code ${res.statusCode}')
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
      debugPrint('API connection failed at ${ApiConfig.apiBaseUrl}');
      throw ApiException(
        'Cannot reach the Ymentor server at ${ApiConfig.apiBaseUrl}. '
        'Check the server address, that both devices are on the same Wi-Fi, '
        'and that the computer firewall allows port 3000.',
      );
    } on TimeoutException {
      throw ApiException(
        'The Ymentor server request timed out at ${ApiConfig.apiBaseUrl}. '
        'Check the server and Wi-Fi connection.',
      );
    } on http.ClientException {
      throw ApiException(
        'Network connection to ${ApiConfig.apiBaseUrl} failed. '
        'Check that the server is running and the device can reach the computer.',
      );
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
      final res = await _post(
        _base.replace(path: '/api/auth/register'),
        headers: _buildHeaders(),
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

  static Future<Map<String, dynamic>> login(
      {required String email, required String password}) async {
    return _guard(() async {
      final res = await _post(
        _base.replace(path: '/api/auth/login'),
        headers: _buildHeaders(),
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
      final res = await _get(
        _base.replace(path: '/api/auth/me'),
        headers: _buildHeaders(),
      );
      final data = _decode(res);
      final userMap =
          data['user'] is Map ? data['user'] as Map<String, dynamic> : data;
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
      final res = await _put(
        _base.replace(path: '/api/users/onboarding'),
        headers: _buildHeaders(),
        body: jsonEncode({
          'faculty': faculty,
          'skillsOrInterests': skillsOrInterests,
          'title': title ?? '',
          'bio': bio ?? '',
          if (hourlyRate != null) 'hourlyRate': hourlyRate,
        }),
      );
      final data = _decode(res);
      final userMap =
          data['user'] is Map ? data['user'] as Map<String, dynamic> : data;
      return AppUser.fromJson(userMap);
    });
  }

  static Future<AppUser> completeMenteeOnboarding({
    required String academicStatus,
    required String fieldOfInterest,
    required String primaryGoal,
    required List<String> targetSkills,
    required String competencyLevel,
    required String preferredMode,
    required String mentorStyle,
    required double targetBudget,
    required double weeklyCommitmentHours,
  }) async {
    return _guard(() async {
      final response = await _put(
        _base.replace(path: '/api/users/onboarding/mentee'),
        headers: _buildHeaders(),
        body: jsonEncode({
          'academicStatus': academicStatus,
          'fieldOfInterest': fieldOfInterest,
          'primaryGoal': primaryGoal,
          'targetSkills': targetSkills,
          'competencyLevel': competencyLevel,
          'preferredMode': preferredMode,
          'mentorStyle': mentorStyle,
          'targetBudget': targetBudget,
          'weeklyCommitmentHours': weeklyCommitmentHours,
        }),
      );
      final data = _decode(response);
      return AppUser.fromJson(data['user'] as Map<String, dynamic>);
    });
  }

  static Future<AppUser> submitMentorOnboarding({
    required Map<String, String> fields,
    Map<String, File> files = const {},
  }) async {
    return _guard(() async {
      final request = http.MultipartRequest(
        'POST',
        _base.replace(path: '/api/auth/onboard/mentor'),
      );
      request.fields.addAll(fields);
      for (final entry in files.entries) {
        request.files.add(
            await http.MultipartFile.fromPath(entry.key, entry.value.path));
      }
      final data = _decode(await _sendMultipart(request));
      return AppUser.fromJson(data['user'] as Map<String, dynamic>);
    });
  }

  static Future<AppUser> updateProfile({
    String? name,
    String? bio,
    String? title,
    String? faculty,
    List<String>? skillsOrInterests,
    double? hourlyRate,
    double? monthlyRate,
    int? maxMentees,
    PricingTiers? pricingTiers,
    String? meetingUrl,
  }) async {
    return _guard(() async {
      final res = await _put(
        _base.replace(path: '/api/users/profile'),
        headers: _buildHeaders(),
        body: jsonEncode({
          if (name != null) 'name': name,
          if (bio != null) 'bio': bio,
          if (title != null) 'title': title,
          if (faculty != null) 'faculty': faculty,
          if (skillsOrInterests != null) 'skillsOrInterests': skillsOrInterests,
          if (hourlyRate != null) 'hourlyRate': hourlyRate,
          if (monthlyRate != null) 'monthlyRate': monthlyRate,
          if (maxMentees != null) 'maxMentees': maxMentees,
          if (pricingTiers != null) 'pricingTiers': pricingTiers.toJson(),
          if (meetingUrl != null) 'meetingUrl': meetingUrl,
        }),
      );
      final data = _decode(res);
      final userMap =
          data['user'] is Map ? data['user'] as Map<String, dynamic> : data;
      return AppUser.fromJson(userMap);
    });
  }

  static Future<AppUser> updateMentorProfile({
    required double hourlyRateNpr,
    required double monthlyRateNpr,
    required String meetingUrl,
  }) async {
    return _guard(() async {
      final response = await _patch(
        _base.replace(path: '/api/v1/mentors/profile'),
        headers: _buildHeaders(),
        body: jsonEncode({
          'hourlyRateNPR': hourlyRateNpr,
          'monthlyRateNPR': monthlyRateNpr,
          'meetingUrl': meetingUrl,
        }),
      );
      final data = _decode(response);
      final userMap =
          data['user'] is Map ? data['user'] as Map<String, dynamic> : data;
      return AppUser.fromJson(userMap);
    });
  }

  // ---------------- MENTORS DISCOVERY ----------------

  static Future<List<AppUser>> getMentors(
      {String? interests, String? skill, String? q}) async {
    return _guard(() async {
      final params = <String, String>{};
      if (interests != null && interests.isNotEmpty)
        params['interests'] = interests;
      if (skill != null && skill.isNotEmpty) params['skill'] = skill;
      if (q != null && q.isNotEmpty) params['q'] = q;

      final uri = _base.replace(
          path: '/api/users/mentors',
          queryParameters: params.isEmpty ? null : params);
      final res = await _get(uri, headers: _buildHeaders());
      return _decodeList(res)
          .map((e) => AppUser.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  static Future<List<AppUser>> getLeaderboard({int limit = 10}) async {
    return _guard(() async {
      final uri = _base.replace(
          path: '/api/mentors/leaderboard',
          queryParameters: {'limit': '$limit'});
      final res = await _get(uri, headers: _buildHeaders());
      return _decodeList(res)
          .map((e) => AppUser.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  static Future<Map<String, dynamic>> getMentorProfile(String mentorId) async {
    return _guard(() async {
      final res = await _get(_base.replace(path: '/api/mentors/$mentorId'),
          headers: _buildHeaders());
      return _decode(res);
    });
  }

  static Future<AppUser> updateMentorConfig(
    String mentorId, {
    PricingTiers? pricingTiers,
    String? meetingUrl,
  }) async {
    return _guard(() async {
      final res = await _patch(
        _base.replace(path: '/api/mentors/$mentorId/config'),
        headers: _buildHeaders(),
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
    double? basePrice,
    double? durationInHours,
    DateTime? scheduledTime,
  }) async {
    return _guard(() async {
      final actualPrice = basePrice ?? price;
      final res = await _post(
        _base.replace(path: '/api/bookings/checkout'),
        headers: _buildHeaders(),
        body: jsonEncode({
          'menteeId': menteeId,
          'mentorId': mentorId,
          'durationMinutes': durationMinutes,
          'durationInHours': durationInHours ?? (durationMinutes / 60.0),
          'basePrice': actualPrice,
          'price': actualPrice,
          'scheduledTime':
              (scheduledTime ?? DateTime.now().add(const Duration(days: 1)))
                  .toIso8601String(),
        }),
      );
      return _decode(res);
    });
  }

  static Future<Map<String, dynamic>> checkoutMonthly(String mentorId) async {
    return _guard(() async {
      final response = await _post(
        _base.replace(path: '/api/bookings/monthly'),
        headers: _buildHeaders(),
        body: jsonEncode({'mentorId': mentorId}),
      );
      return _decode(response);
    });
  }

  static Future<Map<String, dynamic>> getPlatformFee(double amount) async {
    return _guard(() async {
      final response = await _get(
        _base.replace(
          path: '/api/platform/fees',
          queryParameters: {'amount': amount.toStringAsFixed(2)},
        ),
      );
      return _decode(response);
    });
  }

  static Future<List<dynamic>> getChatMessages(String conversationId,
      {DateTime? after}) async {
    return _guard(() async {
      final response = await _get(
        _base.replace(
          path: '/api/v1/chat/$conversationId',
          queryParameters:
              after == null ? null : {'after': after.toUtc().toIso8601String()},
        ),
        headers: _buildHeaders(),
      );
      return _decodeList(response);
    });
  }

  static Future<Map<String, dynamic>> sendChatMessage({
    required String conversationId,
    String text = '',
    File? pdf,
    String sessionType = 'MONTHLY',
  }) async {
    return _guard(() async {
      final request = http.MultipartRequest(
          'POST', _base.replace(path: '/api/v1/chat/send'));
      request.fields['conversationId'] = conversationId;
      request.fields['text'] = text;
      request.fields['sessionType'] = sessionType;
      if (pdf != null)
        request.files.add(await http.MultipartFile.fromPath('pdf', pdf.path));
      return _decode(await _sendMultipart(request));
    });
  }

  static Future<dynamic> adminGet(String path) async {
    return _guard(() async => _decode(await _get(
        _base.replace(path: '/api/admin/$path'),
        headers: _buildHeaders())));
  }

  static Future<dynamic> adminPut(
      String path, Map<String, dynamic> body) async {
    return _guard(() async => _decode(await _put(
          _base.replace(path: '/api/admin/$path'),
          headers: _buildHeaders(),
          body: jsonEncode(body),
        )));
  }

  static Future<dynamic> adminPost(
      String path, Map<String, dynamic> body) async {
    return _guard(() async => _decode(await _post(
          _base.replace(path: '/api/admin/$path'),
          headers: _buildHeaders(),
          body: jsonEncode(body),
        )));
  }

  static Future<Map<String, dynamic>> completeBooking(
    String bookingId, {
    double rating = 5.0,
    String reviewNote = 'Outstanding mentorship session!',
  }) async {
    return _guard(() async {
      final res = await _put(
        _base.replace(path: '/api/bookings/$bookingId/complete'),
        headers: _buildHeaders(),
        body: jsonEncode({'rating': rating, 'reviewNote': reviewNote}),
      );
      return _decode(res);
    });
  }

  static Future<List<Booking>> getUserBookings(String userId) async {
    return _guard(() async {
      final res = await _get(
        _base.replace(path: '/api/bookings/user/$userId'),
        headers: _buildHeaders(),
      );
      return _decodeList(res)
          .map((e) => Booking.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  static Future<Map<String, dynamic>> getRtcToken(String sessionId) async {
    return _guard(() async {
      final res = await _post(
        _base.replace(path: '/api/v1/bookings/$sessionId/rtc-token'),
        headers: _buildHeaders(),
      );
      return _decode(res);
    });
  }

  // ---------------- WORKSPACES & PDF NOTES ----------------

  static Future<List<Workspace>> getUserWorkspaces(String userId) async {
    return _guard(() async {
      final res = await _get(
        _base.replace(path: '/api/workspaces/user/$userId'),
        headers: _buildHeaders(),
      );
      return _decodeList(res)
          .map((e) => Workspace.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  static Future<List<Note>> getWorkspaceNotes(String workspaceId) async {
    return _guard(() async {
      final res = await _get(
        _base.replace(path: '/api/workspaces/$workspaceId/notes'),
        headers: _buildHeaders(),
      );
      return _decodeList(res)
          .map((e) => Note.fromJson(e as Map<String, dynamic>))
          .toList();
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
      request.fields['title'] = title;
      request.fields['uploadedBy'] = uploadedBy;
      if (description != null) request.fields['description'] = description;
      if (dueDate != null) request.fields['dueDate'] = dueDate;
      if (pdfFile != null) {
        request.files
            .add(await http.MultipartFile.fromPath('pdf', pdfFile.path));
      }
      final res = await _sendMultipart(request);
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
      final res = await _post(
        _base.replace(path: '/api/workspaces/notes/$noteId/comments'),
        headers: _buildHeaders(),
        body: jsonEncode({
          'senderId': senderId,
          'senderName': senderName,
          'message': message
        }),
      );
      return NoteComment.fromJson(_decode(res));
    });
  }

  static Future<Note> toggleNote(String noteId) async {
    return _guard(() async {
      final res = await _patch(
        _base.replace(path: '/api/workspaces/notes/$noteId/toggle'),
        headers: _buildHeaders(),
      );
      return Note.fromJson(_decode(res));
    });
  }

  // ---------------- ADMIN ENDPOINTS ----------------

  static Future<List<AppUser>> getPendingMentors() async {
    return _guard(() async {
      final res = await _get(_base.replace(path: '/api/admin/pending-mentors'),
          headers: _buildHeaders());
      return _decodeList(res)
          .map((e) => AppUser.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  static Future<AppUser> approveMentor(String mentorId) async {
    return _guard(() async {
      final res = await _put(
          _base.replace(path: '/api/admin/approve-mentor/$mentorId'),
          headers: _buildHeaders());
      final data = _decode(res);
      final userMap =
          data['user'] is Map ? data['user'] as Map<String, dynamic> : data;
      return AppUser.fromJson(userMap);
    });
  }

  static Future<AppUser> toggleUserStatus(String userId,
      {String? status}) async {
    return _guard(() async {
      final res = await _put(
        _base.replace(path: '/api/admin/toggle-user-status/$userId'),
        headers: _buildHeaders(),
        body: status != null ? jsonEncode({'status': status}) : null,
      );
      final data = _decode(res);
      final userMap =
          data['user'] is Map ? data['user'] as Map<String, dynamic> : data;
      return AppUser.fromJson(userMap);
    });
  }

  static Future<Map<String, dynamic>> getEscrowTransactions() async {
    return _guard(() async {
      final res = await _get(
          _base.replace(path: '/api/admin/escrow-transactions'),
          headers: _buildHeaders());
      return _decode(res);
    });
  }

  static Future<Map<String, dynamic>> releaseEscrowAdmin(
      String bookingId) async {
    return _guard(() async {
      final res = await _put(
          _base.replace(path: '/api/admin/release-escrow/$bookingId'),
          headers: _buildHeaders());
      return _decode(res);
    });
  }

  static Future<List<dynamic>> getAuditLogs() async {
    return _guard(() async {
      final res = await _get(_base.replace(path: '/api/admin/audit-logs'),
          headers: _buildHeaders());
      return _decodeList(res);
    });
  }

  static Future<List<AppUser>> getAllUsers() async {
    return _guard(() async {
      final res = await _get(_base.replace(path: '/api/admin/users'),
          headers: _buildHeaders());
      return _decodeList(res)
          .map((e) => AppUser.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }
}

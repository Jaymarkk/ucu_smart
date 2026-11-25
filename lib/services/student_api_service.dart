import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/student_portal_models.dart';
import 'api_config.dart';

@immutable
class StudentProfile {
  const StudentProfile({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.email,
    required this.role,
    required this.status,
    this.studentId,
    this.course,
  });

  final String id;
  final String username;
  final String firstName;
  final String lastName;
  final String fullName;
  final String email;
  final String role;
  final String status;
  final String? studentId;
  final String? course;

  factory StudentProfile.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const StudentApiException(
        'The server returned an invalid student profile.',
      );
    }

    final id = value['id'];
    final username = value['username'];
    final firstName = value['first_name'];
    final lastName = value['last_name'];
    final fullName = value['full_name'];
    final email = value['email'];
    final role = value['role'];
    final status = value['status'];
    final studentId = value['student_id'];
    final course = value['course'];
    if (id == null ||
        username is! String ||
        firstName is! String ||
        lastName is! String ||
        fullName is! String ||
        email is! String ||
        role is! String ||
        status is! String ||
        (studentId != null && studentId is! String) ||
        (course != null && course is! String) ||
        username.trim().isEmpty ||
        firstName.trim().isEmpty ||
        lastName.trim().isEmpty ||
        fullName.trim().isEmpty ||
        email.trim().isEmpty ||
        role.trim().isEmpty ||
        status.trim().isEmpty) {
      throw const StudentApiException(
        'The server returned an invalid student profile.',
      );
    }

    return StudentProfile(
      id: id.toString(),
      username: username,
      firstName: firstName,
      lastName: lastName,
      fullName: fullName,
      email: email,
      role: role,
      status: status,
      studentId: studentId is String && studentId.trim().isNotEmpty
          ? studentId.trim()
          : null,
      course:
          course is String && course.trim().isNotEmpty ? course.trim() : null,
    );
  }
}

@immutable
class StudentLoginResponse {
  const StudentLoginResponse({required this.token, required this.profile});

  final String token;
  final StudentProfile profile;
}

class StudentApiException implements Exception {
  const StudentApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class StudentApiService {
  static final StudentApiService instance = StudentApiService();

  StudentApiService({
    String? baseUrl,
    http.Client? client,
  })  : _baseUri = Uri.parse(baseUrl ?? apiBaseUrl),
        _client = client ?? http.Client();

  final Uri _baseUri;
  final http.Client _client;

  void close() => _client.close();

  Future<StudentLoginResponse> login({
    required String username,
    required String password,
  }) async {
    final json = await _send(
      'POST',
      'student/login',
      body: {'username': username, 'password': password},
    );
    final token = json['access_token'];
    if (token is! String || token.trim().isEmpty) {
      throw const StudentApiException(
        'The server did not return a valid sign-in session.',
      );
    }

    return StudentLoginResponse(
      token: token,
      profile: StudentProfile.fromJson(json['user']),
    );
  }

  Future<StudentProfile> fetchProfile(String token) async {
    final json = await _send('GET', 'student/me', token: token);
    return StudentProfile.fromJson(json['user'] ?? json);
  }

  Future<void> logout(String token) async {
    await _send('POST', 'student/logout', token: token);
  }

  Future<StudentDashboardData> fetchDashboard(String token) async {
    final json = await _send('GET', 'student/dashboard', token: token);
    return StudentDashboardData.fromJson(json);
  }

  Future<List<StudentBuilding>> fetchBuildings(String token) async {
    final json = await _send('GET', 'student/buildings', token: token);
    final values = _listPayload(json, const ['buildings', 'data']);
    return values.map(StudentBuilding.fromJson).toList(growable: false);
  }

  Future<List<StudentRoom>> fetchBuildingRooms(
    String token,
    StudentBuilding building,
  ) async {
    final json = await _send(
      'GET',
      'student/buildings/${building.id}/rooms',
      token: token,
    );
    final values = _listPayload(json, const ['rooms', 'data']);
    return values
        .map(
          (value) => StudentRoom.fromJson(
            value,
            fallbackBuilding: building,
          ),
        )
        .toList(growable: false);
  }

  Future<StudentRoom> fetchRoom(String token, int roomId) async {
    final json = await _send('GET', 'student/rooms/$roomId', token: token);
    return StudentRoom.fromJson(json);
  }

  List<Object?> _listPayload(
    Map<String, dynamic> response,
    List<String> wrappers,
  ) {
    Object? current = response;
    for (var depth = 0; depth <= wrappers.length; depth++) {
      if (current is List) return current.cast<Object?>();
      if (current is! Map<String, dynamic>) break;
      final currentMap = current;
      var changed = false;
      for (final wrapper in wrappers) {
        if (currentMap.containsKey(wrapper)) {
          current = currentMap[wrapper];
          changed = true;
          break;
        }
      }
      if (!changed) break;
    }
    throw const StudentApiException('The server returned an invalid list.');
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    String? token,
    Map<String, Object?>? body,
  }) async {
    final uri = Uri.parse(
      '${_baseUri.toString().replaceFirst(RegExp(r'/+$'), '')}/$path',
    );
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    try {
      final request = http.Request(method, uri)..headers.addAll(headers);
      if (body != null) request.body = jsonEncode(body);
      final streamedResponse =
          await _client.send(request).timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _decodeResponse(response);
      }

      switch (response.statusCode) {
        case 401:
          throw StudentApiException(
            path == 'student/login'
                ? 'The username or password is incorrect.'
                : 'Your student session has expired. Please sign in again.',
            statusCode: 401,
          );
        case 403:
          throw const StudentApiException(
            'This account cannot access Student services. Check your account '
            'eligibility or contact the Registrar.',
            statusCode: 403,
          );
        case 422:
          throw StudentApiException(
            _validationMessage(response),
            statusCode: 422,
          );
        case 429:
          throw const StudentApiException(
            'Too many sign-in attempts. Please wait a while and try again.',
            statusCode: 429,
          );
      }

      if (response.statusCode >= 500) {
        throw StudentApiException(
          'The server encountered an error. Please try again later.',
          statusCode: response.statusCode,
        );
      }
      throw StudentApiException(
        'The request could not be completed. Please try again.',
        statusCode: response.statusCode,
      );
    } on StudentApiException {
      rethrow;
    } on SocketException {
      throw const StudentApiException(
        'Cannot connect to the server. Check your connection and try again.',
      );
    } on TimeoutException {
      throw const StudentApiException(
        'The server took too long to respond. Please try again.',
      );
    } on http.ClientException {
      throw const StudentApiException(
        'Cannot connect to the server. Check your connection and try again.',
      );
    }
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.body.isEmpty) return <String, dynamic>{};

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
    } on FormatException {
      throw const StudentApiException(
        'The server returned an unreadable response. Please try again.',
      );
    }

    throw const StudentApiException(
      'The server returned an unexpected response. Please try again.',
    );
  }

  String _validationMessage(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final errors = decoded['errors'];
        if (errors is Map<String, dynamic>) {
          final messages = errors.values
              .expand((value) => value is List ? value : [value])
              .whereType<String>()
              .where((message) => message.trim().isNotEmpty)
              .toList(growable: false);
          if (messages.isNotEmpty) return messages.join('\n');
        }
        final message = decoded['message'];
        if (message is String && message.trim().isNotEmpty) return message;
      }
    } on FormatException {
      return 'Enter a valid username and password, then try again.';
    }
    return 'Enter a valid username and password, then try again.';
  }
}

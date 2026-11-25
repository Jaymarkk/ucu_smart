import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ucu_smart_plus/screens/unified_login_screen.dart';
import 'package:ucu_smart_plus/services/student_api_service.dart';
import 'package:ucu_smart_plus/services/student_auth_service.dart';

class _MemoryTokenStore implements StudentTokenStore {
  _MemoryTokenStore([this.token]);
  String? token;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> writeToken(String value) async => token = value;

  @override
  Future<void> deleteToken() async => token = null;
}

Map<String, Object?> _studentProfile({String role = 'student', String status = 'active'}) => {
      'id': 42,
      'username': 'student42',
      'first_name': 'Test',
      'last_name': 'Student',
      'full_name': 'Test Student',
      'email': 'student@example.test',
      'role': role,
      'status': status,
    };

void main() {
  testWidgets('valid Student credentials open only the Student Dashboard',
      (tester) async {
    final studentClient = MockClient((request) async {
      if (request.url.path == '/api/student/login') {
        return http.Response(
          jsonEncode({
            'access_token': 'student-token',
            'user': _studentProfile(),
          }),
          200,
        );
      }
      if (request.url.path == '/api/student/me') {
        return http.Response(
          jsonEncode({'user': _studentProfile()}),
          200,
        );
      }
      return http.Response('', 404);
    });
    final store = _MemoryTokenStore();
    final auth = StudentAuthService(
      api: StudentApiService(
        baseUrl: 'http://localhost:8000/api',
        client: studentClient,
      ),
      tokenStore: store,
    );
    addTearDown(studentClient.close);
    addTearDown(auth.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: UnifiedLoginScreen(studentAuthService: auth),
        routes: {
          '/student-dashboard': (_) =>
              const Scaffold(body: Text('Student Dashboard')),
        },
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'student42');
    await tester.enterText(find.byType(TextFormField).at(1), 'password');
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(find.text('Student Dashboard'), findsOneWidget);
    expect(auth.isStudentAuthenticated, isTrue);
    expect(store.token, 'student-token');
  });

  testWidgets('non-student role is rejected by Student authentication',
      (tester) async {
    final client = MockClient((request) async {
      if (request.url.path == '/api/student/login') {
        return http.Response(
          jsonEncode({
            'access_token': 'rejected-token',
            'user': _studentProfile(role: 'admin'),
          }),
          200,
        );
      }
      if (request.url.path == '/api/student/logout') {
        return http.Response('', 204);
      }
      return http.Response('', 404);
    });
    final store = _MemoryTokenStore();
    final auth = StudentAuthService(
      api: StudentApiService(
        baseUrl: 'http://localhost:8000/api',
        client: client,
      ),
      tokenStore: store,
    );
    addTearDown(client.close);
    addTearDown(auth.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: UnifiedLoginScreen(studentAuthService: auth),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'admin');
    await tester.enterText(find.byType(TextFormField).at(1), 'password');
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(find.textContaining('not eligible'),
        findsOneWidget);
    expect(store.token, isNull);
    expect(auth.isStudentAuthenticated, isFalse);
  });

  testWidgets('invalid Student credentials show only the Student login error',
      (tester) async {
    final client = MockClient(
      (_) async => http.Response('', 401),
    );
    final auth = StudentAuthService(
      api: StudentApiService(
        baseUrl: 'http://localhost:8000/api',
        client: client,
      ),
      tokenStore: _MemoryTokenStore(),
    );
    addTearDown(client.close);
    addTearDown(auth.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: UnifiedLoginScreen(studentAuthService: auth),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'unknown');
    await tester.enterText(find.byType(TextFormField).at(1), 'wrong');
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(find.text('Invalid username or password.'), findsOneWidget);
    expect(auth.isStudentAuthenticated, isFalse);
  });

  testWidgets('restored active Student session opens Student Dashboard',
      (tester) async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/student/me');
      return http.Response(
        jsonEncode({'user': _studentProfile()}),
        200,
      );
    });
    final auth = StudentAuthService(
      api: StudentApiService(
        baseUrl: 'http://localhost:8000/api',
        client: client,
      ),
      tokenStore: _MemoryTokenStore('saved-student-token'),
    );
    addTearDown(client.close);
    addTearDown(auth.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: UnifiedLoginScreen(studentAuthService: auth),
        routes: {
          '/student-dashboard': (_) =>
              const Scaffold(body: Text('Student Dashboard')),
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Student Dashboard'), findsOneWidget);
  });
}

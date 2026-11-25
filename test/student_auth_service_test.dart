import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ucu_smart_plus/services/student_api_service.dart';
import 'package:ucu_smart_plus/services/student_auth_service.dart';

class _MemoryStudentTokenStore implements StudentTokenStore {
  String? token;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> writeToken(String value) async {
    token = value;
  }

  @override
  Future<void> deleteToken() async {
    token = null;
  }
}

Map<String, Object?> _studentProfile({
  String role = 'student',
  String status = 'active',
}) =>
    {
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
  group('Student API', () {
    test('posts credentials as JSON and sends bearer token for profile',
        () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        if (request.url.path.endsWith('/student/login')) {
          expect(request.method, 'POST');
          expect(request.headers['accept'], 'application/json');
          expect(request.headers['content-type'], 'application/json');
          expect(request.headers['authorization'], isNull);
          expect(
            jsonDecode(request.body),
            {'username': 'student42', 'password': 'password-value'},
          );
          return http.Response(
            jsonEncode({
              'access_token': 'test-student-token',
              'user': _studentProfile(),
            }),
            200,
          );
        }

        expect(request.method, 'GET');
        expect(request.url.path, '/api/student/me');
        expect(request.headers['accept'], 'application/json');
        expect(request.headers['authorization'], 'Bearer test-student-token');
        return http.Response(jsonEncode(_studentProfile()), 200);
      });
      final api = StudentApiService(
        baseUrl: 'http://localhost:8000/api',
        client: client,
      );
      addTearDown(api.close);

      final login = await api.login(
        username: 'student42',
        password: 'password-value',
      );
      final profile = await api.fetchProfile(login.token);

      expect(login.token, 'test-student-token');
      expect(login.profile.username, 'student42');
      expect(profile.fullName, 'Test Student');
      expect(requests, hasLength(2));
    });

    test('maps authentication status codes safely', () async {
      final cases = <int, String>{
        401: 'The username or password is incorrect.',
        403: 'This account cannot access Student services. Check your account '
            'eligibility or contact the Registrar.',
        429: 'Too many sign-in attempts. Please wait a while and try again.',
      };

      for (final entry in cases.entries) {
        final api = StudentApiService(
          baseUrl: 'http://localhost:8000/api',
          client: MockClient(
            (_) async => http.Response(
              jsonEncode({
                'message': 'Sensitive internal server detail',
                'errors': {
                  'username': ['raw framework error']
                },
              }),
              entry.key,
            ),
          ),
        );
        addTearDown(api.close);

        await expectLater(
          api.login(username: 'student42', password: 'password'),
          throwsA(
            isA<StudentApiException>()
                .having((error) => error.statusCode, 'statusCode', entry.key)
                .having(
                  (error) => error.message,
                  'safe message',
                  entry.value,
                ),
          ),
        );
      }
    });

    test('shows Laravel field validation errors from 422 responses', () async {
      final api = StudentApiService(
        baseUrl: 'http://localhost:8000/api',
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'message': 'The given data was invalid.',
              'errors': {
                'username': ['The username field is required.'],
                'password': ['The password field is required.'],
              },
            }),
            422,
          ),
        ),
      );
      addTearDown(api.close);

      await expectLater(
        api.login(username: '', password: ''),
        throwsA(
          isA<StudentApiException>()
              .having((error) => error.statusCode, 'statusCode', 422)
              .having(
                (error) => error.message,
                'message',
                'The username field is required.\n'
                    'The password field is required.',
              ),
        ),
      );
    });

    test('uses a safe fallback for unreadable Laravel validation responses',
        () async {
      final api = StudentApiService(
        baseUrl: 'http://localhost:8000/api',
        client: MockClient(
          (_) async => http.Response('<html>bad request</html>', 422),
        ),
      );
      addTearDown(api.close);

      await expectLater(
        api.login(username: 'student42', password: 'password'),
        throwsA(
          isA<StudentApiException>().having(
            (error) => error.message,
            'message',
            'Enter a valid username and password, then try again.',
          ),
        ),
      );
    });

    test('accepts raw and wrapped student profile responses', () async {
      final wrappedApi = StudentApiService(
        baseUrl: 'http://localhost:8000/api',
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({'user': _studentProfile()}),
            200,
          ),
        ),
      );
      addTearDown(wrappedApi.close);

      expect(
        (await wrappedApi.fetchProfile('token')).role,
        'student',
      );
    });
  });

  group('Student authentication', () {
    test('verifies profile before storing token and logs out securely',
        () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        if (request.url.path.endsWith('/student/login')) {
          return http.Response(
            jsonEncode({
              'access_token': 'student-token',
              'user': _studentProfile(),
            }),
            200,
          );
        }
        if (request.url.path.endsWith('/student/me')) {
          expect(request.headers['authorization'], 'Bearer student-token');
          return http.Response(jsonEncode(_studentProfile()), 200);
        }
        if (request.url.path.endsWith('/student/logout')) {
          expect(request.method, 'POST');
          expect(request.headers['authorization'], 'Bearer student-token');
          return http.Response(
            jsonEncode({'message': 'Logged out successfully.'}),
            200,
          );
        }
        return http.Response('', 404);
      });
      final store = _MemoryStudentTokenStore();
      final api = StudentApiService(
        baseUrl: 'http://localhost:8000/api',
        client: client,
      );
      final auth = StudentAuthService(api: api, tokenStore: store);
      addTearDown(api.close);
      addTearDown(auth.dispose);

      await auth.login(username: 'student42', password: 'password');

      expect(auth.isStudentAuthenticated, isTrue);
      expect(auth.currentProfile?.role, 'student');
      expect(store.token, 'student-token');
      expect(requests.map((request) => request.url.path), [
        '/api/student/login',
        '/api/student/me',
      ]);

      await auth.logout();
      expect(requests.last.url.path, '/api/student/logout');
      expect(store.token, isNull);
      expect(auth.isStudentAuthenticated, isFalse);
    });

    test('restores a valid profile using the saved student token', () async {
      final store = _MemoryStudentTokenStore()..token = 'saved-student-token';
      final client = MockClient((request) async {
        expect(request.url.path, '/api/student/me');
        expect(
          request.headers['authorization'],
          'Bearer saved-student-token',
        );
        return http.Response(jsonEncode(_studentProfile()), 200);
      });
      final api = StudentApiService(
        baseUrl: 'http://localhost:8000/api',
        client: client,
      );
      final auth = StudentAuthService(api: api, tokenStore: store);
      addTearDown(api.close);
      addTearDown(auth.dispose);

      expect(await auth.restoreSession(), isTrue);
      expect(auth.isStudentAuthenticated, isTrue);
      expect(auth.currentProfile?.fullName, 'Test Student');
      expect(store.token, 'saved-student-token');
    });

    test('clears an expired token on session restoration', () async {
      final store = _MemoryStudentTokenStore()..token = 'expired-token';
      final api = StudentApiService(
        baseUrl: 'http://localhost:8000/api',
        client: MockClient(
          (_) async => http.Response('', 401),
        ),
      );
      final auth = StudentAuthService(api: api, tokenStore: store);
      addTearDown(api.close);
      addTearDown(auth.dispose);

      expect(await auth.restoreSession(), isFalse);
      expect(store.token, isNull);
      expect(auth.isStudentAuthenticated, isFalse);
    });

    test('rejects non-student role and never stores its token', () async {
      final store = _MemoryStudentTokenStore();
      final requests = <String>[];
      final api = StudentApiService(
        baseUrl: 'http://localhost:8000/api',
        client: MockClient((request) async {
          requests.add(request.url.path);
          if (request.url.path.endsWith('/student/login')) {
            return http.Response(
              jsonEncode({
                'access_token': 'wrong-role-token',
                'user': _studentProfile(role: 'admin'),
              }),
              200,
            );
          }
          return http.Response('', 200);
        }),
      );
      final auth = StudentAuthService(api: api, tokenStore: store);
      addTearDown(api.close);
      addTearDown(auth.dispose);

      await expectLater(
        auth.login(username: 'admin', password: 'password'),
        throwsA(isA<StudentAuthorizationException>()),
      );

      expect(requests, ['/api/student/login', '/api/student/logout']);
      expect(store.token, isNull);
      expect(auth.isStudentAuthenticated, isFalse);
    });

    test('does not store an inactive profile token', () async {
      final store = _MemoryStudentTokenStore();
      final api = StudentApiService(
        baseUrl: 'http://localhost:8000/api',
        client: MockClient((request) async {
          if (request.url.path.endsWith('/student/login')) {
            return http.Response(
              jsonEncode({
                'access_token': 'inactive-token',
                'user': _studentProfile(status: 'pending'),
              }),
              200,
            );
          }
          return http.Response('', 200);
        }),
      );
      final auth = StudentAuthService(api: api, tokenStore: store);
      addTearDown(api.close);
      addTearDown(auth.dispose);

      await expectLater(
        auth.login(username: 'pending', password: 'password'),
        throwsA(isA<StudentAuthorizationException>()),
      );
      expect(store.token, isNull);
    });

    test('clears the local token even if server logout fails', () async {
      final store = _MemoryStudentTokenStore()..token = 'current-token';
      final api = StudentApiService(
        baseUrl: 'http://localhost:8000/api',
        client: MockClient((_) async => http.Response('', 503)),
      );
      final auth = StudentAuthService(api: api, tokenStore: store);
      addTearDown(api.close);
      addTearDown(auth.dispose);

      await expectLater(
        auth.logout(),
        throwsA(isA<StudentApiException>()),
      );
      expect(store.token, isNull);
      expect(auth.isStudentAuthenticated, isFalse);
    });
  });
}

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ucu_smart_plus/models/student_portal_models.dart';
import 'package:ucu_smart_plus/screens/student_building_details_screen.dart';
import 'package:ucu_smart_plus/screens/student_dashboard_screen.dart';
import 'package:ucu_smart_plus/screens/student_profile_screen.dart';
import 'package:ucu_smart_plus/screens/student_room_availability_screen.dart';
import 'package:ucu_smart_plus/main.dart';
import 'package:ucu_smart_plus/services/building_api_service.dart';
import 'package:ucu_smart_plus/services/student_api_service.dart';
import 'package:ucu_smart_plus/services/student_auth_service.dart';
import 'package:ucu_smart_plus/widgets/student_portal_components.dart';

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

class _StudentRig {
  _StudentRig(this.api, this.auth, this.store);

  final StudentApiService api;
  final StudentAuthService auth;
  final _MemoryStudentTokenStore store;

  void dispose() {
    auth.dispose();
    api.close();
  }
}

class _ProfileAuthService extends StudentAuthService {
  _ProfileAuthService({
    required super.api,
    required super.tokenStore,
    required StudentProfile profile,
  }) : _profile = profile;

  final StudentProfile _profile;

  @override
  StudentProfile? get currentProfile => _profile;

  @override
  bool get isStudentAuthenticated => true;
}

Map<String, Object?> _profile() => {
      'id': 23,
      'student_id': '20230528',
      'username': 'student42',
      'first_name': 'Test',
      'last_name': 'Student',
      'full_name': 'Test Student',
      'email': 'student@example.test',
      'role': 'student',
      'status': 'active',
      'course': 'Bachelor of Science in Information Technology',
    };

Future<_StudentRig> _authenticatedRig(
  Future<http.Response> Function(http.Request request) handler,
) async {
  final store = _MemoryStudentTokenStore()..token = 'student-test-token';
  final api = StudentApiService(
    baseUrl: 'http://localhost:8000/api',
    client: MockClient((request) async {
      if (request.url.path == '/api/student/me') {
        expect(request.headers['authorization'], 'Bearer student-test-token');
        return http.Response(jsonEncode({'user': _profile()}), 200);
      }
      return handler(request);
    }),
  );
  final auth = StudentAuthService(api: api, tokenStore: store);
  expect(await auth.restoreSession(), isTrue);
  return _StudentRig(api, auth, store);
}

void main() {
  group('Student Portal API', () {
    test('maps student ID and course independently from database user ID',
        () async {
      final api = StudentApiService(
        baseUrl: 'http://localhost:8000/api',
        client: MockClient((request) async {
          expect(request.url.path, '/api/student/me');
          return http.Response(
            jsonEncode({'user': _profile()}),
            200,
          );
        }),
      );
      addTearDown(api.close);

      final profile = await api.fetchProfile('student-token');

      expect(profile.id, '23');
      expect(profile.studentId, '20230528');
      expect(profile.course, 'Bachelor of Science in Information Technology');
    });

    test('calls dashboard, buildings, building rooms, and room detail',
        () async {
      final requests = <http.Request>[];
      final api = StudentApiService(
        baseUrl: 'http://localhost:8000/api',
        client: MockClient((request) async {
          requests.add(request);
          expect(request.headers['accept'], 'application/json');
          expect(request.headers['authorization'], 'Bearer portal-token');
          switch (request.url.path) {
            case '/api/student/dashboard':
              return http.Response(
                jsonEncode({
                  'data': {
                    'total_buildings': 2,
                    'total_rooms': 14,
                    'available_rooms': 5,
                    'occupied_rooms': 9,
                  },
                }),
                200,
              );
            case '/api/student/buildings':
              return http.Response(
                jsonEncode({
                  'data': [
                    {
                      'id': 8,
                      'code': 'SCI',
                      'name': 'Science Building',
                      'rooms_count': 7,
                    },
                  ],
                }),
                200,
              );
            case '/api/student/buildings/8/rooms':
              return http.Response(
                jsonEncode({
                  'data': {
                    'rooms': [
                      {
                        'id': 92,
                        'room_number': '204',
                        'room_name': 'Lecture Room',
                        'floor': 2,
                        'capacity': 40,
                      },
                    ],
                  },
                }),
                200,
              );
            case '/api/student/rooms/92':
              return http.Response(
                jsonEncode({
                  'data': {
                    'room': {
                      'id': 92,
                      'room_number': '204',
                      'room_name': 'Lecture Room',
                      'floor': 2,
                      'capacity': 40,
                      'building': {
                        'id': 8,
                        'building_code': 'SCI',
                        'building_name': 'Science Building',
                        'rooms_count': 7,
                      },
                      'availability': {
                        'status': 'available',
                        'checked_at': '2026-11-03T00:00:00+08:00',
                        'current_schedule': null,
                      },
                    },
                  },
                }),
                200,
              );
          }
          return http.Response('', 404);
        }),
      );
      addTearDown(api.close);
      const building = StudentBuilding(
        id: 8,
        code: 'SCI',
        name: 'Science Building',
      );

      final summary = await api.fetchDashboard('portal-token');
      final buildings = await api.fetchBuildings('portal-token');
      final rooms = await api.fetchBuildingRooms('portal-token', building);
      final room = await api.fetchRoom('portal-token', 92);

      expect(summary.totalBuildings, 2);
      expect(summary.availableRooms, 5);
      expect(buildings.single.name, 'Science Building');
      expect(rooms.single.building, same(building));
      expect(rooms.single.floor, '2');
      expect(rooms.single.capacity, 40);
      expect(room.building?.code, 'SCI');
      expect(room.floor, '2');
      expect(room.availability, 'available');
      expect(room.isAvailable, isTrue);
      expect(requests.map((request) => request.url.path), [
        '/api/student/dashboard',
        '/api/student/buildings',
        '/api/student/buildings/8/rooms',
        '/api/student/rooms/92',
      ]);
    });

    test('parses empty building lists and rejects malformed list responses',
        () async {
      final api = StudentApiService(
        baseUrl: 'http://localhost:8000/api',
        client: MockClient(
          (_) async => http.Response(jsonEncode({'data': []}), 200),
        ),
      );
      addTearDown(api.close);

      expect(await api.fetchBuildings('portal-token'), isEmpty);

      final invalidApi = StudentApiService(
        baseUrl: 'http://localhost:8000/api',
        client: MockClient(
          (_) async => http.Response(jsonEncode({'data': {}}), 200),
        ),
      );
      addTearDown(invalidApi.close);
      await expectLater(
        invalidApi.fetchBuildings('portal-token'),
        throwsA(isA<StudentApiException>()),
      );
    });
  });

  group('Student Portal screens', () {
    testWidgets('dashboard matches the Student Portal feature layout',
        (tester) async {
      final rig = await _authenticatedRig((request) async {
        expect(request.url.path, '/api/student/dashboard');
        return http.Response(
          jsonEncode({
            'data': {
              'total_buildings': 9,
              'total_rooms': 73,
              'available_rooms': 12,
              'occupied_rooms': 54,
              'unavailable_rooms': 7,
            },
          }),
          200,
        );
      });
      addTearDown(rig.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: StudentDashboardScreen(
            authService: rig.auth,
            api: rig.api,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              widget.textSpan?.toPlainText() == 'Welcome back, Test Student',
        ),
        findsOneWidget,
      );
      expect(find.text('student@example.test'), findsNothing);
      expect(find.text('Campus overview'), findsNothing);
      expect(find.text('Student services'), findsNothing);
      expect(find.text('Buildings'), findsNothing);
      expect(find.text('Rooms'), findsNothing);
      expect(find.text('Available'), findsNothing);
      expect(find.text('Occupied'), findsNothing);
      expect(find.text('Room Availability'), findsOneWidget);
      expect(
        find.text(
          'Check which classrooms are currently available or occupied across the campus.',
        ),
        findsOneWidget,
      );
      expect(find.text('View Available Rooms'), findsOneWidget);
      expect(find.text('UCU Smart+ Mobile'), findsNothing);
      expect(find.text('Get the Mobile App'), findsNothing);
      expect(find.text('How UCU Smart+ Helps You'), findsOneWidget);
      expect(find.text('Find a Building'), findsOneWidget);
      expect(find.text('Check a Room'), findsOneWidget);
      expect(find.text('Navigate with Mobile'), findsOneWidget);
    });

    testWidgets('navigation adapts from a mobile drawer to a desktop sidebar',
        (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final rig = await _authenticatedRig((request) async =>
          http.Response(jsonEncode({'total_rooms': 5}), 200));
      addTearDown(rig.dispose);

      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        MaterialApp(
          home: StudentDashboardScreen(
            authService: rig.auth,
            api: rig.api,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.menu), findsOneWidget);
      expect(find.byType(Drawer), findsNothing);

      await tester.binding.setSurfaceSize(const Size(1280, 900));
      await tester.pumpAndSettle();
      expect(find.byType(Drawer), findsNothing);
      expect(find.text('Campus Navigation'), findsOneWidget);
      expect(find.text('My Profile'), findsOneWidget);
    });

    testWidgets('navigation menu opens each existing portal destination',
        (tester) async {
      final rig = await _authenticatedRig((request) async =>
          http.Response(jsonEncode({'total_rooms': 5}), 200));
      addTearDown(rig.dispose);
      final destinationRoutes = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: StudentDashboardScreen(
            authService: rig.auth,
            api: rig.api,
          ),
          onGenerateRoute: (settings) {
            destinationRoutes.add(settings.name!);
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => Scaffold(
                appBar: AppBar(),
                body: Center(child: Text(settings.name!)),
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      const destinations = {
        'Dashboard': '/student-dashboard',
        'Room Availability': '/student/room-availability',
        'Campus Navigation': '/campus-map',
        'My Profile': '/student/profile',
      };
      for (final entry in destinations.entries) {
        await tester.tap(find.byIcon(Icons.menu));
        await tester.pumpAndSettle();
        final destinationItem = find.widgetWithText(ListTile, entry.key);
        expect(destinationItem, findsOneWidget);
        final item = tester.widget<ListTile>(
          destinationItem,
        );
        if (entry.key == 'Dashboard') {
          expect(item.selected, isTrue);
        }
        await tester.tap(destinationItem);
        await tester.pumpAndSettle();
        expect(find.text(entry.value), findsOneWidget);
        expect(destinationRoutes.last, entry.value);
        if (entry.key == 'Campus Navigation') {
          expect(
            ModalRoute.of(tester.element(find.text(entry.value)))!
                .settings
                .arguments,
            StudentPortalMapOrigin.studentPortal,
          );
        }
        await tester.pageBack();
        await tester.pumpAndSettle();
      }
    });

    testWidgets(
        'Student opens the existing map and returns to dashboard without logout',
        (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final rig = await _authenticatedRig((request) async =>
          http.Response(jsonEncode({'total_rooms': 5}), 200));
      addTearDown(rig.dispose);
      final buildingApi = BuildingApiService(
        baseUrl: 'http://localhost:8000/api',
        client: MockClient((request) async {
          if (request.url.path == '/api/buildings') {
            return http.Response(jsonEncode({'data': []}), 200);
          }
          return http.Response('', 404);
        }),
        campusHeadersProvider: () => null,
      );
      addTearDown(buildingApi.close);

      await tester.binding.setSurfaceSize(const Size(1280, 900));
      await tester.pumpWidget(
        MaterialApp(
          home: StudentDashboardScreen(
            authService: rig.auth,
            api: rig.api,
          ),
          onGenerateRoute: (settings) {
            if (settings.name == '/campus-map') {
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => CampusMapPage(
                  buildingApi: buildingApi,
                  studentAuthService: rig.auth,
                  openedFromStudentPortal: settings.arguments ==
                      StudentPortalMapOrigin.studentPortal,
                ),
              );
            }
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => Scaffold(
                body: Center(child: Text(settings.name ?? 'Unknown route')),
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ListTile, 'Campus Navigation'));
      await tester.pumpAndSettle();

      expect(find.byType(CampusMapPage), findsOneWidget);
      expect(find.text('Back to Student Dashboard'), findsOneWidget);
      expect(rig.auth.isStudentAuthenticated, isTrue);
      expect(rig.store.token, 'student-test-token');

      await tester.tap(find.text('Back to Student Dashboard'));
      await tester.pumpAndSettle();

      expect(find.byType(CampusMapPage), findsNothing);
      expect(find.text('Student Dashboard'), findsOneWidget);
      expect(rig.auth.isStudentAuthenticated, isTrue);
      expect(rig.store.token, 'student-test-token');

      await tester.tap(find.widgetWithText(ListTile, 'Campus Navigation'));
      await tester.pumpAndSettle();
      expect(find.byType(CampusMapPage), findsOneWidget);
      expect(find.text('Back to Student Dashboard'), findsOneWidget);
    });

    testWidgets('map return button requires an authenticated Student session',
        (tester) async {
      final api = StudentApiService(
        baseUrl: 'http://localhost:8000/api',
        client: MockClient((_) async => http.Response('', 401)),
      );
      final auth = StudentAuthService(
        api: api,
        tokenStore: _MemoryStudentTokenStore(),
      );
      addTearDown(auth.dispose);
      addTearDown(api.close);
      final buildingApi = BuildingApiService(
        baseUrl: 'http://localhost:8000/api',
        client: MockClient((_) async => http.Response(
              jsonEncode({'data': []}),
              200,
            )),
        campusHeadersProvider: () => null,
      );
      addTearDown(buildingApi.close);

      await tester.pumpWidget(
        MaterialApp(
          home: CampusMapPage(
            buildingApi: buildingApi,
            studentAuthService: auth,
            openedFromStudentPortal: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(auth.isStudentAuthenticated, isFalse);
      expect(find.text('Back to Student Dashboard'), findsNothing);
    });

    testWidgets('Room Availability card opens the existing building list',
        (tester) async {
      final rig = await _authenticatedRig((request) async {
        if (request.url.path == '/api/student/dashboard') {
          return http.Response(jsonEncode({'total_rooms': 5}), 200);
        }
        if (request.url.path == '/api/student/buildings') {
          return http.Response(jsonEncode({'data': []}), 200);
        }
        return http.Response('{}', 404);
      });
      addTearDown(rig.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: StudentDashboardScreen(
            authService: rig.auth,
            api: rig.api,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('View Available Rooms'));
      await tester.pumpAndSettle();

      expect(find.text('No buildings available'), findsOneWidget);
      expect(find.text('Room Availability'), findsNWidgets(2));
    });

    testWidgets('dashboard shows loading and retryable server error',
        (tester) async {
      final response = Completer<http.Response>();
      var attempts = 0;
      final rig = await _authenticatedRig((request) async {
        attempts++;
        if (attempts == 1) return response.future;
        return http.Response(
          jsonEncode({'total_buildings': 3, 'total_rooms': 18}),
          200,
        );
      });
      addTearDown(rig.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: StudentDashboardScreen(
            authService: rig.auth,
            api: rig.api,
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Loading student information…'), findsOneWidget);

      response.complete(http.Response('{}', 503));
      await tester.pumpAndSettle();
      expect(
          find.text('The server encountered an error. Please try again later.'),
          findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Room Availability'), findsOneWidget);
      expect(find.text('View Available Rooms'), findsOneWidget);
    });

    testWidgets('building list shows empty and searchable success states',
        (tester) async {
      var includeBuildings = false;
      final rig = await _authenticatedRig((request) async {
        expect(request.url.path, '/api/student/buildings');
        return http.Response(
          jsonEncode({
            'data': includeBuildings
                ? [
                    {
                      'id': 8,
                      'code': 'SCI',
                      'name': 'Science Building',
                      'rooms_count': 7,
                    },
                    {
                      'id': 9,
                      'code': 'LIB',
                      'name': 'Main Library',
                      'rooms_count': 3,
                    },
                  ]
                : [],
          }),
          200,
        );
      });
      addTearDown(rig.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: StudentRoomAvailabilityScreen(
            authService: rig.auth,
            api: rig.api,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No buildings available'), findsOneWidget);

      includeBuildings = true;
      await tester.tap(find.byTooltip('Refresh buildings'));
      await tester.pumpAndSettle();
      expect(find.text('Science Building'), findsOneWidget);
      expect(find.text('Main Library'), findsOneWidget);

      await tester.enterText(
        find.byType(TextField).first,
        'science',
      );
      await tester.pumpAndSettle();
      expect(find.text('Science Building'), findsOneWidget);
      expect(find.text('Main Library'), findsNothing);
    });

    testWidgets('building detail displays rooms and room detail fields',
        (tester) async {
      const building = StudentBuilding(
        id: 8,
        code: 'SCI',
        name: 'Science Building',
        roomCount: 1,
      );
      final rig = await _authenticatedRig((request) async {
        if (request.url.path == '/api/student/buildings/8/rooms') {
          return http.Response(
            jsonEncode({
              'data': [
                {
                  'id': 92,
                  'room_number': 'BB - 202',
                  'room_name': 'BB - 202',
                  'floor': 2,
                  'capacity': 0,
                },
              ],
            }),
            200,
          );
        }
        if (request.url.path == '/api/student/rooms/92') {
          return http.Response(
            jsonEncode({
              'data': {
                'id': 12,
                'room_number': 'BB - 202',
                'room_name': 'BB - 202',
                'floor': 2,
                'capacity': 0,
                'building': {
                  'id': 8,
                  'building_code': 'SCI',
                  'building_name': 'Science Building',
                  'room_count': 1,
                },
                'availability': {
                  'status': 'available',
                  'checked_at': '2026-11-03T00:00:00+08:00',
                  'current_schedule': null,
                },
              },
            }),
            200,
          );
        }
        return http.Response('', 404);
      });
      addTearDown(rig.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: StudentBuildingDetailsScreen(
            authService: rig.auth,
            api: rig.api,
            building: building,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Science Building'), findsNWidgets(2));
      expect(find.text('BB - 202'), findsNWidgets(2));
      expect(find.text('Floor'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Capacity'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('Check availability'), findsOneWidget);

      await tester.tap(find.text('Check availability'));
      await tester.pumpAndSettle();
      expect(find.text('Room Details'), findsOneWidget);
      expect(find.text('BB - 202'), findsNWidgets(2));
      expect(find.text('Available'), findsOneWidget);
      expect(
        find.text('No class is currently using this room.'),
        findsOneWidget,
      );
      expect(find.text('Building'), findsOneWidget);
      expect(find.text('Science Building'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('profile displays authenticated details and active status',
        (tester) async {
      final rig = await _authenticatedRig((_) async => http.Response('', 404));
      addTearDown(rig.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: StudentProfileScreen(authService: rig.auth),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Student Account'), findsNWidgets(2));
      expect(find.text('Test Student'), findsOneWidget);
      expect(find.text('UCU Smart+ Student Portal'), findsOneWidget);
      expect(find.text('Student Information'), findsOneWidget);
      expect(find.text('Your registered account details.'), findsOneWidget);
      expect(find.text('First Name'), findsOneWidget);
      expect(find.text('Test'), findsOneWidget);
      expect(find.text('Last Name'), findsOneWidget);
      expect(find.text('Student ID'), findsOneWidget);
      expect(find.text('20230528'), findsOneWidget);
      expect(find.text('23'), findsNothing);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('student@example.test'), findsOneWidget);
      expect(find.text('Course'), findsOneWidget);
      expect(
        find.text('Bachelor of Science in Information Technology'),
        findsOneWidget,
      );
      expect(find.text('Not provided'), findsNothing);
      expect(find.text('Account Status'), findsOneWidget);
      expect(find.text('Your account is currently active.'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.textContaining('password'), findsNothing);
    });

    testWidgets('profile uses one column on mobile and two columns when wide',
        (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final rig = await _authenticatedRig((_) async => http.Response('', 404));
      addTearDown(rig.dispose);

      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        MaterialApp(home: StudentProfileScreen(authService: rig.auth)),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.text('First Name')).dx,
        tester.getTopLeft(find.text('Last Name')).dx,
      );
      expect(tester.takeException(), isNull);

      await tester.binding.setSurfaceSize(const Size(1280, 900));
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.text('Last Name')).dx,
        greaterThan(tester.getTopLeft(find.text('First Name')).dx),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('profile status badge reflects a non-active API status',
        (tester) async {
      final api = StudentApiService(
        baseUrl: 'http://localhost:8000/api',
        client: MockClient((_) async => http.Response('', 404)),
      );
      final auth = _ProfileAuthService(
        api: api,
        tokenStore: _MemoryStudentTokenStore(),
        profile: StudentProfile.fromJson({
          ..._profile(),
          'status': 'inactive',
        }),
      );
      addTearDown(() {
        auth.dispose();
        api.close();
      });

      await tester.pumpWidget(
        MaterialApp(home: StudentProfileScreen(authService: auth)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Your account is currently inactive.'), findsOneWidget);
      expect(find.text('Inactive'), findsOneWidget);
      expect(find.text('Active'), findsNothing);
    });
  });
}

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:ucu_smart_plus/main.dart';
import 'package:ucu_smart_plus/services/building_api_service.dart';
import 'package:ucu_smart_plus/services/campus_geofence_service.dart';
import 'package:ucu_smart_plus/services/campus_map_development_policy.dart';
import 'package:ucu_smart_plus/services/student_api_service.dart';
import 'package:ucu_smart_plus/services/student_auth_service.dart';

import 'support/fake_campus_location_provider.dart';

Map<String, String> _testCampusHeaders() => {
      'X-Campus-Latitude': '0.5',
      'X-Campus-Longitude': '0.5',
      'X-Campus-Accuracy': '5',
      'X-Campus-Timestamp': DateTime.now().toUtc().toIso8601String(),
    };

CampusGeofenceService _testGeofenceService() {
  final service = testCampusGeofenceService();
  addTearDown(service.dispose);
  return service;
}

CampusGeofenceService _unconfiguredGeofenceService() {
  final service = CampusGeofenceService(
    locationProvider: FakeCampusLocationProvider(),
  );
  addTearDown(service.dispose);
  return service;
}

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

BuildingApiService _buildingApiFor(List<Map<String, Object?>> buildings) {
  return BuildingApiService(
    baseUrl: 'http://localhost:8000/api',
    campusHeadersProvider: _testCampusHeaders,
    client: MockClient((request) async {
      if (request.method == 'GET' && request.url.path == '/api/buildings') {
        return http.Response(jsonEncode({'data': buildings}), 200);
      }
      return http.Response('', 404);
    }),
  );
}

Future<void> _openVisitorCampusMap(WidgetTester tester) async {
  final buildingApi = _buildingApiFor(const []);
  addTearDown(buildingApi.close);
  final geofenceService = _testGeofenceService();
  await tester.pumpWidget(
    UcuSmartPlusApp(
      buildingApi: buildingApi,
      geofenceService: geofenceService,
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Continue as Visitor'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Visitor opens the map after location verification',
      (tester) async {
    final buildingApi = _buildingApiFor(const []);
    addTearDown(buildingApi.close);
    final geofenceService = _testGeofenceService();

    await tester.pumpWidget(
      UcuSmartPlusApp(
        buildingApi: buildingApi,
        geofenceService: geofenceService,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Continue as Visitor'), findsOneWidget);
    await tester.tap(find.text('Continue as Visitor'));
    await tester.pumpAndSettle();

    expect(find.byType(CampusMapPage), findsOneWidget);
    expect(find.text('Campus Access Restricted'), findsNothing);
    expect(find.text('Back to Student Dashboard'), findsNothing);
    expect(geofenceService.state.isGranted, isTrue);
  }, skip: campusMapDevelopmentBypassEnabled);

  testWidgets(
      'Visitor outside campus remains restricted without a retry button',
      (tester) async {
    final provider = FakeCampusLocationProvider()
      ..fix = CampusLocationFix(
        point: const GeoPoint(2, 0.5),
        accuracyMeters: 5,
        timestamp: DateTime.utc(2026, 1, 1),
      );
    final geofenceService = testCampusGeofenceService(provider: provider);
    final buildingApi = _buildingApiFor(const []);
    addTearDown(geofenceService.dispose);
    addTearDown(buildingApi.close);

    await tester.pumpWidget(
      UcuSmartPlusApp(
        buildingApi: buildingApi,
        geofenceService: geofenceService,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue as Visitor'));
    await tester.pumpAndSettle();

    expect(find.byType(CampusMapPage), findsNothing);
    expect(find.text('Campus Access Restricted'), findsOneWidget);
    expect(find.text('Location Outside Campus Boundary'), findsOneWidget);
    expect(find.text('Retry Location Verification'), findsNothing);
    expect(geofenceService.currentAccessHeaders, isNull);
  }, skip: campusMapDevelopmentBypassEnabled);

  testWidgets('entry offers Visitor and one shared Login destination',
      (WidgetTester tester) async {
    final buildingApi = _buildingApiFor(const []);
    final studentApi = StudentApiService(
      baseUrl: 'http://localhost:8000/api',
      client: MockClient((_) async => http.Response('', 401)),
    );
    final studentAuth = StudentAuthService(
      api: studentApi,
      tokenStore: _MemoryStudentTokenStore(),
    );
    addTearDown(buildingApi.close);
    addTearDown(studentApi.close);
    addTearDown(studentAuth.dispose);
    await tester.pumpWidget(
      UcuSmartPlusApp(
        studentAuthService: studentAuth,
        buildingApi: buildingApi,
        geofenceService: _testGeofenceService(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Continue as Visitor'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Admin Login'), findsNothing);
    expect(find.text('Student Login'), findsNothing);
    expect(find.text('Campus Locations'), findsNothing);

    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome!'), findsOneWidget);
    expect(
      find.text('Please log in to your access account.'),
      findsOneWidget,
    );
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Admin Login'), findsNothing);
    expect(find.text('Student Login'), findsNothing);
  });

  testWidgets('shared login validates fields and respects campus gate',
      (WidgetTester tester) async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      if (request.url.path.endsWith('/student/login')) {
        return http.Response(
          jsonEncode({
            'access_token': 'student-test-token',
            'user': {
              'id': 42,
              'username': 'student42',
              'first_name': 'Test',
              'last_name': 'Student',
              'full_name': 'Test Student',
              'email': 'student@example.test',
              'role': 'student',
              'status': 'active',
            },
          }),
          200,
        );
      }
      if (request.url.path.endsWith('/student/me')) {
        return http.Response(
          jsonEncode({
            'id': 42,
            'username': 'student42',
            'first_name': 'Test',
            'last_name': 'Student',
            'full_name': 'Test Student',
            'email': 'student@example.test',
            'role': 'student',
            'status': 'active',
          }),
          200,
        );
      }
      return http.Response('', 404);
    });
    final api = StudentApiService(
      baseUrl: 'http://localhost:8000/api',
      client: client,
    );
    final auth = StudentAuthService(
      api: api,
      tokenStore: _MemoryStudentTokenStore(),
    );
    addTearDown(api.close);
    addTearDown(auth.dispose);

    final buildingApi = _buildingApiFor(const []);
    addTearDown(buildingApi.close);
    await tester.pumpWidget(
      UcuSmartPlusApp(
        studentAuthService: auth,
        buildingApi: buildingApi,
        geofenceService: _unconfiguredGeofenceService(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    expect(find.text('Username is required.'), findsOneWidget);
    expect(requests, isEmpty);

    await tester.enterText(find.byType(TextFormField).at(0), 'student42');
    await tester.enterText(find.byType(TextFormField).at(1), 'password');
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(requests.map((request) => request.url.path), [
      '/api/student/login',
      '/api/student/me',
      '/api/student/dashboard',
    ]);
    expect(find.text('Campus Access Restricted'), findsNothing);
    expect(find.text('Student Dashboard'), findsOneWidget);
  });

  testWidgets('verified student reaches the student dashboard and can sign out',
      (WidgetTester tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1280, 1000));
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/student/login')) {
        return http.Response(
          jsonEncode({
            'access_token': 'student-widget-token',
            'user': {
              'id': 42,
              'username': 'student42',
              'first_name': 'Test',
              'last_name': 'Student',
              'full_name': 'Test Student',
              'email': 'student@example.test',
              'role': 'student',
              'status': 'active',
            },
          }),
          200,
        );
      }
      if (request.url.path.endsWith('/student/me')) {
        return http.Response(
          jsonEncode({
            'id': 42,
            'username': 'student42',
            'first_name': 'Test',
            'last_name': 'Student',
            'full_name': 'Test Student',
            'email': 'student@example.test',
            'role': 'student',
            'status': 'active',
          }),
          200,
        );
      }
      if (request.url.path.endsWith('/student/dashboard')) {
        return http.Response(
          jsonEncode({
            'total_buildings': 4,
            'total_rooms': 20,
            'available_rooms': 12,
            'occupied_rooms': 8,
          }),
          200,
        );
      }
      if (request.url.path.endsWith('/student/logout')) {
        return http.Response('', 204);
      }
      return http.Response('', 404);
    });
    final api = StudentApiService(
      baseUrl: 'http://localhost:8000/api',
      client: client,
    );
    final tokenStore = _MemoryStudentTokenStore();
    final auth = StudentAuthService(
      api: api,
      tokenStore: tokenStore,
    );
    addTearDown(api.close);
    addTearDown(auth.dispose);

    final buildingApi = _buildingApiFor(const []);
    addTearDown(buildingApi.close);
    await tester.pumpWidget(
      UcuSmartPlusApp(
        studentAuthService: auth,
        buildingApi: buildingApi,
        geofenceService: _testGeofenceService(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'student42');
    await tester.enterText(find.byType(TextFormField).at(1), 'password');
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(find.text('Student Dashboard'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.textSpan?.toPlainText() == 'Welcome back, Test Student',
      ),
      findsOneWidget,
    );
    expect(find.text('Admin Dashboard'), findsNothing);

    await tester.tap(find.widgetWithText(ListTile, 'Campus Navigation'));
    await tester.pumpAndSettle();
    expect(find.byType(CampusMapPage), findsOneWidget);
    expect(find.text('Back to Student Dashboard'), findsOneWidget);
    expect(auth.isStudentAuthenticated, isTrue);
    expect(tokenStore.token, 'student-widget-token');

    await tester.tap(find.text('Back to Student Dashboard'));
    await tester.pumpAndSettle();
    expect(find.byType(CampusMapPage), findsNothing);
    expect(find.text('Student Dashboard'), findsOneWidget);
    expect(find.text('Continue as Visitor'), findsNothing);
    expect(find.text('Welcome!'), findsNothing);
    expect(auth.isStudentAuthenticated, isTrue);
    expect(tokenStore.token, 'student-widget-token');

    await tester.tap(find.widgetWithText(ListTile, 'Campus Navigation'));
    await tester.pumpAndSettle();
    expect(find.byType(CampusMapPage), findsOneWidget);
    expect(find.text('Back to Student Dashboard'), findsOneWidget);
    await tester.tap(find.text('Back to Student Dashboard'));
    await tester.pumpAndSettle();
    expect(find.text('Student Dashboard'), findsOneWidget);

    await tester.tap(find.byTooltip('Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Student Dashboard'), findsNothing);
    expect(find.text('Continue as Visitor'), findsOneWidget);
    expect(auth.isStudentAuthenticated, isFalse);
  });

  testWidgets('Visitor building search opens off-map details without routes',
      (WidgetTester tester) async {
    final buildingApi = _buildingApiFor([
      {
        'id': 72,
        'code': 'LAB-72',
        'name': 'Unmapped Laboratory',
        'description': 'A new lab building.',
        'location_details': 'Beside the north campus entrance.',
        'category': 'Academic',
        'map_x_pct': null,
        'map_y_pct': null,
        'route_node_id': null,
        'route_connection_verified': false,
        'is_active': true,
        'is_public': true,
      },
    ]);
    addTearDown(buildingApi.close);
    final geofenceService = _testGeofenceService();

    await tester.pumpWidget(
      UcuSmartPlusApp(
        buildingApi: buildingApi,
        geofenceService: geofenceService,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue as Visitor'));
    await tester.pumpAndSettle();

    expect(find.text('36 locations'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'LAB-72');
    await tester.pumpAndSettle();
    expect(find.text('Unmapped Laboratory'), findsOneWidget);
    await tester.tap(find.text('Unmapped Laboratory'));
    await tester.pumpAndSettle();

    expect(find.text('Location on campus'), findsOneWidget);
    expect(
      find.text('Beside the north campus entrance.'),
      findsOneWidget,
    );
    expect(
      find.text('About this building: A new lab building.'),
      findsOneWidget,
    );
    expect(
      find.text('A map marker is not yet available for this building.'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Directions are not available until a map location and walkable-path connection are verified.',
      ),
      findsOneWidget,
    );
    expect(find.text('Get Directions'), findsNothing);
  });

  testWidgets('public B21 TEST appears with description and no marker or route',
      (WidgetTester tester) async {
    final buildingApi = _buildingApiFor([
      {
        'id': 26,
        'code': 'B21',
        'name': 'TEST',
        'category': 'Building',
        'description': 'TEST',
        'location_details': null,
        'map_x_pct': null,
        'map_y_pct': null,
        'route_node_id': null,
        'route_connection_verified': false,
        'is_active': true,
        'is_public': true,
      },
    ]);
    addTearDown(buildingApi.close);

    await tester.pumpWidget(
      UcuSmartPlusApp(
        buildingApi: buildingApi,
        geofenceService: _testGeofenceService(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue as Visitor'));
    await tester.pumpAndSettle();

    expect(find.text('36 locations'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'B21');
    await tester.pumpAndSettle();
    expect(find.text('TEST'), findsOneWidget);
    await tester.tap(find.text('TEST'));
    await tester.pumpAndSettle();

    expect(find.text('Location on campus'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('TEST'),
      ),
      findsNWidgets(2),
    );
    expect(
      find.text('A map marker is not yet available for this building.'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Directions are not available until a map location and walkable-path connection are verified.',
      ),
      findsOneWidget,
    );
    expect(find.text('Get Directions'), findsNothing);
    expect(find.byTooltip('TEST'), findsNothing);
  });

  testWidgets('public building API failure keeps all saved campus locations',
      (WidgetTester tester) async {
    final buildingApi = BuildingApiService(
      baseUrl: 'http://localhost:8000/api',
      client: MockClient((_) async => http.Response('', 503)),
      campusHeadersProvider: _testCampusHeaders,
    );
    addTearDown(buildingApi.close);

    await tester.pumpWidget(
      UcuSmartPlusApp(
        buildingApi: buildingApi,
        geofenceService: _testGeofenceService(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue as Visitor'));
    await tester.pumpAndSettle();

    expect(find.text('35 locations'), findsOneWidget);
    expect(
      find.textContaining(
        'Online building list unavailable. Showing saved campus locations.',
      ),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField).first, 'Nursing');
    await tester.pumpAndSettle();
    expect(find.text('Nursing Bldg. 1'), findsOneWidget);
  });

  testWidgets('building without saved location text shows a friendly message',
      (WidgetTester tester) async {
    final buildingApi = _buildingApiFor([
      {
        'id': 74,
        'code': 'BLDG-74',
        'name': 'New Campus Building',
        'category': 'Academic',
        'map_x_pct': null,
        'map_y_pct': null,
        'route_node_id': null,
        'route_connection_verified': false,
        'is_active': true,
        'is_public': true,
      },
    ]);
    addTearDown(buildingApi.close);

    await tester.pumpWidget(
      UcuSmartPlusApp(
        buildingApi: buildingApi,
        geofenceService: _testGeofenceService(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue as Visitor'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'BLDG-74');
    await tester.pumpAndSettle();
    await tester.tap(find.text('New Campus Building'));
    await tester.pumpAndSettle();

    expect(
      find.text('Location information is not yet available.'),
      findsOneWidget,
    );
    expect(find.text('Academic'), findsOneWidget);
    expect(find.text('A map marker is not yet available for this building.'),
        findsOneWidget);
  });

  testWidgets('Visitor sees Get Directions only for a verified building route',
      (WidgetTester tester) async {
    final buildingApi = _buildingApiFor([
      {
        'id': 73,
        'code': 'HALL-73',
        'name': 'Mapped Hall',
        'description': 'A hall with a confirmed map location.',
        'category': 'Facility',
        'map_x_pct': 42.5,
        'map_y_pct': 31.25,
        'route_node_id': 'top',
        'route_connection_verified': true,
        'is_active': true,
        'is_public': true,
      },
    ]);
    addTearDown(buildingApi.close);
    final geofenceService = _testGeofenceService();

    await tester.pumpWidget(
      UcuSmartPlusApp(
        buildingApi: buildingApi,
        geofenceService: geofenceService,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue as Visitor'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'HALL-73');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mapped Hall'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'This building is shown at its saved location on the campus map.',
      ),
      findsOneWidget,
    );
    expect(find.text('Get Directions'), findsOneWidget);
  });

  testWidgets('unknown campus graph nodes do not enable building directions',
      (WidgetTester tester) async {
    final buildingApi = _buildingApiFor([
      {
        'id': 75,
        'code': 'BLDG-75',
        'name': 'Unconnected Building',
        'description': 'A building without a graph connection.',
        'category': 'Academic',
        'map_x_pct': 42.5,
        'map_y_pct': 31.25,
        'route_node_id': 'not-in-campus-graph',
        'route_connection_verified': true,
        'is_active': true,
        'is_public': true,
      },
    ]);
    addTearDown(buildingApi.close);

    await tester.pumpWidget(
      UcuSmartPlusApp(
        buildingApi: buildingApi,
        geofenceService: _testGeofenceService(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue as Visitor'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'BLDG-75');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unconnected Building'));
    await tester.pumpAndSettle();

    expect(find.text('Get Directions'), findsNothing);
    expect(
      find.text(
        'Directions are not available until a map location and walkable-path connection are verified.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('building search filters results without selecting them',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1200));
    await _openVisitorCampusMap(tester);

    final searchField = find.byType(TextField).first;
    await tester.enterText(searchField, 'Nursing');
    await tester.pump();

    expect(find.text('Nursing Bldg. 1'), findsOneWidget);
    expect(find.text('Nursing Bldg. 2'), findsOneWidget);
    expect(find.text('Select Start Location'), findsNothing);

    await tester.enterText(searchField, '16');
    await tester.pump();

    expect(find.text('Fitness Gym. 2'), findsOneWidget);
    expect(find.text('Nursing Bldg. 1'), findsNothing);

    await tester.tap(find.text('Fitness Gym. 2'));
    await tester.pump();
    expect(find.text('Select Start Location'), findsNothing);

    await tester.enterText(searchField, 'xyz123');
    await tester.pump();
    expect(find.text('No buildings found'), findsOneWidget);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pump();
    expect(find.text('No buildings found'), findsNothing);
    expect(find.text('Campus Locations'), findsOneWidget);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('numbered marker name appears only while long-pressed',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1200));
    await _openVisitorCampusMap(tester);

    final marker27 = find.text('27').first;
    final firstPress = await tester.startGesture(tester.getCenter(marker27));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Quadrangle'), findsOneWidget);

    await firstPress.up();
    await tester.pump();
    expect(find.text('Quadrangle'), findsNothing);

    final marker8 = find.text('8').first;
    final secondPress = await tester.startGesture(tester.getCenter(marker8));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Nursing Bldg. 2'), findsOneWidget);
    expect(find.text('Quadrangle'), findsNothing);

    await secondPress.up();
    await tester.pump();
    expect(find.text('Nursing Bldg. 2'), findsNothing);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('cancelling a marker long-press hides its name',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1200));
    await _openVisitorCampusMap(tester);

    final marker27 = find.text('27').first;
    final press = await tester.startGesture(tester.getCenter(marker27));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Quadrangle'), findsOneWidget);

    await press.cancel();
    await tester.pump();
    expect(find.text('Quadrangle'), findsNothing);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('numbered marker tooltip stays compact on mobile screens',
      (WidgetTester tester) async {
    var isInitialScreen = true;
    for (final screenSize in [const Size(360, 740), const Size(430, 900)]) {
      await tester.binding.setSurfaceSize(screenSize);
      if (isInitialScreen) {
        await _openVisitorCampusMap(tester);
        isInitialScreen = false;
      } else {
        await tester.pumpAndSettle();
      }

      for (final markerCase in [
        (number: '8', name: 'Nursing Bldg. 2'),
        (number: '32', name: 'Entrep. & Law Bldg.'),
      ]) {
        final marker = find.text(markerCase.number).first;
        final press = await tester.startGesture(tester.getCenter(marker));
        await tester.pump(const Duration(milliseconds: 600));

        expect(find.text(markerCase.name), findsOneWidget);
        final tooltipRect = tester.getRect(
          find.byKey(const ValueKey('numbered-marker-name-tooltip')),
        );
        expect(tooltipRect.width, lessThanOrEqualTo(176));
        expect(tooltipRect.height, lessThanOrEqualTo(44));
        expect(tooltipRect.left, greaterThanOrEqualTo(0));
        expect(tooltipRect.right, lessThanOrEqualTo(screenSize.width));

        await press.up();
        await tester.pump();
        expect(find.text(markerCase.name), findsNothing);
      }
    }

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('numbered marker tap still opens location selection',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1200));
    await _openVisitorCampusMap(tester);

    await tester.tap(find.text('27').first);
    await tester.pumpAndSettle();

    expect(find.text('Select Start Location'), findsOneWidget);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('location picker search is independent of main search',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1200));
    await _openVisitorCampusMap(tester);

    await tester.tap(find.text('Start Location'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '32');
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField).last).controller!.text,
      '32',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(InkWell).last);
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      isEmpty,
    );

    await tester.tap(find.text('Destination'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '13');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(InkWell).last);
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      isEmpty,
    );
    expect(find.text('Find Route'), findsOneWidget);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('hamburger displays and dismisses the coming soon dialog',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1200));
    await _openVisitorCampusMap(tester);

    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Coming Soon'), findsOneWidget);
    expect(
      find.text('More features will be available here in a future update.'),
      findsOneWidget,
    );
    expect(find.text('OK'), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Coming Soon'), findsNothing);

    await tester.binding.setSurfaceSize(null);
  });
}

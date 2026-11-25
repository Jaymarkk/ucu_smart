import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ucu_smart_plus/services/campus_geofence_service.dart';
import 'package:ucu_smart_plus/services/campus_map_development_policy.dart';
import 'package:ucu_smart_plus/services/student_api_service.dart';
import 'package:ucu_smart_plus/services/student_auth_service.dart';
import 'package:ucu_smart_plus/widgets/campus_access_gate.dart';

import 'support/fake_campus_location_provider.dart';

class _MemoryStudentTokenStore implements StudentTokenStore {
  @override
  Future<String?> readToken() async => 'student-token';

  @override
  Future<void> writeToken(String token) async {}

  @override
  Future<void> deleteToken() async {}
}

class _AuthenticatedStudentAuthService extends StudentAuthService {
  _AuthenticatedStudentAuthService()
      : super(
          api: StudentApiService(
            baseUrl: 'http://localhost:8000/api',
            client: MockClient((_) async => http.Response('', 401)),
          ),
          tokenStore: _MemoryStudentTokenStore(),
        );

  @override
  bool get isStudentAuthenticated => true;
}

void main() {
  testWidgets('authenticated Student routes bypass the campus gate',
      (tester) async {
    final provider = FakeCampusLocationProvider()..supported = false;
    final service = CampusGeofenceService(locationProvider: provider);
    final auth = _AuthenticatedStudentAuthService();
    final routeName = ValueNotifier<String?>('/student-dashboard');
    addTearDown(service.dispose);
    addTearDown(auth.dispose);
    addTearDown(routeName.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: CampusAccessGate(
          geofenceService: service,
          studentAuthService: auth,
          currentRouteName: routeName,
          child: const Scaffold(body: Text('Student Portal')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Student Portal'), findsOneWidget);
    expect(find.text('Campus Access Restricted'), findsNothing);
  });

  testWidgets('Visitor mode is limited to allowed Campus routes',
      (tester) async {
    final provider = FakeCampusLocationProvider()..supported = false;
    final service = CampusGeofenceService(locationProvider: provider);
    final routeName = ValueNotifier<String?>('/student-dashboard');
    addTearDown(service.dispose);
    addTearDown(routeName.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: CampusAccessGate(
          geofenceService: service,
          isVisitorMode: true,
          currentRouteName: routeName,
          child: const Scaffold(body: Text('Protected content')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Visitor mode is limited to the Campus Map.'),
        findsOneWidget);
    expect(find.text('Sign in with a Student account to access Student pages.'),
        findsOneWidget);

    routeName.value = '/campus-map';
    await tester.pumpAndSettle();
    if (campusMapDevelopmentBypassEnabled) {
      expect(find.text('Protected content'), findsOneWidget);
    } else {
      expect(find.text('Campus Access Restricted'), findsOneWidget);
    }
  });

  testWidgets('bootstrap login route has no Admin option',
      (tester) async {
    final provider = FakeCampusLocationProvider()..supported = false;
    final service = CampusGeofenceService(locationProvider: provider);
    final routeName = ValueNotifier<String?>('/login');
    addTearDown(service.dispose);
    addTearDown(routeName.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: CampusAccessGate(
          geofenceService: service,
          currentRouteName: routeName,
          child: const Scaffold(body: Text('Student Login')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Student Login'), findsOneWidget);
    expect(find.text('Admin Login'), findsNothing);
    expect(find.text('Admin sign-in'), findsNothing);
  });
}

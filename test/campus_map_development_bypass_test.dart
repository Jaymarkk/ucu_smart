import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ucu_smart_plus/main.dart';
import 'package:ucu_smart_plus/services/building_api_service.dart';
import 'package:ucu_smart_plus/services/campus_geofence_service.dart';
import 'package:ucu_smart_plus/services/campus_map_development_policy.dart';
import 'package:ucu_smart_plus/services/student_api_service.dart';
import 'package:ucu_smart_plus/services/student_auth_service.dart';
import 'package:ucu_smart_plus/widgets/campus_access_gate.dart';

import 'support/fake_campus_location_provider.dart';

class _MemoryStudentTokenStore implements StudentTokenStore {
  @override
  Future<String?> readToken() async => null;

  @override
  Future<void> writeToken(String token) async {}

  @override
  Future<void> deleteToken() async {}
}

void main() {
  group(
    'development bypass enabled',
    skip: !campusMapDevelopmentBypassEnabled,
    () {
      testWidgets('Visitor entry opens Campus Map without location checks',
          (tester) async {
        final provider = FakeCampusLocationProvider()..supported = false;
        final geofenceService =
            CampusGeofenceService(locationProvider: provider);
        final buildingApi = BuildingApiService(
          baseUrl: 'http://localhost:8000/api',
          campusHeadersProvider: () => null,
          client: MockClient((_) async => http.Response(
                jsonEncode({'data': <Object>[]}),
                200,
              )),
        );
        final studentApi = StudentApiService(
          baseUrl: 'http://localhost:8000/api',
          client: MockClient((_) async => http.Response('', 401)),
        );
        final studentAuth = StudentAuthService(
          api: studentApi,
          tokenStore: _MemoryStudentTokenStore(),
        );
        addTearDown(geofenceService.dispose);
        addTearDown(buildingApi.close);
        addTearDown(studentApi.close);
        addTearDown(studentAuth.dispose);

        await tester.pumpWidget(
          UcuSmartPlusApp(
            geofenceService: geofenceService,
            buildingApi: buildingApi,
            studentAuthService: studentAuth,
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue as Visitor'));
        await tester.pumpAndSettle();

        expect(find.byType(CampusMapPage), findsOneWidget);
        expect(find.text('Campus Access Restricted'), findsNothing);
        expect(provider.positionRequests, 0);

        await tester.pumpWidget(const SizedBox.shrink());
      });

      testWidgets('Visitor mode still cannot access Student pages',
          (tester) async {
        final service = CampusGeofenceService(
          locationProvider: FakeCampusLocationProvider()..supported = false,
        );
        final routeName = ValueNotifier<String?>('/student-dashboard');
        addTearDown(service.dispose);
        addTearDown(routeName.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: CampusAccessGate(
              geofenceService: service,
              isVisitorMode: true,
              currentRouteName: routeName,
              child: const Scaffold(body: Text('Protected page')),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Visitor mode is limited to the Campus Map.'),
            findsOneWidget);

        routeName.value = '/unknown';
        await tester.pumpAndSettle();
        expect(find.text('Visitor mode is limited to the Campus Map.'),
            findsOneWidget);
        expect(find.text('Protected page'), findsNothing);

        await tester.pumpWidget(const SizedBox.shrink());
      });

      testWidgets('non-Visitor protected routes still require geofence access',
          (tester) async {
        final service = CampusGeofenceService(
          boundary: syntheticTestCampusBoundary(),
          locationProvider: FakeCampusLocationProvider()
            ..fix = CampusLocationFix(
              point: const GeoPoint(2, 0.5),
              accuracyMeters: 5,
              timestamp: DateTime.utc(2026, 1, 1),
            ),
          clock: () => DateTime.utc(2026, 1, 1),
        );
        final routeName = ValueNotifier<String?>('/unknown');
        addTearDown(service.dispose);
        addTearDown(routeName.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: CampusAccessGate(
              geofenceService: service,
              currentRouteName: routeName,
              child: const Scaffold(body: Text('Protected page')),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(service.state.status, CampusAccessStatus.outside);
        expect(find.text('Campus Access Restricted'), findsOneWidget);
        expect(find.text('Protected page'), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
      });
    },
  );

  group(
    'development bypass disabled',
    skip: campusMapDevelopmentBypassEnabled,
    () {
      testWidgets('Visitor remains subject to normal geofence policy',
          (tester) async {
        final provider = FakeCampusLocationProvider()
          ..fix = CampusLocationFix(
            point: const GeoPoint(2, 0.5),
            accuracyMeters: 5,
            timestamp: DateTime.utc(2026, 1, 1),
          );
        final service = CampusGeofenceService(
          boundary: syntheticTestCampusBoundary(),
          locationProvider: provider,
          clock: () => DateTime.utc(2026, 1, 1),
        );
        final routeName = ValueNotifier<String?>('/campus-map');
        addTearDown(service.dispose);
        addTearDown(routeName.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: CampusAccessGate(
              geofenceService: service,
              isVisitorMode: true,
              currentRouteName: routeName,
              child: const Scaffold(body: Text('Campus map')),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(service.state.status, CampusAccessStatus.outside);
        expect(find.text('Campus Access Restricted'), findsOneWidget);
        expect(find.text('Campus map'), findsOneWidget);
        expect(provider.positionRequests, 1);

        await tester.pumpWidget(const SizedBox.shrink());
      });
    },
  );
}

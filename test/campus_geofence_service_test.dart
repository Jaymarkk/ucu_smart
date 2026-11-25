import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ucu_smart_plus/services/campus_geofence_service.dart';

import 'support/fake_campus_location_provider.dart';

void main() {
  group('CampusBoundary', () {
    final boundary = syntheticTestCampusBoundary();

    test('interprets coordinate pairs as latitude then longitude', () {
      final asymmetricBoundary = CampusBoundary.fromJson(
        '[[10,20],[10,23],[11,23],[11,20]]',
      );

      expect(asymmetricBoundary.isValid, isTrue);
      expect(
        asymmetricBoundary.relation(const GeoPoint(10.5, 21.5)),
        CampusBoundaryRelation.inside,
      );
      expect(
        asymmetricBoundary.relation(const GeoPoint(21.5, 10.5)),
        CampusBoundaryRelation.outside,
      );
    });

    test('accepts a polygon with an explicit closing coordinate', () {
      final closedBoundary = CampusBoundary.fromJson(
        '[[0,0],[0,1],[1,1],[1,0],[0,0]]',
      );

      expect(closedBoundary.isValid, isTrue);
      expect(closedBoundary.points, hasLength(4));
    });

    test('classifies points inside and outside the polygon', () {
      expect(
        boundary.relation(const GeoPoint(0.5, 0.5)),
        CampusBoundaryRelation.inside,
      );
      expect(
        boundary.relation(const GeoPoint(2, 0.5)),
        CampusBoundaryRelation.outside,
      );
    });

    test('measures shortest distance to the nearest polygon edge', () {
      expect(
        boundary.distanceToBoundaryMeters(const GeoPoint(0.5, 0.5)),
        closeTo(55658, 1),
      );
      expect(
        () => boundary.distanceToBoundaryMeters(const GeoPoint(91, 0)),
        throwsArgumentError,
      );
    });

    test('classifies points on the perimeter as boundary', () {
      expect(
        boundary.relation(const GeoPoint(0, 0.5)),
        CampusBoundaryRelation.boundary,
      );
      expect(
        boundary.relation(const GeoPoint(0, 0)),
        CampusBoundaryRelation.boundary,
      );
    });

    test('rejects missing, malformed, out-of-range, and degenerate polygons',
        () {
      final unconfigured = CampusBoundary.fromJson('');
      expect(unconfigured.isConfigured, isFalse);
      expect(unconfigured.isValid, isFalse);
      expect(
        () => unconfigured.relation(const GeoPoint(0.5, 0.5)),
        throwsArgumentError,
      );
      expect(
        () => unconfigured.distanceToBoundaryMeters(const GeoPoint(0.5, 0.5)),
        throwsArgumentError,
      );
      expect(CampusBoundary.fromJson('not-json').isValid, isFalse);
      expect(CampusBoundary.fromJson('[[0,0],[1,1]]').isValid, isFalse);
      expect(
        CampusBoundary.fromJson('[[0,0],[0,1],[0,2]]').isValid,
        isFalse,
      );
      expect(
        CampusBoundary.fromJson('[[0,0],[2,2],[0,2],[2,0],[3,0]]').isValid,
        isFalse,
      );
      expect(
        CampusBoundary.fromJson('[[0,0],[0,181],[1,1]]').isValid,
        isFalse,
      );
      expect(
        CampusBoundary.fromJson('[[0,0],[0,1],[1,1],[1,0],[1,0]]').isValid,
        isFalse,
      );
      expect(
        CampusBoundary.fromJson('[[0,0],[0,2],[0,1],[1,1],[1,0]]').isValid,
        isFalse,
      );
      expect(
        CampusBoundary.fromJson('[[0,0],[0,1],[1,1],[1,0],[0,0],[0,0]]')
            .isValid,
        isFalse,
      );
    });
  });

  group('CampusGeofenceService access transitions', () {
    late FakeCampusLocationProvider provider;
    late CampusGeofenceService service;
    final now = DateTime.utc(2026, 1, 1);

    setUp(() {
      provider = FakeCampusLocationProvider();
      service = testCampusGeofenceService(
        provider: provider,
        clock: () => now,
      );
    });

    tearDown(() => service.dispose());

    test('coalesces overlapping refreshes into one location request', () async {
      final pendingFix = Completer<CampusLocationFix>();
      provider.pendingFix = pendingFix.future;

      final firstRefresh = service.refresh();
      final secondRefresh = service.refresh();
      await Future<void>.delayed(Duration.zero);

      expect(provider.positionRequests, 1);
      pendingFix.complete(provider.fix);
      await Future.wait([firstRefresh, secondRefresh]);

      expect(service.state.status, CampusAccessStatus.granted);
    });

    test('forced verification obtains a new fix after an active check',
        () async {
      final pendingFix = Completer<CampusLocationFix>();
      provider.pendingFix = pendingFix.future;

      final firstRefresh = service.refresh();
      await Future<void>.delayed(Duration.zero);
      final forcedRefresh = service.refresh(forceFresh: true);

      expect(provider.positionRequests, 1);
      pendingFix.complete(provider.fix);
      await Future.wait([firstRefresh, forcedRefresh]);

      expect(provider.positionRequests, 2);
      expect(service.state.status, CampusAccessStatus.granted);
    });

    test('grants access with a fresh, accurate, safely-inside fix', () async {
      await service.refresh();

      expect(service.state.status, CampusAccessStatus.granted);
      expect(service.currentAccessHeaders, contains('X-Campus-Latitude'));
    });

    test('captures diagnostics from the exact fix rejected for accuracy',
        () async {
      final fix = CampusLocationFix(
        point: const GeoPoint(0.5, 0.5),
        accuracyMeters: 45,
        timestamp: now,
      );
      provider.fix = fix;

      await service.refresh();

      final diagnostic = service.lastGpsDiagnostic!;
      expect(identical(diagnostic.fix, fix), isTrue);
      expect(diagnostic.fixAge, Duration.zero);
      expect(diagnostic.pointInPolygon, CampusBoundaryRelation.inside);
      expect(
        diagnostic.nearestBoundaryDistanceMeters,
        service.boundary.distanceToBoundaryMeters(fix.point),
      );
      expect(diagnostic.requiredClearanceMeters, 60);
      expect(diagnostic.result.status, CampusAccessStatus.inaccurate);
      expect(service.state.status, CampusAccessStatus.inaccurate);
    });

    test('captures the edge distance and clearance for uncertain fixes',
        () async {
      final fix = CampusLocationFix(
        point: const GeoPoint(0.0001, 0.5),
        accuracyMeters: 5,
        timestamp: now,
      );
      provider.fix = fix;

      await service.refresh();

      final diagnostic = service.lastGpsDiagnostic!;
      expect(diagnostic.pointInPolygon, CampusBoundaryRelation.inside);
      expect(
        diagnostic.nearestBoundaryDistanceMeters,
        service.boundary.distanceToBoundaryMeters(fix.point),
      );
      expect(diagnostic.requiredClearanceMeters, 20);
      expect(diagnostic.result.status, CampusAccessStatus.boundaryUncertain);
    });

    test('clears a previous fix diagnostic when a new attempt gets no fix',
        () async {
      await service.refresh();
      expect(service.lastGpsDiagnostic, isNotNull);

      provider.locationEnabled = false;
      await service.refresh();

      expect(service.lastGpsDiagnostic, isNull);
    });

    test('revokes access outside and restores it after a verified return',
        () async {
      await service.refresh();
      provider.fix = CampusLocationFix(
        point: const GeoPoint(2, 0.5),
        accuracyMeters: 5,
        timestamp: now,
      );
      await service.refresh();
      expect(service.state.status, CampusAccessStatus.outside);
      expect(service.currentAccessHeaders, isNull);

      provider.fix = CampusLocationFix(
        point: const GeoPoint(0.5, 0.5),
        accuracyMeters: 5,
        timestamp: now,
      );
      await service.refresh();
      expect(service.state.status, CampusAccessStatus.granted);
    });

    test('keeps boundary-uncertain fixes restricted', () async {
      provider.fix = CampusLocationFix(
        point: const GeoPoint(0.0001, 0.5),
        accuracyMeters: 5,
        timestamp: now,
      );

      await service.refresh();

      expect(service.state.status, CampusAccessStatus.boundaryUncertain);
      expect(service.currentAccessHeaders, isNull);
    });

    test('applies the accuracy plus buffer clearance at the perimeter',
        () async {
      provider.fix = CampusLocationFix(
        point: const GeoPoint(0.00018, 0.5),
        accuracyMeters: 5,
        timestamp: now,
      );

      await service.refresh();

      expect(service.state.status, CampusAccessStatus.granted);
    });

    test('rejects stale and inaccurate fixes without calling them outside',
        () async {
      provider.fix = CampusLocationFix(
        point: const GeoPoint(0.5, 0.5),
        accuracyMeters: 5,
        timestamp: now.subtract(const Duration(seconds: 121)),
      );
      await service.refresh();
      expect(service.state.status, CampusAccessStatus.stale);

      provider.fix = CampusLocationFix(
        point: const GeoPoint(0.5, 0.5),
        accuracyMeters: 31,
        timestamp: now,
      );
      await service.refresh();
      expect(service.state.status, CampusAccessStatus.inaccurate);
    });

    test('rejects future-dated fixes', () async {
      provider.fix = CampusLocationFix(
        point: const GeoPoint(0.5, 0.5),
        accuracyMeters: 5,
        timestamp: now.add(const Duration(seconds: 1)),
      );

      await service.refresh();

      expect(service.state.status, CampusAccessStatus.stale);
      expect(service.currentAccessHeaders, isNull);
    });

    test('handles denied permissions and requests a denied permission once',
        () async {
      provider.permission = CampusPermission.denied;

      await service.refresh();

      expect(provider.permissionRequests, 1);
      expect(service.state.status, CampusAccessStatus.permissionDenied);
    });

    test('revokes a previous grant when a later location check fails',
        () async {
      await service.refresh();
      expect(service.currentAccessHeaders, isNotNull);

      provider.locationEnabled = false;
      await service.refresh();

      expect(
        service.state.status,
        CampusAccessStatus.locationServicesDisabled,
      );
      expect(service.currentAccessHeaders, isNull);
    });

    test('handles permanently denied, disabled, unsupported, and unconfigured',
        () async {
      provider.permission = CampusPermission.deniedForever;
      await service.refresh();
      expect(service.state.status, CampusAccessStatus.permissionDeniedForever);

      provider.permission = CampusPermission.whileInUse;
      provider.locationEnabled = false;
      await service.refresh();
      expect(service.state.status, CampusAccessStatus.locationServicesDisabled);

      provider.locationEnabled = true;
      provider.supported = false;
      await service.refresh();
      expect(service.state.status, CampusAccessStatus.unsupported);

      provider.supported = true;
      final unconfigured = CampusGeofenceService(
        locationProvider: provider,
        clock: () => now,
      );
      addTearDown(unconfigured.dispose);
      await unconfigured.refresh();
      expect(unconfigured.state.status, CampusAccessStatus.unconfigured);
    });

    test('does not allow an expired verified fix to remain accessible',
        () async {
      var clockNow = now;
      final expiringService = testCampusGeofenceService(
        provider: provider,
        clock: () => clockNow,
      );
      addTearDown(expiringService.dispose);
      await expiringService.refresh();
      expect(expiringService.state.isGranted, isTrue);

      clockNow = now.add(const Duration(seconds: 121));
      expect(expiringService.state.status, CampusAccessStatus.stale);
      expect(expiringService.currentAccessHeaders, isNull);
    });

    test('fails closed for invalid configured accuracy thresholds', () async {
      final invalidPolicyService = CampusGeofenceService(
        boundary: syntheticTestCampusBoundary(),
        locationProvider: provider,
        clock: () => now,
        maxAccuracyMeters: 0,
      );
      addTearDown(invalidPolicyService.dispose);

      await invalidPolicyService.refresh();

      expect(
        invalidPolicyService.state.status,
        CampusAccessStatus.invalidBoundary,
      );
    });
  });
}

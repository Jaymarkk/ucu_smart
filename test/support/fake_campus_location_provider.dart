import 'dart:async';

import 'package:ucu_smart_plus/services/campus_geofence_service.dart';

class FakeCampusLocationProvider implements CampusLocationProvider {
  CampusPermission permission = CampusPermission.whileInUse;
  CampusLocationFix fix = CampusLocationFix(
    point: const GeoPoint(0.5, 0.5),
    accuracyMeters: 5,
    timestamp: DateTime.utc(2026, 1, 1),
  );
  bool locationEnabled = true;
  bool supported = true;
  Future<CampusLocationFix>? pendingFix;
  int positionRequests = 0;
  int permissionRequests = 0;
  int appSettingsOpened = 0;
  int locationSettingsOpened = 0;

  @override
  bool get isSupported => supported;

  @override
  Future<CampusPermission> checkPermission() async => permission;

  @override
  Future<CampusLocationFix> getCurrentPosition() {
    positionRequests++;
    return pendingFix ?? Future.value(fix);
  }

  @override
  Future<bool> isLocationServiceEnabled() async => locationEnabled;

  @override
  Future<void> openAppSettings() async {
    appSettingsOpened++;
  }

  @override
  Future<void> openLocationSettings() async {
    locationSettingsOpened++;
  }

  @override
  Future<CampusPermission> requestPermission() async {
    permissionRequests++;
    return permission;
  }
}

CampusBoundary syntheticTestCampusBoundary() => CampusBoundary.fromJson(
      '[[0,0],[0,1],[1,1],[1,0]]',
    );

CampusGeofenceService testCampusGeofenceService({
  FakeCampusLocationProvider? provider,
  DateTime Function()? clock,
}) =>
    CampusGeofenceService(
      boundary: syntheticTestCampusBoundary(),
      locationProvider: provider ?? FakeCampusLocationProvider(),
      clock: clock ?? () => DateTime.utc(2026, 1, 1),
    );

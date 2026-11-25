import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ucu_smart_plus/services/campus_geofence_service.dart';

import 'support/fake_campus_location_provider.dart';

void main() {
  test('service consumes the compile-time boundary define', () async {
    const compiledBoundary = String.fromEnvironment(
      'UCU_CAMPUS_BOUNDARY_JSON',
    );
    final service = CampusGeofenceService(
      locationProvider: FakeCampusLocationProvider(),
      clock: () => DateTime.utc(2026, 1, 1),
    );
    addTearDown(service.dispose);

    await service.refresh();

    if (compiledBoundary.isEmpty) {
      expect(service.state.status, CampusAccessStatus.unconfigured);
    } else {
      final config = jsonDecode(
        File('config/ucu_campus_boundary.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      expect(compiledBoundary, config['UCU_CAMPUS_BOUNDARY_JSON']);
      expect(service.state.status, CampusAccessStatus.outside);
    }
  });

  test('configured UCU boundary keeps the supplied 37-point order', () {
    final config = jsonDecode(
      File('config/ucu_campus_boundary.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final boundary = CampusBoundary.fromJson(
      config['UCU_CAMPUS_BOUNDARY_JSON'] as String,
    );
    final orderedPoints = boundary.points
        .map((point) => [point.latitude, point.longitude])
        .toList();

    expect(boundary.isConfigured, isTrue);
    expect(boundary.isValid, isTrue);
    expect(orderedPoints, hasLength(37));
    expect(jsonEncode(orderedPoints), config['UCU_CAMPUS_BOUNDARY_JSON']);
  });
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/campus_geofence_service.dart';

bool shouldShowCampusGpsDiagnosticPanel({
  required bool isDebugBuild,
  required bool optedIn,
}) =>
    isDebugBuild && optedIn;

class CampusGpsDiagnosticPanel extends StatelessWidget {
  const CampusGpsDiagnosticPanel({
    required this.diagnostic,
    required this.currentResult,
    super.key,
  });

  final CampusGpsDiagnostic? diagnostic;
  final CampusAccessState currentResult;

  String _meters(double? value) =>
      value == null ? 'Unavailable' : '${value.toStringAsFixed(2)} m';

  String _relation(CampusBoundaryRelation? relation) => switch (relation) {
        CampusBoundaryRelation.inside => 'Inside',
        CampusBoundaryRelation.outside => 'Outside',
        CampusBoundaryRelation.boundary => 'On boundary',
        null => 'Unavailable',
      };

  String _status(CampusAccessStatus status) => switch (status) {
        CampusAccessStatus.checking => 'Checking',
        CampusAccessStatus.granted => 'Verified',
        CampusAccessStatus.unconfigured => 'Boundary unconfigured',
        CampusAccessStatus.invalidBoundary => 'Invalid configuration',
        CampusAccessStatus.outside => 'Outside campus',
        CampusAccessStatus.boundaryUncertain => 'Boundary location uncertain',
        CampusAccessStatus.permissionDenied => 'Permission denied',
        CampusAccessStatus.permissionDeniedForever => 'Permission blocked',
        CampusAccessStatus.locationServicesDisabled => 'Location services off',
        CampusAccessStatus.unsupported => 'Unsupported',
        CampusAccessStatus.inaccurate => 'Accuracy insufficient',
        CampusAccessStatus.stale => 'Stale location',
        CampusAccessStatus.unavailable => 'Location unavailable',
      };

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    final captured = diagnostic;
    final result = captured?.result ?? currentResult;

    return Card(
      key: const ValueKey('campus-gps-diagnostic-panel'),
      color: const Color(0xFFF4F7FB),
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'DEBUG-ONLY GPS DIAGNOSTICS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Local to this screen only. Values are not saved or uploaded.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            if (captured == null)
              const Text('No GPS fix was captured by the latest verification.')
            else ...[
              _DiagnosticRow(
                label: 'Latitude',
                value: captured.fix.point.latitude.toStringAsFixed(7),
              ),
              _DiagnosticRow(
                label: 'Longitude',
                value: captured.fix.point.longitude.toStringAsFixed(7),
              ),
              _DiagnosticRow(
                label: 'Accuracy',
                value: _meters(captured.fix.accuracyMeters),
              ),
              _DiagnosticRow(
                label: 'Fix age',
                value:
                    '${(captured.fixAge.inMilliseconds / Duration.millisecondsPerSecond).toStringAsFixed(1)} seconds',
              ),
              _DiagnosticRow(
                label: 'Point in polygon',
                value: _relation(captured.pointInPolygon),
              ),
              _DiagnosticRow(
                label: 'Nearest polygon edge',
                value: _meters(captured.nearestBoundaryDistanceMeters),
              ),
              _DiagnosticRow(
                label: 'Required clearance (accuracy + buffer)',
                value: _meters(captured.requiredClearanceMeters),
              ),
            ],
            const Divider(height: 20),
            _DiagnosticRow(
              label: 'Verification result',
              value: _status(result.status),
            ),
            Text(
              result.message,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _DiagnosticRow extends StatelessWidget {
  const _DiagnosticRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(label)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
}

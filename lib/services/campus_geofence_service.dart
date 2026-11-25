import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

@immutable
class GeoPoint {
  const GeoPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  bool get isValid =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;
}

@immutable
class CampusLocationFix {
  const CampusLocationFix({
    required this.point,
    required this.accuracyMeters,
    required this.timestamp,
  });

  final GeoPoint point;
  final double accuracyMeters;
  final DateTime timestamp;
}

enum CampusBoundaryRelation { inside, outside, boundary }

class CampusBoundary {
  CampusBoundary._(this.points,
      {required this.isConfigured, this.isValid = false});

  factory CampusBoundary.fromJson(String value) {
    if (value.trim().isEmpty) {
      return CampusBoundary._(const [], isConfigured: false);
    }

    try {
      final decoded = jsonDecode(value);
      if (decoded is! List) {
        return CampusBoundary._(
          const [],
          isConfigured: true,
          isValid: false,
        );
      }

      final points = <GeoPoint>[];
      for (final item in decoded) {
        if (item is! List ||
            item.length != 2 ||
            item[0] is! num ||
            item[1] is! num) {
          return CampusBoundary._(
            const [],
            isConfigured: true,
            isValid: false,
          );
        }
        final point = GeoPoint(
          (item[0] as num).toDouble(),
          (item[1] as num).toDouble(),
        );
        if (!point.isValid) {
          return CampusBoundary._(
            const [],
            isConfigured: true,
            isValid: false,
          );
        }
        points.add(point);
      }

      if (points.length > 1 && _samePoint(points.first, points.last)) {
        points.removeLast();
      }
      final uniquePoints =
          points.map((point) => '${point.latitude},${point.longitude}').toSet();
      if (points.length < 3 ||
          uniquePoints.length < 3 ||
          _polygonArea(points).abs() < 1e-12 ||
          _hasInvalidAdjacentEdges(points) ||
          _hasSelfIntersection(points)) {
        return CampusBoundary._(
          const [],
          isConfigured: true,
          isValid: false,
        );
      }
      return CampusBoundary._(
        List.unmodifiable(points),
        isConfigured: true,
        isValid: true,
      );
    } on FormatException {
      return CampusBoundary._(
        const [],
        isConfigured: true,
        isValid: false,
      );
    }
  }

  final List<GeoPoint> points;
  final bool isConfigured;
  final bool isValid;

  CampusBoundaryRelation relation(GeoPoint point) {
    if (!isConfigured || !isValid || !point.isValid) {
      throw ArgumentError('A valid polygon and geographic point are required.');
    }
    if (distanceToBoundaryMeters(point) <= 0.5) {
      return CampusBoundaryRelation.boundary;
    }

    var inside = false;
    for (var i = 0, j = points.length - 1; i < points.length; j = i++) {
      final first = points[i];
      final second = points[j];
      final crossesLatitude = (first.latitude > point.latitude) !=
          (second.latitude > point.latitude);
      if (crossesLatitude) {
        final crossingLongitude = (second.longitude - first.longitude) *
                (point.latitude - first.latitude) /
                (second.latitude - first.latitude) +
            first.longitude;
        if (point.longitude < crossingLongitude) inside = !inside;
      }
    }
    return inside
        ? CampusBoundaryRelation.inside
        : CampusBoundaryRelation.outside;
  }

  double distanceToBoundaryMeters(GeoPoint point) {
    if (!isConfigured || !isValid || !point.isValid) {
      throw ArgumentError('A valid polygon and geographic point are required.');
    }
    final longitudeScale = 111320 * _cosDegrees(point.latitude);
    var minimumDistance = double.infinity;
    for (var index = 0; index < points.length; index++) {
      final first = points[index];
      final second = points[(index + 1) % points.length];
      final startX = (first.longitude - point.longitude) * longitudeScale;
      final startY = (first.latitude - point.latitude) * 111320;
      final endX = (second.longitude - point.longitude) * longitudeScale;
      final endY = (second.latitude - point.latitude) * 111320;
      final segmentX = endX - startX;
      final segmentY = endY - startY;
      final segmentLengthSquared = segmentX * segmentX + segmentY * segmentY;
      final projection = segmentLengthSquared == 0
          ? 0.0
          : (-(startX * segmentX + startY * segmentY) / segmentLengthSquared)
              .clamp(0.0, 1.0)
              .toDouble();
      final nearestX = startX + projection * segmentX;
      final nearestY = startY + projection * segmentY;
      final distance = math.sqrt(nearestX * nearestX + nearestY * nearestY);
      if (distance < minimumDistance) minimumDistance = distance;
    }
    return minimumDistance;
  }

  static bool _samePoint(GeoPoint first, GeoPoint second) =>
      first.latitude == second.latitude && first.longitude == second.longitude;

  static bool _hasInvalidAdjacentEdges(List<GeoPoint> points) {
    for (var index = 0; index < points.length; index++) {
      final previous = points[(index - 1 + points.length) % points.length];
      final current = points[index];
      final next = points[(index + 1) % points.length];
      if (_samePoint(current, next)) return true;
      if (_orientation(previous, current, next).abs() <= 1e-12 &&
          !_onSegment(previous, next, current)) {
        return true;
      }
    }
    return false;
  }

  static double _polygonArea(List<GeoPoint> points) {
    var area = 0.0;
    for (var index = 0; index < points.length; index++) {
      final next = points[(index + 1) % points.length];
      area += points[index].longitude * next.latitude -
          next.longitude * points[index].latitude;
    }
    return area / 2;
  }

  static bool _hasSelfIntersection(List<GeoPoint> points) {
    for (var first = 0; first < points.length; first++) {
      final firstNext = (first + 1) % points.length;
      for (var second = first + 1; second < points.length; second++) {
        final secondNext = (second + 1) % points.length;
        if (first == second || firstNext == second || secondNext == first) {
          continue;
        }
        if (_segmentsIntersect(
          points[first],
          points[firstNext],
          points[second],
          points[secondNext],
        )) {
          return true;
        }
      }
    }
    return false;
  }

  static bool _segmentsIntersect(
    GeoPoint first,
    GeoPoint second,
    GeoPoint third,
    GeoPoint fourth,
  ) {
    final a = _orientation(first, second, third);
    final b = _orientation(first, second, fourth);
    final c = _orientation(third, fourth, first);
    final d = _orientation(third, fourth, second);
    if (a * b < 0 && c * d < 0) return true;

    return (a.abs() <= 1e-12 && _onSegment(first, second, third)) ||
        (b.abs() <= 1e-12 && _onSegment(first, second, fourth)) ||
        (c.abs() <= 1e-12 && _onSegment(third, fourth, first)) ||
        (d.abs() <= 1e-12 && _onSegment(third, fourth, second));
  }

  static double _orientation(GeoPoint first, GeoPoint second, GeoPoint third) {
    return (second.longitude - first.longitude) *
            (third.latitude - first.latitude) -
        (second.latitude - first.latitude) *
            (third.longitude - first.longitude);
  }

  static bool _onSegment(GeoPoint first, GeoPoint second, GeoPoint point) =>
      point.longitude >= math.min(first.longitude, second.longitude) - 1e-12 &&
      point.longitude <= math.max(first.longitude, second.longitude) + 1e-12 &&
      point.latitude >= math.min(first.latitude, second.latitude) - 1e-12 &&
      point.latitude <= math.max(first.latitude, second.latitude) + 1e-12;

  static double _cosDegrees(double value) => math.cos(value * math.pi / 180);
}

enum CampusPermission { denied, deniedForever, whileInUse, always, unknown }

abstract interface class CampusLocationProvider {
  bool get isSupported;
  Future<bool> isLocationServiceEnabled();
  Future<CampusPermission> checkPermission();
  Future<CampusPermission> requestPermission();
  Future<CampusLocationFix> getCurrentPosition();
  Future<void> openAppSettings();
  Future<void> openLocationSettings();
}

class GeolocatorCampusLocationProvider implements CampusLocationProvider {
  @override
  bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Future<bool> isLocationServiceEnabled() =>
      Geolocator.isLocationServiceEnabled();

  @override
  Future<CampusPermission> checkPermission() async =>
      _mapPermission(await Geolocator.checkPermission());

  @override
  Future<CampusPermission> requestPermission() async =>
      _mapPermission(await Geolocator.requestPermission());

  @override
  Future<CampusLocationFix> getCurrentPosition() async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
    return CampusLocationFix(
      point: GeoPoint(position.latitude, position.longitude),
      accuracyMeters: position.accuracy,
      timestamp: position.timestamp,
    );
  }

  @override
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  @override
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  CampusPermission _mapPermission(LocationPermission permission) =>
      switch (permission) {
        LocationPermission.denied => CampusPermission.denied,
        LocationPermission.deniedForever => CampusPermission.deniedForever,
        LocationPermission.whileInUse => CampusPermission.whileInUse,
        LocationPermission.always => CampusPermission.always,
        LocationPermission.unableToDetermine => CampusPermission.unknown,
      };
}

enum CampusAccessStatus {
  checking,
  granted,
  unconfigured,
  invalidBoundary,
  outside,
  boundaryUncertain,
  permissionDenied,
  permissionDeniedForever,
  locationServicesDisabled,
  unsupported,
  inaccurate,
  stale,
  unavailable,
}

@immutable
class CampusAccessState {
  const CampusAccessState(this.status, this.message);

  final CampusAccessStatus status;
  final String message;

  bool get isGranted => status == CampusAccessStatus.granted;
}

@immutable
class CampusGpsDiagnostic {
  const CampusGpsDiagnostic({
    required this.fix,
    required this.fixAge,
    required this.pointInPolygon,
    required this.nearestBoundaryDistanceMeters,
    required this.requiredClearanceMeters,
    required this.result,
  });

  final CampusLocationFix fix;
  final Duration fixAge;
  final CampusBoundaryRelation? pointInPolygon;
  final double? nearestBoundaryDistanceMeters;
  final double? requiredClearanceMeters;
  final CampusAccessState result;
}

class CampusGeofenceService extends ChangeNotifier {
  CampusGeofenceService({
    CampusLocationProvider? locationProvider,
    CampusBoundary? boundary,
    DateTime Function()? clock,
    double? maxAccuracyMeters,
    Duration? maxLocationAge,
    double? boundaryClearanceMeters,
  })  : _locationProvider =
            locationProvider ?? GeolocatorCampusLocationProvider(),
        _boundary = boundary ?? CampusBoundary.fromJson(_boundaryJson),
        _clock = clock ?? DateTime.now,
        maxAccuracyMeters = maxAccuracyMeters ?? _configuredMaxAccuracy ?? 30,
        maxLocationAge = maxLocationAge ??
            Duration(seconds: _configuredMaxLocationAgeSeconds ?? 120),
        boundaryClearanceMeters =
            boundaryClearanceMeters ?? _configuredBoundaryClearance ?? 15;

  static final CampusGeofenceService instance = CampusGeofenceService();

  static const String _boundaryJson =
      String.fromEnvironment('UCU_CAMPUS_BOUNDARY_JSON');
  static const String _maxAccuracySetting =
      String.fromEnvironment('UCU_CAMPUS_MAX_ACCURACY_METERS');
  static const String _maxLocationAgeSetting =
      String.fromEnvironment('UCU_CAMPUS_MAX_FIX_AGE_SECONDS');
  static const String _boundaryClearanceSetting =
      String.fromEnvironment('UCU_CAMPUS_BOUNDARY_BUFFER_METERS');
  static final double? _configuredMaxAccuracy =
      _maxAccuracySetting.isEmpty ? 30 : double.tryParse(_maxAccuracySetting);
  static final int? _configuredMaxLocationAgeSeconds =
      _maxLocationAgeSetting.isEmpty
          ? 120
          : int.tryParse(_maxLocationAgeSetting);
  static final double? _configuredBoundaryClearance =
      _boundaryClearanceSetting.isEmpty
          ? 15
          : double.tryParse(_boundaryClearanceSetting);
  static final bool _environmentPolicyIsValid =
      _configuredMaxAccuracy != null &&
          _configuredMaxAccuracy!.isFinite &&
          _configuredMaxAccuracy! > 0 &&
          _configuredMaxLocationAgeSeconds != null &&
          _configuredMaxLocationAgeSeconds! > 0 &&
          _configuredBoundaryClearance != null &&
          _configuredBoundaryClearance!.isFinite &&
          _configuredBoundaryClearance! >= 0;

  final CampusLocationProvider _locationProvider;
  final CampusBoundary _boundary;
  final DateTime Function() _clock;
  final double maxAccuracyMeters;
  final Duration maxLocationAge;
  final double boundaryClearanceMeters;

  CampusBoundary get boundary => _boundary;

  CampusAccessState _state = const CampusAccessState(
    CampusAccessStatus.checking,
    'Checking campus access.',
  );
  CampusGpsDiagnostic? _lastGpsDiagnostic;
  CampusLocationFix? _verifiedFix;
  Future<void>? _activeCheck;

  CampusAccessState get state {
    if (_state.isGranted &&
        (_verifiedFix == null || !_isFresh(_verifiedFix!))) {
      return const CampusAccessState(
        CampusAccessStatus.stale,
        'The verified location has expired. Waiting for a fresh fix.',
      );
    }
    return _state;
  }

  bool get isChecking => _activeCheck != null;

  CampusGpsDiagnostic? get lastGpsDiagnostic => _lastGpsDiagnostic;

  Map<String, String>? get currentAccessHeaders {
    final fix = _verifiedFix;
    if (!_state.isGranted || fix == null || !_isFresh(fix)) return null;
    return {
      'X-Campus-Latitude': fix.point.latitude.toStringAsFixed(8),
      'X-Campus-Longitude': fix.point.longitude.toStringAsFixed(8),
      'X-Campus-Accuracy': fix.accuracyMeters.toStringAsFixed(2),
      'X-Campus-Timestamp': fix.timestamp.toUtc().toIso8601String(),
    };
  }

  Future<void> refresh({
    bool requestPermission = true,
    bool forceFresh = false,
  }) {
    final existingCheck = _activeCheck;
    if (existingCheck != null) {
      if (!forceFresh) return existingCheck;
      return existingCheck.then(
        (_) => refresh(requestPermission: requestPermission),
      );
    }
    if (_state.isGranted &&
        (_verifiedFix == null || !_isFresh(_verifiedFix!))) {
      _setState(
        CampusAccessStatus.stale,
        'The verified location has expired. Waiting for a fresh fix.',
      );
    }
    _lastGpsDiagnostic = null;
    final check = _refresh(requestPermission: requestPermission);
    _activeCheck = check;
    notifyListeners();
    return check.whenComplete(() {
      _activeCheck = null;
      notifyListeners();
    });
  }

  Future<void> openSettings() async {
    try {
      if (_state.status == CampusAccessStatus.locationServicesDisabled) {
        await _locationProvider.openLocationSettings();
      } else {
        await _locationProvider.openAppSettings();
      }
    } on PlatformException {
      _setState(
        CampusAccessStatus.unavailable,
        'Could not open device settings. Open location settings manually and retry.',
      );
    } on MissingPluginException {
      _setState(
        CampusAccessStatus.unsupported,
        'Device settings are unavailable on this platform.',
      );
    } on ActivityMissingException {
      _setState(
        CampusAccessStatus.unavailable,
        'Return to the app and retry opening device settings.',
      );
    }
  }

  Future<void> _refresh({required bool requestPermission}) async {
    if (!_locationProvider.isSupported) {
      _setState(
        CampusAccessStatus.unsupported,
        'Location verification is unavailable on this platform.',
      );
      return;
    }
    if (!_boundary.isConfigured) {
      _setState(
        CampusAccessStatus.unconfigured,
        'The verified UCU campus perimeter has not been configured.',
      );
      return;
    }
    if (!_boundary.isValid) {
      _setState(
        CampusAccessStatus.invalidBoundary,
        'The configured campus perimeter is invalid. Contact the app administrator.',
      );
      return;
    }
    if (!_environmentPolicyIsValid ||
        !maxAccuracyMeters.isFinite ||
        maxAccuracyMeters <= 0 ||
        maxLocationAge <= Duration.zero ||
        !boundaryClearanceMeters.isFinite ||
        boundaryClearanceMeters < 0) {
      _setState(
        CampusAccessStatus.invalidBoundary,
        'Campus access settings are invalid. Contact the app administrator.',
      );
      return;
    }
    try {
      if (!await _locationProvider.isLocationServiceEnabled()) {
        _setState(
          CampusAccessStatus.locationServicesDisabled,
          'Turn on device location services to verify campus access.',
        );
        return;
      }

      var permission = await _locationProvider.checkPermission();
      if (permission == CampusPermission.denied && requestPermission) {
        permission = await _locationProvider.requestPermission();
      }
      if (permission == CampusPermission.denied) {
        _setState(
          CampusAccessStatus.permissionDenied,
          'Location permission is needed to verify campus access.',
        );
        return;
      }
      if (permission == CampusPermission.deniedForever) {
        _setState(
          CampusAccessStatus.permissionDeniedForever,
          'Location permission is blocked. Allow it in app settings to continue.',
        );
        return;
      }
      if (permission == CampusPermission.unknown) {
        _setState(
          CampusAccessStatus.unavailable,
          'The device could not determine location permission status.',
        );
        return;
      }

      final fix = await _locationProvider.getCurrentPosition();
      final fixAge = _clock().difference(fix.timestamp);
      final hasValidPoint = fix.point.isValid;
      final relation = hasValidPoint ? _boundary.relation(fix.point) : null;
      final distance =
          hasValidPoint ? _boundary.distanceToBoundaryMeters(fix.point) : null;
      final clearance = fix.accuracyMeters.isFinite && fix.accuracyMeters >= 0
          ? fix.accuracyMeters + boundaryClearanceMeters
          : null;
      if (!fix.point.isValid ||
          !fix.accuracyMeters.isFinite ||
          fix.accuracyMeters < 0) {
        _setFixResult(
          fix: fix,
          fixAge: fixAge,
          relation: relation,
          distance: distance,
          clearance: clearance,
          status: CampusAccessStatus.inaccurate,
          message:
              'The location reading is invalid. Move to an open area; automatic checks will continue.',
        );
        return;
      }
      if (fixAge.isNegative || fixAge > maxLocationAge) {
        _setFixResult(
          fix: fix,
          fixAge: fixAge,
          relation: relation,
          distance: distance,
          clearance: clearance,
          status: CampusAccessStatus.stale,
          message: 'The location reading is too old. Waiting for a fresh fix.',
        );
        return;
      }
      if (fix.accuracyMeters > maxAccuracyMeters) {
        _setFixResult(
          fix: fix,
          fixAge: fixAge,
          relation: relation,
          distance: distance,
          clearance: clearance,
          status: CampusAccessStatus.inaccurate,
          message:
              'Location accuracy is ${fix.accuracyMeters.toStringAsFixed(0)} m; '
              'improve the signal to at least ${maxAccuracyMeters.toStringAsFixed(0)} m.',
        );
        return;
      }

      if (relation == CampusBoundaryRelation.boundary ||
          distance! <= clearance!) {
        _setFixResult(
          fix: fix,
          fixAge: fixAge,
          relation: relation,
          distance: distance,
          clearance: clearance,
          status: CampusAccessStatus.boundaryUncertain,
          message:
              'The reading is too close to the campus boundary to verify safely.',
        );
        return;
      }
      if (relation == CampusBoundaryRelation.outside) {
        _verifiedFix = null;
        _setFixResult(
          fix: fix,
          fixAge: fixAge,
          relation: relation,
          distance: distance,
          clearance: clearance,
          status: CampusAccessStatus.outside,
          message:
              'This app is available only within the Urdaneta City University campus.',
        );
        return;
      }

      _verifiedFix = fix;
      _setFixResult(
        fix: fix,
        fixAge: fixAge,
        relation: relation,
        distance: distance,
        clearance: clearance,
        status: CampusAccessStatus.granted,
        message: 'Campus location verified.',
      );
    } on TimeoutException {
      _setState(
        CampusAccessStatus.unavailable,
        'Location verification timed out. Check your signal; automatic checks will continue.',
      );
    } on LocationServiceDisabledException {
      _setState(
        CampusAccessStatus.locationServicesDisabled,
        'Turn on device location services to verify campus access.',
      );
    } on PermissionDeniedException {
      _setState(
        CampusAccessStatus.permissionDenied,
        'Location permission is needed to verify campus access.',
      );
    } on PermissionRequestInProgressException {
      _setState(
        CampusAccessStatus.unavailable,
        'A location permission request is still in progress. Checking again automatically.',
      );
    } on ActivityMissingException {
      _setState(
        CampusAccessStatus.unavailable,
        'Return to the app before requesting location permission.',
      );
    } on PermissionDefinitionsNotFoundException {
      _setState(
        CampusAccessStatus.invalidBoundary,
        'Location permission configuration is missing. Contact the app administrator.',
      );
    } on InvalidPermissionException {
      _setState(
        CampusAccessStatus.unavailable,
        'The device returned an invalid location permission status.',
      );
    } on MissingPluginException {
      _setState(
        CampusAccessStatus.unsupported,
        'Location verification is unavailable on this platform.',
      );
    } on PlatformException {
      _setState(
        CampusAccessStatus.unavailable,
        'The device could not verify location. Check device settings; automatic checks will continue.',
      );
    } on PositionUpdateException {
      _setState(
        CampusAccessStatus.unavailable,
        'The device could not provide a location fix. Move to an open area; automatic checks will continue.',
      );
    }
  }

  bool _isFresh(CampusLocationFix fix) {
    final age = _clock().difference(fix.timestamp);
    return !age.isNegative && age <= maxLocationAge;
  }

  void _setFixResult({
    required CampusLocationFix fix,
    required Duration fixAge,
    required CampusBoundaryRelation? relation,
    required double? distance,
    required double? clearance,
    required CampusAccessStatus status,
    required String message,
  }) {
    _lastGpsDiagnostic = CampusGpsDiagnostic(
      fix: fix,
      fixAge: fixAge,
      pointInPolygon: relation,
      nearestBoundaryDistanceMeters: distance,
      requiredClearanceMeters: clearance,
      result: CampusAccessState(status, message),
    );
    _setState(status, message);
  }

  void _setState(CampusAccessStatus status, String message) {
    _state = CampusAccessState(status, message);
    if (!state.isGranted) _verifiedFix = null;
    notifyListeners();
  }
}

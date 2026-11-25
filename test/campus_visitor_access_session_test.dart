import 'package:flutter_test/flutter_test.dart';
import 'package:ucu_smart_plus/services/campus_geofence_service.dart';
import 'package:ucu_smart_plus/services/campus_visitor_access_session.dart';

void main() {
  final initialTime = DateTime.utc(2026, 1, 1);
  late DateTime now;
  late CampusVisitorAccessSession session;

  CampusGpsDiagnostic diagnosticFor(CampusAccessStatus status) {
    final fix = CampusLocationFix(
      point: const GeoPoint(0.5, 0.5),
      accuracyMeters: 5,
      timestamp: now,
    );
    return CampusGpsDiagnostic(
      fix: fix,
      fixAge: Duration.zero,
      pointInPolygon: status == CampusAccessStatus.outside
          ? CampusBoundaryRelation.outside
          : CampusBoundaryRelation.inside,
      nearestBoundaryDistanceMeters: 100,
      requiredClearanceMeters: 20,
      result: CampusAccessState(status, status.name),
    );
  }

  CampusVisitorAccessTransition apply(CampusAccessStatus status) =>
      session.update(
        state: CampusAccessState(status, status.name),
        diagnostic:
            status == CampusAccessStatus.granted ? diagnosticFor(status) : null,
      );

  setUp(() {
    now = initialTime;
    session = CampusVisitorAccessSession(
      maxLocationAge: const Duration(seconds: 120),
      clock: () => now,
    );
  });

  test('new visitor access requires a reliable inside verification', () {
    expect(
        apply(CampusAccessStatus.outside), CampusVisitorAccessTransition.none);
    expect(apply(CampusAccessStatus.inaccurate),
        CampusVisitorAccessTransition.none);
    expect(apply(CampusAccessStatus.stale), CampusVisitorAccessTransition.none);
    expect(
      apply(CampusAccessStatus.boundaryUncertain),
      CampusVisitorAccessTransition.none,
    );
    expect(apply(CampusAccessStatus.unavailable),
        CampusVisitorAccessTransition.none);
    expect(session.isActive, isFalse);

    expect(apply(CampusAccessStatus.granted),
        CampusVisitorAccessTransition.entered);
    expect(session.isActive, isTrue);
  });

  test('a single outside fix does not revoke a current visitor session', () {
    apply(CampusAccessStatus.granted);

    expect(
        apply(CampusAccessStatus.outside), CampusVisitorAccessTransition.none);
    expect(session.isActive, isTrue);
    expect(session.consecutiveOutsideResults, 1);
  });

  test('two consecutive reliable outside fixes revoke visitor access', () {
    apply(CampusAccessStatus.granted);

    apply(CampusAccessStatus.outside);
    expect(apply(CampusAccessStatus.outside),
        CampusVisitorAccessTransition.exited);
    expect(session.isActive, isFalse);
    expect(session.consecutiveOutsideResults, 0);
  });

  test('uncertain or unavailable fixes are not interpreted as outside', () {
    apply(CampusAccessStatus.granted);
    apply(CampusAccessStatus.outside);

    expect(
      apply(CampusAccessStatus.boundaryUncertain),
      CampusVisitorAccessTransition.none,
    );
    expect(session.isActive, isTrue);
    expect(session.consecutiveOutsideResults, 0);

    expect(
      apply(CampusAccessStatus.unavailable),
      CampusVisitorAccessTransition.none,
    );
    expect(session.isActive, isTrue);
    expect(apply(CampusAccessStatus.inaccurate),
        CampusVisitorAccessTransition.none);
    expect(apply(CampusAccessStatus.stale), CampusVisitorAccessTransition.none);
    expect(session.isActive, isTrue);
  });

  test('temporary location loss retains access for at most 120 seconds', () {
    apply(CampusAccessStatus.granted);
    now = initialTime.add(const Duration(seconds: 119));

    expect(apply(CampusAccessStatus.unavailable),
        CampusVisitorAccessTransition.none);
    expect(session.isActive, isTrue);

    now = initialTime.add(const Duration(seconds: 121));
    expect(session.expireIfNeeded(), CampusVisitorAccessTransition.expired);
    expect(session.isActive, isFalse);
  });

  test('a reliable inside fix restores access after a confirmed exit', () {
    apply(CampusAccessStatus.granted);
    apply(CampusAccessStatus.outside);
    apply(CampusAccessStatus.outside);

    expect(apply(CampusAccessStatus.granted),
        CampusVisitorAccessTransition.entered);
    expect(session.isActive, isTrue);
  });
}

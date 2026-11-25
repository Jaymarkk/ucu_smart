import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ucu_smart_plus/screens/campus_restriction_screen.dart';
import 'package:ucu_smart_plus/services/campus_geofence_service.dart';

Future<void> _pumpRestrictionScreen(
  WidgetTester tester,
  CampusAccessStatus status,
  String message,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: CampusRestrictionScreen(
        state: CampusAccessState(status, message),
        onOpenSettings: () async {},
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('restriction UI does not expose debug diagnostics or coordinates',
      (tester) async {
    await _pumpRestrictionScreen(
      tester,
      CampusAccessStatus.inaccurate,
      'internal service detail must not be shown',
    );

    expect(find.text('Campus Access Restricted'), findsOneWidget);
    expect(
      find.text(
        'Access to the UCU Smart+ Campus Map is available only when your current location is successfully verified within Urdaneta City University.',
      ),
      findsOneWidget,
    );
    expect(find.text('Location Accuracy Insufficient'), findsOneWidget);
    expect(
      find.text(
        'Your current location cannot be verified accurately. Please ensure that location services are enabled and that your device can obtain a reliable location reading.',
      ),
      findsOneWidget,
    );
    expect(find.text('Show GPS diagnostics (debug only)'), findsNothing);
    expect(
        find.text('internal service detail must not be shown'), findsNothing);
    expect(find.text('Latitude'), findsNothing);
    expect(find.text('Longitude'), findsNothing);
    expect(find.text('Coordinates are not saved or uploaded.'), findsNothing);
  });

  testWidgets('restriction status uses formal titles and guidance',
      (tester) async {
    const cases = <(CampusAccessStatus, String, String)>[
      (
        CampusAccessStatus.checking,
        'Location Verification in Progress',
        'Your current location is being checked. Please wait for verification to complete.',
      ),
      (
        CampusAccessStatus.granted,
        'Campus Location Confirmed',
        'Your current location has been successfully verified within Urdaneta City University.',
      ),
      (
        CampusAccessStatus.outside,
        'Location Outside Campus Boundary',
        'Your current location is outside the authorized Urdaneta City University campus boundary.',
      ),
      (
        CampusAccessStatus.unavailable,
        'Location Verification Unavailable',
        'Your current location is temporarily unavailable. Campus access requires a valid location verification.',
      ),
      (
        CampusAccessStatus.boundaryUncertain,
        'Location Verification Required',
        'Your current location is too close to the campus boundary to be verified with confidence. Access remains restricted until your location can be confirmed.',
      ),
    ];

    for (final (status, title, guidance) in cases) {
      await _pumpRestrictionScreen(tester, status, 'ignored internal detail');
      expect(find.text(title), findsOneWidget);
      expect(find.text(guidance), findsOneWidget);
      expect(find.text('ignored internal detail'), findsNothing);
    }
  });
}

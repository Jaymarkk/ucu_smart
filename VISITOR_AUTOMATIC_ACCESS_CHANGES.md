# Automatic Visitor Campus Access Changes

Updated: November 12, 2026

## Summary

Visitor access now uses the existing `CampusGeofenceService` and configured
campus polygon. Arrival notifications, notification-tap navigation, notification
settings, and Android background arrival-geofence registration were removed.
The map, campus boundary, routing, authentication, and Laravel backend were not
changed.

## Visitor access behavior

- **Continue as Visitor** requests a fresh location verification. A reliable
  inside result opens the existing Campus Map; otherwise the Visitor remains
  restricted.
- While Visitor mode is active, the app checks location every 30 seconds and
  after resuming from the background.
- Two consecutive reliable outside results revoke Visitor map access.
- Unavailable, inaccurate, stale, or boundary-uncertain results are not treated
  as proof that the Visitor has exited.
- A previously verified Visitor session is retained during temporary location
  loss for up to 120 seconds after the last reliable inside result. If it
  expires without a new inside result, access is restricted as unverified.
- Visitor mode does not create or require a Student account and does not grant
  Student or Admin pages or protected API access.
- Student and Admin authentication and authorization remain in place.

No background or instant-exit detection is provided. Location checks require
the app to be active or resumed.

## Arrival feature removal

Removed the arrival-only Dart service and navigation handler, Android geofence
and boot receivers and related native classes, arrival-notification settings,
and notification-specific tests. Removed arrival-only Android permissions and
the explicit Play Services location dependency used by that implementation.
Foreground location permissions and the existing shared Flutter location
verification remain.

## Files changed

Updated:

- `lib/main.dart` — removed notification setup and tap handling; Visitor entry
  uses fresh verification and existing navigation.
- `lib/widgets/campus_access_gate.dart` — applies Visitor session checks,
  periodic foreground checks, resume checks, and route restrictions.
- `lib/screens/campus_restriction_screen.dart` and
  `lib/screens/campus_restriction_copy.dart` — removed manual retry and
  arrival-notification controls; retained verification status and guidance.
- `lib/services/campus_geofence_service.dart` — adjusted user-facing messages
  for automatic checks.
- `android/app/src/main/AndroidManifest.xml`,
  `android/app/build.gradle.kts`, and
  `android/app/src/main/kotlin/com/example/ucu_smart/MainActivity.kt` — removed
  arrival-specific Android registration and simplified the activity.
- `README.md` — documented current Visitor access behavior.
- `test/campus_access_gate_test.dart`, `test/widget_test.dart`, and
  `test/campus_gps_diagnostic_panel_test.dart` — updated coverage for the
  automatic flow and removal of arrival features.
- `CAMPUS_ARRIVAL_NOTIFICATION_VERIFICATION.md`,
  `VISITOR_CAMPUS_ARRIVAL_CHANGES.md`, and
  `STUDENT_CAMPUS_BYPASS_CHANGES.md` — marked historical descriptions as
  superseded.

Added:

- `lib/services/campus_visitor_access_session.dart` — in-memory Visitor
  entry/exit debounce and 120-second temporary-location-loss policy.
- `test/campus_visitor_access_session_test.dart` — tests for entry, exit,
  uncertain/unavailable location, expiry, and re-entry.

Removed:

- `lib/services/campus_arrival_service.dart`
- `lib/services/campus_arrival_navigation_handler.dart`
- `android/app/src/main/kotlin/com/example/ucu_smart/CampusArrivalManager.kt`
- `android/app/src/main/kotlin/com/example/ucu_smart/CampusArrivalEventPolicy.kt`
- `android/app/src/main/kotlin/com/example/ucu_smart/CampusArrivalBoundaryPolicy.kt`
- `android/app/src/main/kotlin/com/example/ucu_smart/CampusGeofenceReceiver.kt`
- `android/app/src/main/kotlin/com/example/ucu_smart/CampusBootReceiver.kt`
- The corresponding Android arrival-policy unit tests and Flutter arrival
  service/navigation tests.

## Validation results

- `flutter analyze` — passed; no issues found.
- Focused Visitor, gate, geofence, diagnostic, and widget tests — **55 passed**.
- Configured campus-boundary tests — **2 passed**, including the supplied
  37-point order check.
- Android unit tests (`:app:testDebugUnitTest`) — passed.
- Full `flutter test` — **135 passed, 1 failed**. The pre-existing Building
  1-to-Marker 31 route test still expects
  `[(53,20.4),(38,20),(38,18),(34,16),(32.5,13)]`, while the existing route
  implementation returns `[(53,20.4),(33,14),(32.5,13)]`. The route logic and
  expectation were not changed.

No Release APK was built, and no physical-device testing was performed.

## Preserved scope

The campus polygon and its supplied point order, map image and markers, map
interactions, route graph and route services, Laravel backend, and Student/Admin
authentication were not modified. No debug access bypass was added.

Git status could not be inspected because the workspace does not contain a
`.git` directory.

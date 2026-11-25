# Campus Arrival Notification Verification Update

> **Superseded:** Arrival notifications, notification-tap navigation, and
> Android background arrival-geofence registration have been removed from the
> current app. This file records the former implementation and is not a
> description of current behavior. See the Visitor campus access section in
> [README.md](./README.md).

## What changed

The Android circular geofence is only an approximate trigger. An `ENTER` event
no longer sends an arrival notification directly. Android requests a fresh,
high-accuracy location fix with cached fixes disallowed, then checks the fix
against the registered UCU campus polygon.

An arrival notification is sent only when all checks pass:

- The fix is valid and no more than 120 seconds old.
- Reported accuracy is 30 meters or better.
- The point is inside the configured polygon.
- The point is outside the uncertainty margin: reported accuracy plus the
  existing 15-meter boundary buffer.
- Required location, notification, and monitoring-mode states remain valid
  when the fix is evaluated. Monitoring requires either an authenticated
  Student session or active Visitor mode.

The location request is bounded to 8 seconds. If Android cannot provide a
qualifying fix, the notification is suppressed. No cached location is accepted.
An `EXIT` event never sends an arrival notification and resets state so a later
valid re-entry can be checked. Duplicate `ENTER` events are suppressed.

This background notification check does not replace or weaken
`CampusAccessGate`, `CampusGeofenceService`, or fresh verification required when
the user taps the notification.

## Visitor-only arrival flow

Selecting **Continue as Visitor** activates a separate native Visitor mode; it
does not create or imply a Student account. The app obtains a fresh foreground
fix through the existing `CampusGeofenceService`. A confirmed inside fix opens
the existing Campus Map. A confirmed outside fix keeps the user restricted to
Visitor/map/bootstrap routes and attempts Android arrival-monitor registration
using the configured polygon only as the source for an approximate circular
trigger. Registration remains conditional on the valid boundary, foreground
and background location permissions, enabled location services, notification
permission, and Android registration success. Missing permissions or a
registration failure leave monitoring inactive and are surfaced in the
verification screen.

On `ENTER`, Android re-checks active Visitor mode (or the existing Student
session), opt-in/enabled state, permissions, and location services before
requesting a fresh high-accuracy fix. Visitor mode does not bypass the polygon,
30 m accuracy, 120 s freshness, 15 m clearance buffer, duplicate suppression,
or notification-tap verification. `EXIT` resets entry state without notifying.
The notification tap performs another fresh foreground verification and opens
the existing map only after that succeeds. The notification reads:
“Welcome to Urdaneta City University!” and “You're near Urdaneta City
University. Tap to open UCU Smart+ Campus Map.” Student and Admin routes remain
protected; Laravel/API authorization was not changed.

The duplicate warning happened because the restriction screen previously
rendered both a retry-specific notice and the persistent verification-status
card. The retry-specific card was removed: the single status card now reports
the current failure reason, while the Retry button and loading behavior remain.

## Files changed for this update

- `android/app/src/main/kotlin/com/example/ucu_smart/CampusArrivalBoundaryPolicy.kt`
- `android/app/src/main/kotlin/com/example/ucu_smart/CampusArrivalEventPolicy.kt`
- `android/app/src/main/kotlin/com/example/ucu_smart/CampusArrivalManager.kt`
- `android/app/src/main/kotlin/com/example/ucu_smart/CampusGeofenceReceiver.kt`
- `android/app/src/main/kotlin/com/example/ucu_smart/MainActivity.kt`
- `lib/main.dart`
- `lib/screens/splash_screen.dart`
- `lib/screens/campus_restriction_screen.dart`
- `lib/widgets/campus_access_gate.dart`
- `lib/services/campus_arrival_service.dart`
- `lib/services/campus_arrival_navigation_handler.dart`
- `android/app/src/test/kotlin/com/example/ucu_smart/CampusArrivalBoundaryPolicyTest.kt`
- `android/app/src/test/kotlin/com/example/ucu_smart/CampusArrivalEventPolicyTest.kt`
- `test/campus_arrival_service_test.dart`
- `test/campus_arrival_navigation_test.dart`
- `test/campus_access_gate_test.dart`
- `test/widget_test.dart`
- `CAMPUS_GEOFENCING_CHANGES.md`

The campus polygon coordinates, 30-meter accuracy limit, 120-second freshness
limit, 15-meter boundary buffer, map, markers, route services, and Laravel
backend were not changed.

## Verification

- `flutter analyze` — passed with no issues.
- Focused arrival, gate, navigation, and widget tests — 57 passed.
- `flutter test` — 150 passed; one existing Building 1-to-31 route
  expectation failed. It expects `[(53,20.4),(38,20),(38,18),(34,16),(32.5,13)]`;
  the unchanged implementation returns `[(53,20.4),(33,14),(32.5,13)]`.
- Running the full suite with the Release boundary define yielded 140 passed
  and 5 failed. Four failures are existing tests that explicitly expect no
  configured boundary; the remaining failure is the same route mismatch.
  Configured-boundary behavior was verified separately with the define.
- `flutter test --dart-define-from-file=config\ucu_campus_boundary.json test\ucu_campus_boundary_config_test.dart`
  — passed; both boundary configuration tests passed and confirmed all 37
  points remain in the supplied order.
- Android Kotlin unit tests (`.\gradlew.bat :app:testDebugUnitTest`)
  — passed; policy tests cover inside/outside,
  inaccurate, stale/future, boundary-uncertain, unavailable, duplicate, EXIT,
  and re-entry cases.
- The Release APK contains the exact configured boundary string in all three
  AOT libraries; JSON parsing confirmed 37 latitude/longitude pairs.
- Map and route-source SHA-256 checks matched the previously recorded values.

### Building 1-to-31 route test diagnosis

The test expects Building 1-to-Marker 31 to be the reversed suffix of the
existing Building 32-to-Building 1 route. The route implementation has a
special reverse-route case only for Building 1-to-Building 32. Building
1-to-Marker 31 does not match that case and instead uses the general walkable
path search, which returns a shorter route via `(33, 14)`. The expected route
contains `(38, 20)`, `(38, 18)`, `(34, 16)` before Marker 31. The route source
and test expectation were not changed.

### Clean Release APK

Built after `flutter clean` and dependency restoration using:

```powershell
flutter build apk --release --dart-define-from-file=config\ucu_campus_boundary.json
```

- Artifact: `build\app\outputs\flutter-apk\app-release.apk`
- Size: 56,247,589 bytes (53.6 MB)
- SHA-256: `DC13A62F2D461F28731DF7FFDACDAA8759029E8FF16D1FDB76A259F4205B0B99`
- Modified: November 12, 2026, 12:21:22 PM (local build machine time)
- The supplied 37-point boundary JSON was found byte-for-byte in the compiled
  `libapp.so` for arm64-v8a, armeabi-v7a, and x86_64.
- The Release build command did not supply either development bypass define.
  The Flutter gate additionally checks `kDebugMode`, which is false in Release.
- No map, marker, route, or map asset files were changed. The map asset SHA-256
  is `9f02b5734d02b108f3e65a7dabdd9d679ed22b75dfe67ea3dbed43d1bc208fc2`.
  The route service hashes remain
  `b23e2d9639014c40abe39a82db8940a5c70fe309879a118a8b22982154e91a8d` and
  `7dd269adb4aefa58bf4be59418fc99851f6d87ec0b19c41b7a28f8d6349ad6c5`.

The existing Android Release Gradle configuration signs with the debug
signing config. This APK is a Release-variant build, but it is not signed with
a production release key and should not be treated as a production-distribution
artifact.

Background location acquisition, notification delivery, and permission
behavior have not been tested on a physical Android device. Device testing is
required before relying on real-world geofence delivery. Android background
monitoring requires location services, foreground and background location
permission (including “Allow all the time” where Android requires it), and
notification permission on Android 13+. OS geofence delivery can be delayed or
restricted by Doze and manufacturer battery policies. Android does not
reliably deliver events while the user has force-stopped the app; monitoring
must be re-established after the app is launched again.

# Visitor Campus Arrival Changes

Updated: November 12, 2026

> **Superseded:** Visitor arrival monitoring and notifications have since been
> removed. The current app uses foreground automatic polygon verification for
> Visitor entry and exit, documented in [README.md](./README.md).

## Visitor flow

- Tapping **Continue as Visitor** does not require or create a Student account.
- The app requests a fresh location verification using the existing
  `CampusGeofenceService`. A qualifying inside-campus result opens the existing
  Campus Map.
- If the fix is outside, the app remains in Visitor mode and attempts Android
  background arrival monitoring when required permissions and registration
  are available. Missing permissions or registration failures do not show
  monitoring as enabled.
- Visitor mode is distinct from Student authentication. It does not grant
  access to Student or Admin pages or protected backend APIs.

## Arrival notification safeguards

The circular Android geofence is only an approximate trigger. An ENTER event
must obtain a fresh high-accuracy fix and confirm that it is inside the
configured campus polygon before sending a notification. Existing thresholds
remain unchanged:

- Maximum accuracy: **30 m**
- Maximum fix age: **120 seconds**
- Boundary buffer: **15 m**

EXIT never sends an arrival notification and resets state for later re-entry.
Duplicate ENTER events are suppressed. Tapping the notification performs
another fresh verification and opens the existing map only if that check
succeeds.

Notification:

- Title: `Welcome to Urdaneta City University!`
- Body: `You're near Urdaneta City University. Tap to open UCU Smart+ Campus Map.`

## Duplicate warning fix

The verification screen previously showed a retry-specific warning as well as
the persistent status card. The retry-specific card was removed. The single
status card continues to show the current verification reason, and retry,
loading feedback, and retry results remain.

## Validation

- `flutter analyze` — passed with no issues.
- Focused arrival, navigation, gate, and widget tests — **57 passed**.
- Android Kotlin unit tests (`.\gradlew.bat :app:testDebugUnitTest`) — passed.
- Full `flutter test` — **150 passed, 1 failed**. The unchanged Building 1 to
  Marker 31 route expectation fails: it expects
  `[(53,20.4),(38,20),(38,18),(34,16),(32.5,13)]`, while the existing route
  implementation returns `[(53,20.4),(33,14),(32.5,13)]`. Neither route code nor
  its expected route was changed.
- The configured boundary JSON contains **37 coordinate pairs** and is embedded
  in the Release APK AOT libraries for arm64-v8a, armeabi-v7a, and x86_64.
- SHA-256 checks confirmed the map image and route source files are unchanged.
- No Laravel, campus polygon, map, marker, or route implementation was changed.

## Release APK

- Build command:
  `flutter build apk --release --dart-define-from-file=config\ucu_campus_boundary.json`
- Artifact: `build\app\outputs\flutter-apk\app-release.apk`
- Size: **56,247,589 bytes (53.6 MB)**
- SHA-256: `DC13A62F2D461F28731DF7FFDACDAA8759029E8FF16D1FDB76A259F4205B0B99`
- This is a Release-variant APK signed with the configured debug signing key,
  not a production release key.

## Device-testing limitations

Physical Android testing has not been performed. Background geofence delivery
may be delayed or restricted by Doze and manufacturer battery policies. It
requires appropriate foreground/background location access, enabled location
services, and notification permission (including Android 13+ notification
permission). Force-stopping the app can stop delivery until the app is launched
again.

For the full verification details, see
[CAMPUS_ARRIVAL_NOTIFICATION_VERIFICATION.md](./CAMPUS_ARRIVAL_NOTIFICATION_VERIFICATION.md).

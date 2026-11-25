# Temporary Flutter Web Debug Campus Map Bypass

## Purpose

This opt-in bypass lets local Flutter Web development in Chrome open the
existing Campus Map without a location check. It is for UI development only;
it does not verify campus access or production geofence behavior.

## Run locally

From the Flutter project root:

```powershell
flutter run -d chrome --dart-define=UCU_SMART_DEV_CAMPUS_MAP_BYPASS=true
```

With the define enabled, **Continue as Visitor** opens the existing Campus Map
without requesting a location fix. Remove the define to restore the normal
geofence check.

## Restrictions and security

- The bypass requires an explicit compile-time define, Flutter Debug mode, and
  Flutter Web (`kDebugMode && kIsWeb`).
- It cannot be enabled in Release builds, even if the define is supplied. It
  also remains disabled in Android and desktop builds, including Debug.
- The exception only bypasses the Flutter location gate for the Visitor Campus
  Map route. It does not grant Student or Admin access, change authentication or
  Laravel authorization, or make client-supplied location data trustworthy.
- `CampusGeofenceService`, the campus boundary, GPS checks, map assets, markers,
  routing, and backend code are not changed by this bypass.
- Do not use the bypass as evidence that the official campus perimeter or
  production access policy is correct.

## Implementation

- `lib/services/campus_map_development_policy.dart` — requires Debug mode, Web,
  and explicit opt-in.
- `test/campus_map_development_policy_test.dart` — verifies opt-in, Web-only
  behavior, and rejection in Release mode.
- `test/campus_map_development_bypass_test.dart` — covers Visitor map access
  and ensures the bypass does not grant Student or Admin access.
- `README.md` — includes the Chrome run command and safety notes.

## Validation

- `flutter analyze` — passed with no issues.
- Focused native policy, geofence service, and access-gate tests — 40 passed,
  3 skipped.
- `flutter build web --release --dart-define=UCU_SMART_DEV_CAMPUS_MAP_BYPASS=true`
  — passed. The Release build compiles with the define, but the policy still
  rejects enabling the bypass because it is not a Debug build.
- The Chrome-targeted widget test did not complete: it remained at test loading
  for over five minutes and was stopped. The Web widget behavior therefore
  remains unverified by that test.

No geofence, map, marker, routing, authentication, or backend behavior was
changed for this update.

# Campus Geofencing Implementation

## Overview

Added campus-access gating to UCU Smart+ and server-side campus-location
validation to the Laravel API.

The Flutter app now has the supplied 37-point perimeter in its explicit build
configuration. The polygon has passed the Flutter parser but has not been
independently verified against Urdaneta City University's legal property
boundary. Flutter builds that omit the define remain unconfigured and fail
closed. Laravel configuration is separate and was not changed by the latest
Flutter packaging fix.

## Latest access-gate audit update (2026-11-09)

The campus boundary is still **unconfigured**. The Main Gate coordinate and
four candidate boundary points supplied for review do not establish a complete,
ordered, approved perimeter, so they were not used to configure the app.
No authoritative GIS/CAD boundary file was found in the Flutter project.

The audit found two development settings that made the app appear to verify
access when it had not:

- `lib/main.dart` enabled the map-only bypass unconditionally in debug builds.
  That automatic bypass was removed. Campus Map now follows the same access
  gate as other protected pages.
- `.idea/runConfigurations/main_dart.xml` automatically enabled the
  Student-Portal-only debug bypass. That argument was removed from the
  checked-in run configuration.

The general and Student-only debug UI bypasses remain available when a
developer explicitly supplies their documented `--dart-define`. They default
off and are honored only in debug builds. They skip only the Flutter UI gate:
they do not produce location evidence or grant Laravel API access. Login and
bootstrap routes remain available to support recovery.

Files changed by this follow-up:

- `lib/main.dart`
- `lib/widgets/campus_access_gate.dart`
- `.idea/runConfigurations/main_dart.xml`
- `test/campus_access_gate_test.dart`
- `test/widget_test.dart`
- `README.md`

The geofence service, permissions, map, markers, and routing implementation
were not changed. The README now describes the unconfigured boundary and
explicit-only debug bypass behavior. Android location behavior has not been
verified on a device inside or outside UCU.

Follow-up validation from `C:\ucu_smart`:

| Command | Result |
|---|---|
| `flutter analyze` | Passed; no issues found. |
| `flutter test test\campus_geofence_service_test.dart test\campus_access_gate_test.dart test\widget_test.dart` | Passed; all 38 tests passed. |
| `flutter test test\route_service_test.dart test\dynamic_building_route_service_test.dart` | 25 passed, 1 failed. The existing building 1-to-31 route expectation fails; no route code was changed. |

## Retry verification feedback update (2026-11-09)

The existing Retry Location Verification action now displays an inline,
friendly notification based on the result returned by the existing
`CampusGeofenceService.refresh()` call:

- A confirmed outside result displays **Outside UCU Campus** and asks the user
  to enter the campus. The verification screen remains visible and access stays
  restricted.
- An unavailable location displays **Unable to verify your location** and
  advises enabling Location Services and retrying.
- An inaccurate, stale, or boundary-uncertain fix displays **Location not
  confirmed yet** and asks the user to move to an open area and retry.
- A fresh, accurate fix confirmed inside the configured boundary continues
  through the existing access gate and allows protected app access.

The retry uses the existing geofence service and gate; no new location
validation was added. Automatic checks on launch, app resume, and scheduled
rechecks remain unchanged. The campus boundary is still unconfigured, so this
change does not establish real UCU inside/outside results. No coordinates,
permissions, API, authentication, or backend behavior were changed.

Files changed for this update:

- `lib/screens/campus_restriction_screen.dart` — renders retry-result notices.
- `lib/widgets/campus_access_gate.dart` — returns the existing refresh result
  to the verification screen.
- `test/campus_access_gate_test.dart` — tests outside, unavailable,
  inaccurate, and successful retry results.

Validation from `C:\ucu_smart`:

| Command | Result |
|---|---|
| `flutter analyze` | Passed; no issues found. |
| `flutter test test\campus_access_gate_test.dart` | Passed; all 14 tests passed. |

## Retry notification diagnosis (2026-11-09)

The reported release-APK behavior was traced through the existing retry flow.
No source files were changed as part of this diagnosis.

### Likely root cause

The verified UCU boundary is not configured in the project. If the release APK
was built without a valid `UCU_CAMPUS_BOUNDARY_JSON` Dart define,
`CampusGeofenceService._refresh()` returns `CampusAccessStatus.unconfigured`
before it checks permissions or requests a GPS fix. This is the intended
fail-closed configuration behavior; it cannot classify the user as inside or
outside UCU.

The retry callback in `CampusAccessGate.build()` awaits the existing
`CampusGeofenceService.refresh()` and returns the resulting service state.
`CampusRestrictionScreen._retry()` awaits that callback and updates the
notification state. However,
`CampusRestrictionScreen._noticeForResult()` maps both `unconfigured` and
`invalidBoundary` to no notification. The button therefore shows its loading
state during the refresh, then renders no retry notice for the likely
unconfigured result.

### Checked behavior and remaining uncertainty

- The refresh future clears `_activeCheck` and notifies listeners in
  `CampusGeofenceService.refresh()`'s `whenComplete` callback, so the inspected
  code does not indicate a stuck loading state on the unconfigured path.
- The retry handler awaits the result and checks `mounted` before calling
  `setState`; no missing await or missing mounted check was found in that path.
- The unconfigured return occurs before GPS acquisition, so there is no
  geofence classification result for this case and it must not be described as
  an outside-campus result.
- Source inspection cannot confirm the exact Dart defines embedded in the
  user's already-built APK. Confirm the build invocation or build environment
  to determine whether `UCU_CAMPUS_BOUNDARY_JSON` was supplied.

### Smallest proposed fix and regression coverage

Add a friendly, explicit notification mapping for `unconfigured` and
`invalidBoundary` using the existing service message. Keep the existing
verification screen and access gate in place; do not treat either result as
inside or outside and do not bypass restrictions.

Add a widget test using an unconfigured service that taps Retry and verifies
that the configuration notice is shown, the verification screen remains
visible, no access headers are issued, and the location provider is not asked
for a position. Existing retry-result tests cover outside, unavailable,
inaccurate, and successful inside results, but not the unconfigured retry
notice.

No GPS logic, boundary data, permissions, map, routing, authentication, API,
or access restriction was modified. No validation command was run because this
update records diagnosis and a proposed fix only.

## Release APK and campus restriction follow-up (2026-11-09)

A later read-only inspection confirmed that the unconfigured-boundary
notification fix is now present in `CampusRestrictionScreen._noticeForResult()`.
It maps both `unconfigured` and `invalidBoundary` to friendly notices. The
earlier diagnosis above described the code before this mapping was added and
should not be used as the current screen behavior.

The reported Release build command, `flutter build apk --release`, does not
pass `UCU_CAMPUS_BOUNDARY_JSON`. The project has no default polygon and the
Release Gradle configuration does not add that Dart define. For a build made
with that command and no externally supplied define, the service reads an
empty boundary and returns `CampusAccessStatus.unconfigured` before checking
location permission or acquiring a GPS fix. The app cannot determine whether
the user is inside or outside UCU in that state; access correctly remains
restricted. No polygon or Main Gate coordinate was invented or substituted.

The local Release APK artifacts inspected were last written on November 9,
2026 at 04:03 PHT. Their AOT payload contains the current unconfigured and
invalid-boundary notification text. This confirms those strings are in the
local artifact, but does not prove which APK is installed on the user's phone
or the Dart defines used for a separately built/distributed APK.

Android's merged Release manifest contains both coarse and fine location
permissions. The location provider requests a high-accuracy fix with a
15-second limit. However, the unconfigured-boundary early return occurs before
provider calls, so those permissions do not establish that GPS acquisition
was attempted or working. No Android device was available to this inspection;
device permission state and a real GPS fix remain unverified.

Validation from `C:\ucu_smart`:

| Command | Result |
|---|---|
| `flutter test test\campus_access_gate_test.dart` | Passed; all 16 tests passed, including unconfigured and invalid-boundary retry notices. |

No source or build configuration files were changed during this diagnostic.
Next, obtain a complete UCU-approved perimeter, verify it without substituting
building or Main Gate points, and only then pass that verified polygon into a
new Release build. After installing that exact artifact on Android, verify the
reported service status and GPS permission/fix behavior on-device.

## Flutter implementation

- Added `CampusGeofenceService` for location permission checks, fresh and
  accurate location fixes, polygon validation, point-in-polygon classification,
  and campus-access state.
- Added `CampusAccessGate` around the app navigator. Protected Campus Map,
  Student Portal, and Admin pages are inaccessible until the gate verifies
  access; login/bootstrap routes remain available for recovery.
- Added a responsive restriction screen s   
howing the current verification
  status, a retry action, and settings access for permission or location-service
  issues.
- The app checks on launch, when resumed, and every 30 seconds while active.
- Unsupported platforms, unavailable or stale fixes, permission problems,
  invalid configuration, and boundary uncertainty fail closed. They are not
  mislabeled as proof that the user is outside campus.
- Protected API calls send the latest location fix as request headers.
- Added foreground location permissions for Android and the location-usage
  description for iOS. No background-location permission was added.
- Windows builds do not have a configured location provider and show an
  unsupported-location state. There is no production geofence bypass.
- Local Flutter UI work can opt into the compile-time
  `UCU_SMART_DEV_BYPASS_CAMPUS_GEOFENCE=true` flag. It defaults off and is
  honored only in debug mode. It only skips the Flutter gate; it does not
  provide API location evidence or bypass Laravel middleware.

### Location thresholds

Defaults are shared by the Flutter client and Laravel API:

| Setting | Default | Policy |
|---|---:|---|
| `UCU_CAMPUS_MAX_ACCURACY_METERS` | 30 m | Less accurate fixes are rejected. |
| `UCU_CAMPUS_MAX_FIX_AGE_SECONDS` | 120 s | Older fixes are stale. |
| `UCU_CAMPUS_BOUNDARY_BUFFER_METERS` | 15 m | Added to reported accuracy to define a restricted uncertainty band around the boundary. |

A location must be on the interior side of the polygon and farther from the
boundary than its reported accuracy plus the configured buffer. Points within
that band are reported as ambiguous and remain restricted. A successful fix
expires after 120 seconds.

## Laravel implementation

- Added configurable campus boundary and threshold settings in
  `config/campus_geofence.php`, documented with placeholders in `.env.example`.
- Added `CampusBoundary` polygon validation, point-in-polygon classification,
  boundary-distance calculation, and rejection of invalid/self-intersecting
  polygons.
- Added `EnsureCampusAccess` middleware to all `/api/admin/*` data routes.
  Login, authenticated user lookup, and logout remain available as
  authentication/bootstrap operations; Admin data remains geofenced.
- The middleware validates coordinate ranges, accuracy, timestamp freshness,
  polygon membership, and the boundary uncertainty margin.
- Existing Sanctum authentication, Admin role enforcement, and public visitor
  building endpoints are preserved.
- Missing or invalid backend boundary configuration returns HTTP 503. Missing,
  malformed, stale, or inaccurate location evidence is rejected.

Client coordinates are untrusted and can be spoofed. The backend validates
them independently, but this does not provide device attestation or prevent a
determined user from spoofing GPS.

## Files changed

### Flutter project (`C:\ucu_smart`)

- `pubspec.yaml` and `pubspec.lock` — added `geolocator`.
- `android/app/src/main/AndroidManifest.xml` — added coarse and fine foreground
  location permissions.
- `ios/Runner/Info.plist` — added the location-use description.
- `lib/main.dart` — wraps the full app in the access gate.
- `lib/services/campus_geofence_service.dart` — location provider, polygon
  logic, verification policy, and access states.
- `lib/widgets/campus_access_gate.dart` — app-wide gate, lifecycle observer, and
  periodic rechecks.
- `lib/screens/campus_restriction_screen.dart` — restriction, retry, and
  settings UI.
- `lib/services/admin_api_service.dart` and
  `lib/services/building_api_service.dart` — attach campus evidence to
  protected API requests and fail closed when evidence is missing.
- `test/campus_geofence_service_test.dart`,
  `test/campus_access_gate_test.dart`, and
  `test/support/fake_campus_location_provider.dart` — polygon and access-state
  tests using injected test locations.
- `test/admin_auth_service_test.dart`, `test/building_api_service_test.dart`,
  and `test/widget_test.dart` — updated protected API and app tests.
- `README.md` — added geofencing setup and testing instructions.

### Laravel project (`C:\xampp\htdocs\ucu-smart-backend`)

- `.env.example` — added perimeter and threshold placeholders.
- `config/campus_geofence.php` — geofence configuration.
- `app/Services/CampusBoundary.php` — polygon validation and geometry.
- `app/Http/Middleware/EnsureCampusAccess.php` — API request validation.
- `routes/api.php` — applies middleware to protected routes.
- `tests/Feature/CampusAccessTest.php` — access, invalid-fix, configuration,
  authentication, and public-building tests.
- `tests/Feature/BuildingManagementTest.php` — supplies an in-memory test-only
  polygon and location headers so existing Admin tests continue to exercise
  their existing behavior.
- `README.md` — documents backend configuration and security limitations.

No map image, marker coordinate or ID, route behavior, migration, database
record, or real `.env` file was changed.

## Required perimeter configuration

Obtain and verify the official property perimeter with the university. Supply
its vertices in perimeter order as JSON coordinate pairs:

```json
[[latitude1,longitude1],[latitude2,longitude2],[latitude3,longitude3]]
```

The polygon is implicitly closed. Configure the **same verified polygon**
independently in both projects.

### Laravel

Set these values in the backend deployment environment (or a local, untracked
`.env` file for development):

```dotenv
UCU_CAMPUS_BOUNDARY_JSON=[[latitude1,longitude1],[latitude2,longitude2],[latitude3,longitude3]]
UCU_CAMPUS_MAX_ACCURACY_METERS=30
UCU_CAMPUS_MAX_FIX_AGE_SECONDS=120
UCU_CAMPUS_BOUNDARY_BUFFER_METERS=15
```

After changing environment values on a deployment that caches Laravel
configuration, clear/rebuild the configuration cache using the normal
deployment process. Do not add actual perimeter data to `.env.example` or
commit secrets.

### Flutter Android/iOS

Pass the verified polygon at build/run time:

```powershell
Set-Location C:\ucu_smart
flutter run --dart-define='UCU_CAMPUS_BOUNDARY_JSON=[[latitude1,longitude1],[latitude2,longitude2],[latitude3,longitude3]]'
```

Optional matching values can also be supplied as `--dart-define` settings:

```text
UCU_CAMPUS_MAX_ACCURACY_METERS
UCU_CAMPUS_MAX_FIX_AGE_SECONDS
UCU_CAMPUS_BOUNDARY_BUFFER_METERS
```

Do not use sample or test polygon coordinates for production.

## Safe testing and platform notes

- Flutter unit/widget tests use an injected fake location provider and a
  synthetic polygon. No real GPS or production bypass is used.
- Laravel feature tests configure their synthetic polygon in test memory. They
  do not require production `.env` changes or real device coordinates.
- For manual Android emulator checks, configure the verified polygon and use
  Android Studio **Extended Controls > Location** to send a point well inside,
  well outside, and near the boundary.
- Android emulator development can run with `flutter run`; a real Android
  device must grant location permission and use the real configured perimeter.
- Windows desktop does not provide location verification in this
  implementation. To work on its UI locally without a boundary, run the app
  with `--dart-define=UCU_SMART_DEV_BYPASS_CAMPUS_GEOFENCE=true`. This allows
  protected UI navigation in debug builds only and grants no backend
  API access. For test-only UI/API flows, use the existing fake location
  provider and mocked HTTP clients in Flutter tests and the synthetic,
  in-memory polygon in Laravel feature tests. Full-stack Admin testing still
  requires the verified perimeter and a qualifying on-campus location. No
  Laravel bypass is provided.

## Validation results

Commands run from `C:\ucu_smart`:

| Command | Result |
|---|---|
| `flutter analyze` | Passed; no issues found. |
| Targeted geofence/API/widget test command covering `api_config_test.dart`, `admin_auth_service_test.dart`, `building_api_service_test.dart`, `campus_access_gate_test.dart`, `campus_geofence_service_test.dart`, `dynamic_building_route_service_test.dart`, and `widget_test.dart` | Passed; all selected tests passed. |
| `flutter build apk --debug` | Passed. |
| `flutter test --concurrency=1` | 55 passed, 1 failed. The remaining failure is the pre-existing `test/route_service_test.dart` expectation for the route from building 1 to marker 31; the current route differs from the expected route. No route implementation or expectation was changed for this feature. |
| `flutter build windows` | Not available in this environment because the Visual Studio toolchain is missing. |

Commands run from `C:\xampp\htdocs\ucu-smart-backend`:

| Command | Result |
|---|---|
| `php artisan test` | Passed; 15 tests, 57 assertions. |
| `php vendor\bin\pint ...` for changed PHP files | Passed. |
| `php -l` for changed PHP/config/route/test files | Passed; no syntax errors. |

Production campus access cannot be enabled until the verified UCU boundary is
configured consistently in the Flutter build and Laravel deployment.

## Boundary configuration preparation update (November 10, 2026)

### Change made

Updated `README.md` to document the current Flutter boundary configuration and
the safe procedure for supplying a future approved polygon:

- The only Flutter boundary input is the compile-time
  `UCU_CAMPUS_BOUNDARY_JSON` define read by
  `lib/services/campus_geofence_service.dart`.
- The define has no UCU coordinate default. If it is omitted or empty,
  geofence status is `unconfigured` and protected access remains closed.
- The expected value is an ordered JSON list of `[latitude, longitude]`
  coordinate pairs. The polygon closes implicitly; a duplicate closing
  vertex is optional.
- The README provides a local PowerShell `$campusBoundaryJson` variable for
  future use with Flutter APK builds and debug runs. Its empty-value guard
  prevents invoking the documented Release build command before the complete
  approved polygon is supplied.
- The documentation describes existing parser checks and clearly notes that
  valid geometry does not establish that coordinates match UCU's real
  perimeter. The existing single-polygon format does not represent holes or
  multiple rings.

### Boundary evidence and safety

No coordinates were added. The Main Gate and candidate points A-D remain
reference points only and are not a complete campus boundary. No official or
independently verified perimeter, nor the red-outline reference, was available
for this update. Do not configure production access until a complete ordered
perimeter is obtained from an authoritative source or verified on-site,
reviewed against the UCU/UCNHS inclusion requirements, and approved.

This update changed documentation only. It did not modify the geofence
service, access gate, restriction screen, permissions, location acquisition,
Laravel, API, map assets, markers, or routing.

### Validation

Commands run from `C:\ucu_smart`:

| Command | Result |
|---|---|
| `flutter analyze` | Passed; no issues found. |
| `flutter test test\campus_geofence_service_test.dart test\campus_access_gate_test.dart` | Passed; all 34 tests passed. |

## Supplied 37-point Flutter boundary configuration (November 10, 2026)

### Changes made

- Added `config/ucu_campus_boundary.json` containing the 37 coordinate pairs
  supplied for the UCU campus perimeter. The pairs are stored in the exact
  supplied order and use `[latitude, longitude]`.
- Updated `README.md` with the explicit `--dart-define-from-file` commands for
  debug runs and Release APK builds.
- Added `test/ucu_campus_boundary_config_test.dart` to verify that the
  configured polygon passes the existing parser and retains all 37 coordinates
  in order.

`CampusGeofenceService` and `CampusAccessGate` were not modified. The existing
limits remain 30 m maximum reported GPS accuracy, 120 seconds maximum fix age,
and 15 m boundary clearance. The service's compile-time define still defaults
to empty; omitting the configuration file from a build preserves the existing
`unconfigured` fail-closed behavior. No fallback polygon or bypass was added.

The coordinate list is user-supplied. Its geometry passes the app's parser,
but that alone does not independently verify the legal UCU property boundary
or the intended treatment of neighboring areas.

### Validation

| Command | Result |
|---|---|
| `flutter analyze` | Passed; no issues found. |
| `flutter test test\campus_geofence_service_test.dart test\campus_access_gate_test.dart test\ucu_campus_boundary_config_test.dart` | Passed; all 35 tests passed. |
| `flutter build apk --release --dart-define-from-file=config/ucu_campus_boundary.json` | Passed; built `build\app\outputs\flutter-apk\app-release.apk` (53.6 MB). |

## Campus verification UI synchronization (November 10, 2026)

### Root cause

The shared restriction screen presented different status copy because
`GeolocatorCampusLocationProvider.isSupported` intentionally returns false on
Web and true on Android/iOS. The screen showed the unsupported-platform
information copy on Web, but showed the actual geofence state message on
Android. Additionally, retry feedback grouped some different Android location
errors under one generic message.

### Changes made

- Centralized the approved verification-screen copy in
  `lib/screens/campus_restriction_copy.dart` and used it from the shared
  `CampusRestrictionScreen`.
- Kept platform detection and geolocation behavior unchanged. The Web
  unsupported state displays the approved light-blue information card.
  Supported Android/iOS states retain the actual status/message; location
  failures use the warning treatment, and permission errors retain their
  specific permission guidance.
- Avoided showing the generic Location Services warning for permission
  denials, and avoided a duplicate orange warning for a genuinely unsupported
  platform.
- Added a widget regression test distinguishing unsupported platforms from
  supported-platform permission errors.

No geofence service/gate, boundary, accuracy/freshness/buffer thresholds,
permissions, retry action, fail-closed behavior, or backend validation was
changed.

### Validation

| Command/check | Result |
|---|---|
| `flutter analyze` | Passed; no issues found. |
| `flutter test test\campus_geofence_service_test.dart test\campus_access_gate_test.dart test\ucu_campus_boundary_config_test.dart` | Passed; all 36 tests passed. |
| `flutter build web --dart-define-from-file=config/ucu_campus_boundary.json` | Passed. Browser preview showed the shared layout and the single light-blue unsupported-platform information card. |
| `flutter build apk --release --dart-define-from-file=config/ucu_campus_boundary.json` | Passed; built `build\app\outputs\flutter-apk\app-release.apk` (53.6 MB). |

The Release APK was built but not installed or exercised on a physical Android
device. Supported-platform status behavior was verified with the Android-style
widget test; actual device GPS/permission behavior remains device-dependent.

## Release boundary define packaging fix (November 10, 2026)

### Investigation and root cause

- `config/ucu_campus_boundary.json` contains the exact 37 supplied coordinate
  pairs as a string under `UCU_CAMPUS_BOUNDARY_JSON`; the existing configuration
  test parses the polygon, confirms it is valid, and checks its complete ordered
  coordinate serialization.
- `CampusGeofenceService` reads that exact key with
  `String.fromEnvironment('UCU_CAMPUS_BOUNDARY_JSON')`. Its default remains
  empty, and `_refresh` returns `unconfigured` before GPS acquisition when the
  define is absent.
- The previous local Android Release APK had current UI strings, but its AOT
  native libraries did not contain the unique supplied perimeter coordinate
  strings. This means it had been packaged from a stale AOT snapshot that did
  not include the define; the APK file's recent timestamp alone did not prove
  the boundary was compiled into it. No Android device was connected, so the
  installed APK's hash/version could not be directly compared.
- A clean rebuild showed the full `-DUCU_CAMPUS_BOUNDARY_JSON=...` argument in
  the Flutter compiler invocation. The resulting APK contains the exact full
  boundary JSON in all packaged AOT libraries (`arm64-v8a`, `armeabi-v7a`, and
  `x86_64`).

### Fix and regression protection

- Added a test in `test/ucu_campus_boundary_config_test.dart` proving that a
  `CampusGeofenceService` instance without an injected polygon consumes the
  compile-time define: without it, the state stays `unconfigured`; with the
  supplied define, a synthetic fake fix is classified `outside` (not
  unconfigured and not granted).
- Updated `README.md` to run `flutter clean` and `flutter pub get` before a
  Release rebuild after define changes, then explicitly pass
  `--dart-define-from-file=config/ucu_campus_boundary.json`.
- No polygon coordinates, validation rules, thresholds, permissions, gate,
  backend, or bypass behavior were changed.

### Validation and current artifact

| Command/check | Result |
|---|---|
| `flutter analyze` | Passed; no issues found. |
| `flutter test test\campus_geofence_service_test.dart test\campus_access_gate_test.dart test\ucu_campus_boundary_config_test.dart` | Passed; all 37 tests passed without a define, including unconfigured/fail-closed behavior. |
| `flutter test --dart-define-from-file=config/ucu_campus_boundary.json test\ucu_campus_boundary_config_test.dart` | Passed; both tests passed and confirmed the service consumes the 37-point compile-time define. |
| Clean Release build with `--dart-define-from-file=config/ucu_campus_boundary.json` | Passed; AOT libraries contain the full configured polygon. |

The current Release APK is
`build\app\outputs\flutter-apk\app-release.apk`. Compare its SHA-256 with the
file transferred to the phone to ensure the installed copy is this build.
Flutter detected no attached Android device, so the installed package cannot
be verified from this environment.

APK SHA-256:
`30379524CEE73D6D669991E28D7A92F5644E8C530910F2676441D8DFCF694C52`

### User-facing incident summary

The reported `Campus boundary not configured` result does not mean the user
was detected outside campus. It means the running APK had no compiled
`UCU_CAMPUS_BOUNDARY_JSON` value, so the service stopped before requesting GPS.
The prior APK's interface strings were current, but its AOT libraries lacked
the perimeter, which identified a stale compiled snapshot as the packaging
root cause.

A clean Release build now includes the exact 37-point configuration. Reinstall
`build\app\outputs\flutter-apk\app-release.apk` and compare the installed
transfer copy against the SHA-256 above. Once running that build, an actual
outside-campus fix is classified using the existing accuracy, freshness, and
boundary-clearance policy. No connected Android device was available to verify
installation or live GPS behavior during this investigation.

## Automatic campus arrival detection implementation (November 12, 2026)

### Implemented behavior

- Added an isolated Android Geofencing API integration. It uses a coarse
  circular region derived from the existing 37-point `[latitude, longitude]`
  polygon only as an approximate ENTER/EXIT trigger. On ENTER, Android requests
  a new high-accuracy fix with cached fixes disallowed, then checks that fix
  against the registered polygon before any notification can be sent.
- The native check rejects missing/invalid fixes, fixes older than 120 seconds
  or timestamped in the future, accuracy above 30 m, outside points, and
  points within the existing reported-accuracy-plus-15 m boundary margin.
  The existing 0.5 m boundary-edge uncertainty check is also applied. Only a
  confirmed interior fix can issue the opt-in notification:
  “Welcome to Urdaneta City University! Tap to open UCU Smart+ Campus Map.”
  A failed or timed-out fresh fix fails closed and sends no notification.
- Location acquisition is bounded to 8 seconds, with a zero maximum cached-fix
  age. If Android cannot provide a qualifying fresh fix in time, no arrival
  alert is sent. Duplicate ENTER notifications are suppressed. EXIT only
  resets entry state and never sends an arrival notification; a later ENTER
  can verify and notify again.
- Added an authenticated-Student opt-in to the Campus Location Verification
  screen, with staged foreground/background location and notification
  permission handling. Disabling the setting, losing required permissions, or
  logging out removes the trigger registration.
- Notification taps resume or launch the existing app flow. After login when
  necessary, the app requests a fresh location verification through the
  existing `CampusGeofenceService.refresh(forceFresh: true)`. It opens the
  existing `/campus-map` route only after successful verification; otherwise
  it leaves the user on the existing restricted verification screen.
- Added best-effort process/reboot registration support. Native preferences
  persist opt-in and trigger state, not authentication tokens.

The geofence circle can trigger outside the actual campus polygon. A trigger,
notification tap, client GPS reading, Wi-Fi, or IP address is not proof of app
access and does not authorize Laravel endpoints. The background verification
is isolated to arrival-notification delivery and does not weaken or replace
`CampusAccessGate` or its foreground verification.

### Files changed

New Android and Flutter files:

- `android/app/src/main/kotlin/com/example/ucu_smart/CampusArrivalEventPolicy.kt`
- `android/app/src/main/kotlin/com/example/ucu_smart/CampusArrivalBoundaryPolicy.kt`
- `android/app/src/main/kotlin/com/example/ucu_smart/CampusArrivalManager.kt`
- `android/app/src/main/kotlin/com/example/ucu_smart/CampusGeofenceReceiver.kt`
- `android/app/src/main/kotlin/com/example/ucu_smart/CampusBootReceiver.kt`
- `lib/services/campus_arrival_service.dart`
- `lib/services/campus_arrival_navigation_handler.dart`
- `android/app/src/test/kotlin/com/example/ucu_smart/CampusArrivalEventPolicyTest.kt`
- `android/app/src/test/kotlin/com/example/ucu_smart/CampusArrivalBoundaryPolicyTest.kt`
- `test/campus_arrival_service_test.dart`
- `test/campus_arrival_navigation_test.dart`

Updated Android/Flutter files:

- `android/app/build.gradle.kts`
- `android/app/src/main/AndroidManifest.xml`
- `android/app/src/main/kotlin/com/example/ucu_smart/MainActivity.kt`
- `lib/main.dart`
- `lib/services/campus_geofence_service.dart`
- `lib/widgets/campus_access_gate.dart`
- `lib/screens/campus_restriction_screen.dart`
- `lib/screens/unified_login_screen.dart`
- `test/campus_geofence_service_test.dart`
- `test/unified_login_screen_test.dart`

The existing map image and map implementation, marker data, route graph and
route services, polygon/configuration, Laravel/backend, and `pubspec.yaml` were
not changed. The map asset SHA-256 remains
`9f02b5734d02b108f3e65a7dabdd9d679ed22b75dfe67ea3dbed43d1bc208fc2`.
The route-service SHA-256 values remain
`b23e2d9639014c40abe39a82db8940a5c70fe309879a118a8b22982154e91a8d` and
`7dd269adb4aefa58bf4be59418fc99851f6d87ec0b19c41b7a28f8d6349ad6c5`.

### Validation results

| Command | Result |
|---|---|
| `flutter analyze` | Passed; no issues found. |
| `flutter test test/campus_arrival_service_test.dart test/campus_arrival_navigation_test.dart test/campus_geofence_service_test.dart test/campus_access_gate_test.dart` | Passed; all selected tests passed. |
| `flutter test` | 144 passed, 1 failed. The existing Building 1-to-31 route expectation fails with a route-point mismatch; it was reproduced before this feature and was not changed. |
| `.\gradlew.bat :app:testDebugUnitTest --no-daemon` | Passed; Android debug Kotlin compilation and unit tests succeeded. |

The Android unit suite includes six polygon-fix classification tests and four
event-policy tests, covering outside, inside, inaccurate, stale/future,
boundary-uncertain, unavailable, duplicate, EXIT, and re-entry cases. These
are automated policy tests, not device geofence-delivery tests.

No Release APK was built. No Android device was available, so real background
fix acquisition, permission prompts, process recreation, reboot behavior,
notification delivery/tap, and force-stop limitations have not been verified
on-device. Android may delay or suppress geofence events due to Doze and
manufacturer battery policies; delivery after force-stop is not guaranteed.
Reboot re-registration is best-effort. The receiver uses a bounded fresh-fix
request; if the request times out, is canceled, lacks accuracy, or lacks
permission, the notification is suppressed. No cached fix is accepted.

Before distributing a Release APK, validate this build on supported Android
versions and multiple device vendors, covering ENTER/EXIT, duplicate events,
permission revocation, opt-in/logout cleanup, reboot, notification tap while
logged in and logged out, and fresh inside/outside/inaccurate/stale/uncertain
verification. Keep the existing 30 m accuracy, 120-second freshness, 15 m
boundary clearance, and fail-closed access behavior.

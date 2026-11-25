# UCU SMART+

Flutter campus navigation application for Urdaneta City University.

## Run with the Laravel API

Start the existing Laravel backend from PowerShell:

```powershell
Set-Location C:\xampp\htdocs\ucu-smart
php artisan serve --host=0.0.0.0 --port=8000
```

For Windows desktop, the app defaults to `http://127.0.0.1:8000/api`:

```powershell
Set-Location C:\ucu_smart
flutter run -d windows
```

For an Android emulator, the app defaults to `http://10.0.2.2:8000/api`:

```powershell
Set-Location C:\ucu_smart
flutter run
```

For a physical Android phone, connect the phone and development PC to the same
network, allow the development server through the PC firewall, and use the PC's
LAN IPv4 address instead of `127.0.0.1`:

```powershell
Set-Location C:\ucu_smart
flutter run --dart-define=API_BASE_URL=http://<PC_LAN_IP>:8000/api
```

Replace `<PC_LAN_IP>` with the development PC's actual LAN address. The same
`--dart-define=API_BASE_URL=...` option can override the default for any
platform. Android permits cleartext HTTP so local-LAN release builds can reach
the development server. Use HTTPS and disable cleartext traffic before
connecting the app to a production backend.

Admin sign-in uses `POST /api/login`, then confirms the returned account with
the authenticated bootstrap `GET /api/user` endpoint. These bootstrap routes
remain available when campus location is unavailable; all Admin data routes
remain protected by the app gate and server-side checks. Only a response whose
role is exactly `admin` opens the Admin dashboard. The Sanctum token is stored using secure storage and sent as a bearer token to
protected requests. Sign-out calls
`POST /api/logout` and clears local authentication state.

Student Login is separate from Admin authentication and uses the configured
Laravel API base URL. It sends the existing Student Portal username and
password to `POST /api/student/login`, validates/restores the student session
with `GET /api/student/me`, and signs out with `POST /api/student/logout`.
Student tokens are stored separately using secure storage and are not shared
with Admin authentication.

The Student Portal provides an API-backed dashboard, searchable room
availability by building, building room lists, room details, and a student
profile. It uses `GET /api/student/dashboard`,
`GET /api/student/buildings`,
`GET /api/student/buildings/{building}/rooms`, and
`GET /api/student/rooms/{room}`. Building and room records come from the API;
the Flutter app does not maintain a second copy of this data. Student screens
remain subject to `CampusAccessGate`. Verify the configured Laravel deployment
and its Sanctum migration before attempting live account authentication; mocked
Flutter tests do not establish production connectivity.

## Building management and Visitor map

Apply the additive Laravel migration once:

```powershell
Set-Location C:\xampp\htdocs\ucu-smart-backend
php artisan migrate --path=database/migrations/2026_10_19_000000_create_buildings_table.php
```

It creates a separate `buildings` table with unique codes, optional map
percentages, an optional existing campus-graph node, public/active flags, and
soft deletion. It does not alter users, the campus image, fixed markers, or
existing routes.

Admin management endpoints require a Sanctum bearer token and the authenticated
user's server-side `role` to be exactly `admin`:

- `GET /api/admin/buildings`
- `POST /api/admin/buildings`
- `GET /api/admin/buildings/{id}`
- `PUT /api/admin/buildings/{id}`
- `DELETE /api/admin/buildings/{id}` (archives using soft deletion)

Visitors use `GET /api/buildings` and `GET /api/buildings/{id}` and receive only
active, public records. The Flutter Admin Dashboard's **Manage Buildings**
screen supports search, create, edit, activate/deactivate, archive, and choosing
map percentages by tapping the existing campus image. Visitor map refresh and
search show those records; mapped buildings display separate dynamic markers.
Buildings without map points remain searchable and show their location details
without a marker.

Directions for a dynamic building require valid coordinates, selection of an
existing campus graph node, and an Admin confirmation that the building-to-path
connector is walkable. Routes then use the existing path graph between
configured connections. Buildings without that configuration do not offer
directions. This is not turn-by-turn guidance, and connector verification
depends on the Admin's real-world inspection.

## Campus geofencing

The app gates visitor map, Admin, and Student Portal pages. The
splash/bootstrap screen and sign-in flows remain available so users can reach
authentication and recover from permission/setup issues. Protected pages
require a fresh Android/iOS
location fix with accuracy of 30 m or better. A fix must also be farther from
the configured perimeter than its reported accuracy plus a 15 m safety buffer.
Points inside that uncertainty
band are restricted as ambiguous; they are not reported as outside. Fixes
expire after 120 seconds. Permission denial, disabled location services,
unsupported platforms, and unavailable or stale fixes also fail closed with a
retry/settings screen.

The supplied 37-point campus perimeter is stored in
`config/ucu_campus_boundary.json` as the `UCU_CAMPUS_BOUNDARY_JSON` build
define. The list is kept in the supplied order and uses `[latitude, longitude]`
pairs. The file is a build input, not a Dart fallback: builds that omit it
continue to report **Perimeter not configured** and keep protected access
closed. The supplied coordinates have not been independently surveyed or
compared in this code against a legal property record.

The GPS calibration/control-point documents contain individual measurements,
not the complete campus perimeter. Do not substitute those points or the
map's percentage coordinates for this polygon. The Main Gate and candidate
points A-D remain references only.

### Flutter boundary configuration

The Flutter service reads the compile-time `UCU_CAMPUS_BOUNDARY_JSON` define
from `lib/services/campus_geofence_service.dart`. Its default remains empty;
there is no hardcoded boundary fallback. To build with the supplied perimeter,
explicitly pass the checked-in JSON define file:

```powershell
flutter clean
flutter pub get
flutter build apk --release --dart-define-from-file=config/ucu_campus_boundary.json
```

For Release rebuilds after changing compile-time defines, clean generated Flutter
and Gradle outputs first so an old Android AOT snapshot cannot be reused.

For a debug device run:

```powershell
flutter run --dart-define-from-file=config/ucu_campus_boundary.json
```

Each pair is `[latitude, longitude]`; the 37 vertices are stored in the
provided order. The polygon closes implicitly from the last point to the first.
The define file is only applied when explicitly passed to a Flutter command.
Omitting it preserves the existing unconfigured, fail-closed behavior.

The existing parser requires at least three distinct, in-range geographic
vertices, non-zero area, no invalid adjacent edges, and no self-intersection.
It accepts an explicitly closed ring by removing a repeated final copy of the
first vertex. It can detect invalid geometry, but cannot determine whether
otherwise valid vertices trace the intended UCU property boundary. The current
model supports one simple polygon only; it does not support holes or multiple
separate rings.

The mobile defaults match the API: `UCU_CAMPUS_MAX_ACCURACY_METERS=30`,
`UCU_CAMPUS_MAX_FIX_AGE_SECONDS=120`, and
`UCU_CAMPUS_BOUNDARY_BUFFER_METERS=15`. These can be overridden using
`--dart-define` for each setting. Protected Campus Map, Student Portal, and
Admin pages remain unavailable in builds that omit the boundary define;
login/session bootstrap routes remain available.

### Visitor campus access

**Continue as Visitor** obtains a fresh foreground location fix and uses the
existing polygon verifier. The existing 30 m accuracy, 120-second freshness,
and 15 m boundary-clearance rules apply. A confirmed inside result opens the
existing Campus Map; otherwise the app shows **Restricted Area** and continues
checking automatically every 30 seconds while active and on app resume.

Reliable outside results are debounced: two consecutive qualifying outside
checks revoke an active Visitor session. Inaccurate, stale, unavailable, or
boundary-uncertain readings are not treated as proof of exit. After a successful
inside check, an existing Visitor session is retained during temporary
location loss for at most 120 seconds; if no new reliable inside fix arrives,
the app restricts access as unverified, not as outside.

Visitor mode does not create or require a Student account and does not grant
Student or Admin page access or protected API permissions. Student login and
other bootstrap routes remain available.
Background arrival notifications and their Android geofence registration are
not part of the current app.

#### Temporary development-only Campus Map bypass

For local Flutter Web development in Chrome only, opt in explicitly:

```powershell
flutter run -d chrome --dart-define=UCU_SMART_DEV_CAMPUS_MAP_BYPASS=true
```

This allows **Continue as Visitor** to open the existing Campus Map without a
local location check. It bypasses only the Flutter Campus Map location gate;
it does not grant Student or Admin access, change Laravel authorization, or
provide trusted campus-location evidence to protected APIs. Without the define,
normal geofence behavior remains active. The app combines the flag with
`kDebugMode` and `kIsWeb`, so it is limited to opted-in Flutter Web debug
builds. Android, desktop, and all Release builds cannot enable it, even if the
define is supplied. Do not use this option to validate campus access or
production geofence behavior.

For safe local UI/module tests without a verified perimeter, use the existing
Flutter tests' injected fake location provider and mocked HTTP client, plus the
Laravel feature tests' in-memory synthetic polygon. For interactive full-stack
Admin testing, use the official verified polygon and a real, sufficiently
accurate on-campus fix.

Windows desktop builds remain supported, but Windows has no configured
location provider in this feature and displays a clear unsupported-platform
state. Flutter unit/widget tests use an injected fake provider and test-only
polygon; the Laravel feature tests use a separate synthetic polygon and no
real location. These are the safe ways to exercise inside/outside/ambiguous
states. For manual Android emulator testing,
configure the verified polygon and use Android Studio's Emulator **Extended
Controls > Location** to send a real point well inside the safe interior, well
outside, and near the boundary. No production bypass or fake-coordinate
injection is provided.

The server applies campus checks to Admin API endpoints. `POST /api/login` is
public, while `GET /api/user` and `POST /api/logout` require Sanctum
authentication but not campus location headers. The public visitor
building-list/detail endpoints keep their existing public-building behavior.
Client coordinates are untrusted and can be spoofed; these checks validate the
evidence but do not provide device attestation or prevent a determined
GPS-spoofing client. Do not treat them as proof of identity or anti-fraud
protection.

## Verify

```powershell
Set-Location C:\ucu_smart
flutter analyze
flutter test test\api_config_test.dart test\admin_auth_service_test.dart test\building_api_service_test.dart test\campus_access_gate_test.dart test\campus_geofence_service_test.dart test\dynamic_building_route_service_test.dart test\widget_test.dart

Set-Location C:\xampp\htdocs\ucu-smart-backend
php artisan test
```

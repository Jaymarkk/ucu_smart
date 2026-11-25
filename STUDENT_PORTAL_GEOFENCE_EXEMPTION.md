# Temporary Student Portal Geofence Exemption

## Summary

Authenticated Students can access Student Portal pages without campus GPS or
geofence verification. This narrowly scoped exemption addresses platforms such
as Chrome where the configured location provider reports that verification is
unsupported.

The overall geofencing system remains enabled. Campus Map, Admin routes,
Visitor checks, and unauthenticated access to Student Portal routes remain
subject to the existing access gate.

## Exempted routes

The `CampusAccessGate` skips geofence monitoring and allows the page through
only when `StudentAuthService.isStudentAuthenticated` is true and the current
route is one of:

- `/student-dashboard`
- `/student/profile`
- `/student/room-availability`
- `/student/buildings/...`
- `/student/rooms/...`

The exemption is based on the app's existing verified Student authentication
state. Student login, session restoration, token validation, role/status
checks, Student API calls, and backend authorization were not changed.

## Routes that remain geofenced

- `/campus-map`
- Admin pages
- Visitor Campus Map access
- Student Portal routes when the user is not authenticated as an active
  Student

No global or development geofence bypass was added. The campus boundary, GPS
settings, thresholds, backend middleware, and all map/navigation behavior
remain unchanged.

## Implementation

- [`lib/widgets/campus_access_gate.dart`](lib/widgets/campus_access_gate.dart)
  — identifies authenticated Student Portal routes, skips geofence refresh
  and resume rechecks only for those routes, and otherwise retains existing
  gate behavior.
- [`test/campus_access_gate_test.dart`](test/campus_access_gate_test.dart)
  — verifies authenticated Student Portal access on an unsupported-location
  platform, confirms unauthenticated Student routes remain gated, and checks
  that Campus Map and Admin remain restricted.

## Validation

- `flutter analyze` — passed with no issues.
- Focused geofence gate, Student Portal, and map-bypass tests — passed:
  32 passed, 3 skipped.

This is a Flutter client-side access change for the Student Portal only. It
does not imply or create a backend geofence security guarantee.

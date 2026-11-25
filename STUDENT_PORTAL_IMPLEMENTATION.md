# UCU SMART+ Student Portal Implementation

## Summary

The Flutter app now includes a Student Portal backed by the existing Laravel
student API. Student authentication remains separate from Admin
authentication. Portal screens use the configured `API_BASE_URL` and fetch
building and room information from the API rather than maintaining local
campus records.

Student Portal pages remain subject to `CampusAccessGate` by default. A
separate debug-only, opt-in Student UI bypass is available for local testing
outside UCU after the Laravel API validates Student credentials and status. It
does not bypass Admin/visitor gating or backend middleware. No campus boundary
coordinates or production geofencing configuration were added or enabled.

## Features

- **Student Dashboard** — displays the authenticated student's profile,
  building and room totals, and availability metrics returned by the API.
- **Room Availability** — searchable building list with building codes,
  names, and room counts.
- **Building Details** — rooms belonging to the selected building.
- **Room Details** — room number/name, floor, capacity, building, and
  availability when returned by the API.
- **My Profile** — displays the authenticated student's profile.
- **Logout** — calls the Student logout endpoint and clears only the Student
  session; it does not clear Admin authentication.
- Loading, retryable error, and empty states are included in the portal UI.

## API Endpoints

The Flutter app uses the configured Laravel API base URL and the authenticated
Student Sanctum bearer token:

| Method | Endpoint | Purpose |
|---|---|---|
| `POST` | `/api/student/login` | Sign in with Student Portal username and password |
| `GET` | `/api/student/me` | Validate/restore the authenticated Student profile |
| `GET` | `/api/student/dashboard` | Retrieve dashboard totals and availability |
| `GET` | `/api/student/buildings` | Retrieve buildings for room availability |
| `GET` | `/api/student/buildings/{building}/rooms` | Retrieve rooms for a building |
| `GET` | `/api/student/rooms/{room}` | Retrieve room details |
| `POST` | `/api/student/logout` | Revoke the current Student token |

Building and room values are not hardcoded in Flutter. Student tokens remain
stored separately from Admin tokens using secure storage.

## Files

### Added

- `lib/models/student_portal_models.dart`
- `lib/widgets/student_portal_components.dart`
- `lib/screens/student_room_availability_screen.dart`
- `lib/screens/student_building_details_screen.dart`
- `lib/screens/student_profile_screen.dart`
- `test/student_portal_models_test.dart`
- `test/student_portal_test.dart`

### Updated

- `lib/services/student_api_service.dart`
- `lib/services/student_auth_service.dart`
- `lib/screens/student_dashboard_screen.dart`
- `lib/main.dart`
- `test/student_auth_service_test.dart`
- `test/widget_test.dart`
- `README.md`
- `STUDENT_LOGIN_CHANGES.md`

No Laravel files, database records, campus map assets, map markers, route
logic, or Admin authentication implementation were changed for this work.

To enable the Student-only UI bypass for local debug runs:

```powershell
Set-Location C:\ucu_smart
flutter run --dart-define=UCU_SMART_DEV_BYPASS_STUDENT_CAMPUS_GEOFENCE=true
```

The flag defaults to `false` and is ignored by profile/release builds.

## Validation

- `flutter analyze` — passed; no issues found.
- Focused Student Portal, Student authentication, and widget tests — passed.
- Dart format check for changed Dart files — passed; no formatting changes
  were needed.
- Full `flutter test` — 91 tests passed and 1 existing route-service test
  failed. `test/route_service_test.dart` expects a longer route segment than
  the current route implementation returns. Routing was left unchanged to
  preserve the requested scope.

Tests use mocked HTTP responses; they do not prove that the deployed Laravel
API has the same response shapes or that live Student authentication works.

## Remaining Checks

Before relying on the portal with real accounts:

1. Confirm the configured API base URL targets the intended central Laravel
   deployment.
2. Verify the Sanctum migration and Student API deployment status with the
   backend operator.
3. Check live dashboard, building, and room response shapes against the
   Flutter models.
4. Test with an authorized Student account on the intended Android device.
5. Resolve or separately investigate the failing route-service test without
   changing route behavior unintentionally.

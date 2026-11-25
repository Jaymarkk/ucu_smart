# Student Login and Campus Building API: Root Cause

## Summary

The Flutter app's working student sign-in and Campus Navigation building list
use the same API base URL, but they call different Laravel routes.

The running Laravel app at `http://127.0.0.1:8000` has the student login route
but does not register the public `GET /api/buildings` route requested by Campus
Navigation. A live request to that building URL returned HTTP 404. This explains
why the online building list cannot load from the main project, while student
sign-in can still use that same host.

No files were changed as part of this investigation.

## Existing Flutter requests

Both `StudentApiService` and `BuildingApiService` read `apiBaseUrl` from
`lib/services/api_config.dart`. If the app was built without an `API_BASE_URL`
override, the Windows/Chrome default is:

```text
http://127.0.0.1:8000/api
```

The requests then differ:

| Purpose | Request | Access |
|---|---|---|
| Student sign-in | `POST /api/student/login` | Public |
| Student building list | `GET /api/student/buildings` | Requires student authentication |
| Campus Navigation building list | `GET /api/buildings` | Intended to be public |

Campus Navigation calls `BuildingApiService.fetchPublicBuildings()` without a
student token. This is necessary for the visitor navigation flow.

## Laravel route and live response

The main project at `C:\xampp\htdocs\ucu-smart` registers
`POST /api/student/login` and the authenticated student route
`GET /api/student/buildings` in `routes/api.php`. It does not register a public
`GET /api/buildings` route.

The local server on port 8000 was running Laravel from that main project. A
request to:

```text
GET http://127.0.0.1:8000/api/buildings
```

returned **HTTP 404** with a route-not-found response. The student buildings
route returned **HTTP 401** without a token, consistent with its authentication
middleware.

There is a separate Laravel directory, `C:\xampp\htdocs\ucu-smart-backend`,
whose API source contains a public `/api/buildings` route. However, the live
server process is running the main project, and the separate backend's
environment points to database `ucu_smart_db`, while the main project points
to the existing `ucu_smart` database. Switching the Flutter URL to the separate
project would not reuse the existing main-project configuration as requested.

## Why student sign-in can work

Successful student sign-in confirms that the app can reach the Laravel host and
that the student login route can respond. It does not establish that the
separate Campus Navigation endpoint exists. The student route and public
building route are different paths with different middleware.

Authentication is not the reason for the Campus Navigation request's observed
404. That request targets an unregistered public route. Reusing the
student-authenticated buildings endpoint directly would also be unsuitable for
visitors, who do not have a student token.

## Response compatibility

The existing student API's building data uses fields such as `building_code`
and `building_name`. The navigation `BuildingRecord` parser expects `code`,
`name`, and `category`, and the navigation screen also filters records using
`is_active` and `is_public`.

The main project's current `Building` model uses fields including
`building_code`, `building_name`, `description`, and `image`; it does not
currently define `category`, `is_active`, or `is_public`. Thus, adding only a
route alias that returns the student endpoint's current payload would not
automatically satisfy the Campus Navigation parser and filtering logic.

The endpoint should return a JSON object with a top-level `data` array, with
each record mapped to the fields Campus Navigation expects. Any visibility rule
must be decided using existing project requirements; this investigation does
not assume that all database buildings should be exposed publicly.

## CORS and warning-text discrepancy

The live 404 response included `Access-Control-Allow-Origin: *`. An OPTIONS
preflight request also returned HTTP 204 and allowed the GET method and
`content-type` header. CORS is therefore not indicated as the cause of the
observed localhost request failure.

There is a discrepancy between the live request and the warning text reported
in Chrome. The live request returned HTTP 404, while the Flutter building
service maps an HTTP error to a message containing its status, such as
`The building request failed (HTTP 404).` The exact text
`Cannot connect to the building service. Check the network.` is used for an
HTTP client connection exception. The 404 confirms the missing-route problem
in this environment, but the exact error shown by the user's browser would need
to be reconciled against that browser's Network-panel request URL, status, and
Console message.

## Minimal recommended fix

Add a public `GET /api/buildings` route to the existing main Laravel project at
`C:\xampp\htdocs\ucu-smart`, using the existing `ucu_smart` database. Map its
existing building fields into the response shape consumed by
`BuildingApiService`, and define an explicit, approved rule for which records
are public and active. Keep the student-authenticated endpoint unchanged.

Do not point Flutter at the separate backend project or add a new backend.
Do not modify map markers, coordinates, GPS, routing, zooming, panning, or the
existing offline fallback.

## Files and runtime evidence inspected

### Flutter

- [`lib/services/api_config.dart`](lib/services/api_config.dart) — shared
  base-URL selection.
- [`lib/services/student_api_service.dart`](lib/services/student_api_service.dart)
  — student endpoint requests.
- [`lib/services/building_api_service.dart`](lib/services/building_api_service.dart)
  — public buildings endpoint and required response fields.
- [`lib/main.dart`](lib/main.dart) — Campus Navigation fetch and saved-location
  fallback.
- [`test/building_api_service_test.dart`](test/building_api_service_test.dart)
  — expected building payload shape.

### Main Laravel project

- [`routes/api.php`](../xampp/htdocs/ucu-smart/routes/api.php) — student routes;
  no public Campus Navigation buildings route.
- [`app/Http/Controllers/Api/StudentPortalController.php`](../xampp/htdocs/ucu-smart/app/Http/Controllers/Api/StudentPortalController.php)
  — authenticated student buildings response.
- [`app/Models/Building.php`](../xampp/htdocs/ucu-smart/app/Models/Building.php)
  — existing main-project building fields.

### Runtime

- Port 8000 was served by Laravel from `C:\xampp\htdocs\ucu-smart`.
- `GET /api/buildings` returned HTTP 404.
- `GET /api/student/buildings` without authentication returned HTTP 401.
- The building-list CORS preflight returned HTTP 204 with the expected
  localhost CORS headers.

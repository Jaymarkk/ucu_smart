# Flutter Web Building API Diagnostic

## Summary

Campus Navigation shows the saved campus locations because the public building
list request fails to connect to the configured API address. The offline
fallback remains active. No application files were changed during this
investigation.


## API address and endpoint

The Flutter app reads `API_BASE_URL` as a compile-time setting. When it is not
provided, the Windows/Chrome default is:

```text
http://127.0.0.1:8000/api
```

The building list request appends `buildings`, resulting in:

```text
GET http://127.0.0.1:8000/api/buildings
```

In Chrome, `127.0.0.1` refers to the computer running the browser. The source
code alone cannot confirm whether the currently running web build was built
with an `API_BASE_URL` override.

## Response format

Flutter expects a JSON object with a top-level `data` array. Each building
record must include `id`, `code`, `name`, and `category`; optional fields
include description, location details, map percentages, and route information.

The Laravel public controller returns buildings wrapped in `data` and filters
for active, public records. The Laravel feature test checks the response array
and verifies that inactive or private records are excluded. The building model
casts map percentages to numbers and active/public flags to booleans, matching
the Flutter model's parsing.

The actual live response body and status could not be verified because the API
was not listening on port 8000 during this investigation.

## Observed error and likely cause

The Flutter warning is the existing offline fallback. Its underlying
connection message is produced when Flutter catches an HTTP client connection
error.

In this environment:

- Nothing was listening on port 8000.
- Requests to `http://127.0.0.1:8000/api/buildings` and
  `http://localhost:8000/api/buildings` failed to connect.
- The Laravel source directory was present, but its API service was not running.

This confirms a connection failure at the default local address in the
investigation environment. It does not prove that the same cause is occurring
on the user's Chrome computer: the URL used by that build and its browser
network/console logs were not available.

## CORS and authentication

The checked-in Laravel configuration does not suggest CORS is the cause. The
framework's global `HandleCors` middleware is enabled by default, and the
framework CORS defaults cover API paths and allow origins, methods, and headers.
The Flutter request includes `Content-Type: application/json`, which may cause
a browser preflight, but those defaults permit it. A deployed configuration or
reverse proxy could differ and was not checked.

Authentication is not required for `GET /api/buildings`; the public route is
outside the authenticated Admin route group. Therefore, authentication
permissions do not explain this request's connection error.

## Recommended minimal check

1. Start the Laravel service on the same computer at port 8000, using the
   command already documented in the project README.
2. Retry Campus Navigation and confirm that
   `GET /api/buildings` returns HTTP 200 with a top-level `data` array.
3. If the backend runs on another computer, run or rebuild Flutter Web with
   `API_BASE_URL` set to the backend host that Chrome can reach. Do not use
   `127.0.0.1` for a backend running on a different computer.
4. If the request still fails, inspect the browser Network and Console panels
   for the actual request URL, HTTP status, and any CORS message.

## Files inspected

### Flutter

- [`lib/services/api_config.dart`](lib/services/api_config.dart) — API base URL
  override and platform defaults.
- [`lib/services/building_api_service.dart`](lib/services/building_api_service.dart)
  — HTTP request, response parsing, and error mapping.
- [`lib/main.dart`](lib/main.dart) — building-list loading and offline fallback.
- [`test/api_config_test.dart`](test/api_config_test.dart) — URL default tests.

### Laravel

- [`routes/api.php`](../ucu-smart-backend/routes/api.php) — public building
  routes and protected Admin routes.
- [`app/Http/Controllers/Api/BuildingController.php`](../ucu-smart-backend/app/Http/Controllers/Api/BuildingController.php)
  — active/public filtering and JSON response.
- [`app/Models/Building.php`](../ucu-smart-backend/app/Models/Building.php)
  — field casts.
- [`tests/Feature/BuildingManagementTest.php`](../ucu-smart-backend/tests/Feature/BuildingManagementTest.php)
  — public listing response test.
- `vendor/laravel/framework/config/cors.php` — framework CORS defaults. This
  file is in the installed dependency tree, not the application-owned
  configuration.

## Verification limits

No source files or database records were modified. The Laravel endpoint's
runtime response, live database contents, and the user's actual Chrome request
were not verified because the API service was not running and browser runtime
logs were unavailable.

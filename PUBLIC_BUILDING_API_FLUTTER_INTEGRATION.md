# Flutter Public Building API Integration

## Summary

Campus Navigation uses the existing Flutter `BuildingApiService` and shared
API base URL configuration to load public buildings from Laravel. It requests
`GET /api/buildings` without student authentication and parses the response's
top-level `data` array. The existing 35 saved campus locations remain in place
and are still available when the request fails.

The local Laravel API was verified at
`http://127.0.0.1:8000/api/buildings`. It returned HTTP 200 and the public
building `TEST` (code `B21`), with null map coordinates and no verified route.

## Flutter behavior

- Public building data is loaded through
  [`lib/services/building_api_service.dart`](lib/services/building_api_service.dart)
  using the existing API base URL from
  [`lib/services/api_config.dart`](lib/services/api_config.dart).
- The public request does not attach a student token or campus-location
  headers, so Visitors can load the list.
- The screen adds active, public API buildings to the searchable list while
  preserving the saved locations. API errors leave the saved list available
  and show the existing retry/fallback message.
- Selecting an API building opens its details. `location_details` is preferred;
  when absent or blank, `description` is shown. If neither is available, the
  screen displays “Location information is not yet available.”
- API buildings appear as map markers only when valid saved map percentages
  exist. A selected building offers directions only when it has valid
  coordinates, a verified connection, and a route-node ID present in the
  existing campus graph.

For the verified `TEST` response, `location_details` is null, `description` is
`TEST`, coordinates are null, and route verification is false. Thus it appears
in the list and details show `TEST`, but it creates no marker or directions.
No coordinates or route connections are fabricated.

## Compatibility note

The existing service and response parser already matched the endpoint: both
use the configured base URL, the public GET request, and the top-level `data`
array. The integration adjustment in
[`lib/main.dart`](lib/main.dart) corrected details precedence so `location_details`
is used before `description`, and requires the route node to exist in the
existing graph before presenting directions.

The README's local Laravel startup command was updated to use the main project
directory, `C:\xampp\htdocs\ucu-smart`, where the working API is served.

## Files changed

- [`lib/main.dart`](lib/main.dart) — location-information precedence, searching
  location/description fields, and validation of a route node against the
  existing campus graph.
- [`test/building_api_service_test.dart`](test/building_api_service_test.dart)
  — verifies the actual response shape parses and public fetching does not
  require authorization or location headers.
- [`test/widget_test.dart`](test/widget_test.dart) — covers the B21/TEST entry,
  details and no-marker/no-directions behavior; the 35-location fallback on
  API failure; and rejection of an unknown graph node.
- [`README.md`](README.md) — corrects the documented Laravel startup project
  path.

No Laravel files, database records, geofence behavior, saved locations,
existing map markers, map assets, zoom/pan behavior, or routing graph data were
changed.

## Verification

- Live `GET http://127.0.0.1:8000/api/buildings` — HTTP 200; response contained
  the expected `data` list and B21/TEST record.
- Browser CORS preflight for the public GET — HTTP 204; GET and the `accept` and
  `content-type` headers were allowed.
- `flutter analyze` — passed with no issues.
- `flutter test test\building_api_service_test.dart test\widget_test.dart test\dynamic_building_route_service_test.dart`
  — passed, 26 tests.

The UI behavior was verified with Flutter widget tests. The app was not launched
in Chrome as part of this verification.

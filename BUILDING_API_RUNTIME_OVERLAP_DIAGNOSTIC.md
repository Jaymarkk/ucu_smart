# Campus Navigation Building API Runtime Diagnostic

## Summary

The Campus Navigation screen starts one automatic public building-list request
per `CampusMapPage` initialization. Search and normal rebuilds do not issue
requests. Retry and Refresh are manual request entry points.

The screen prevents manual retries while its loading state is true. The HTTP
service now uses the installed `http` package's abortable request support, so
the existing 15-second timeout signals cancellation and waits for the request
to settle before the screen enables Retry or Refresh. Identical concurrent
public list requests are also coalesced by the service.

## Exact methods and flow

1. `CampusMapPage.initState()` calls `_loadDynamicBuildings()`.
2. `_loadDynamicBuildings()` sets `_loadingDynamicBuildings` to true, then
   awaits `_buildingApi.fetchPublicBuildings()`.
3. If an error is returned, `_loadDynamicBuildings()` sets loading false and
   records the error. The screen then displays the existing fallback warning
   with Retry.
4. The Campus Locations Refresh button is disabled while loading and invokes
   `_loadDynamicBuildings()` when enabled.
5. In `BuildingApiService._send()`, an `http.AbortableRequest` is sent and the
   15-second timeout covers both receiving response headers and reading the
   response body. On timeout, the service completes the request's abort trigger
   and waits for the abortable client to settle before reporting the timeout as
   a `BuildingApiException`.

Relevant files:

- [`lib/main.dart`](lib/main.dart) — `CampusMapPage.initState()`,
  `_loadDynamicBuildings()`, fallback/Retry display, and Refresh control.
- [`lib/services/building_api_service.dart`](lib/services/building_api_service.dart)
  — `fetchPublicBuildings()` and `_send()` request/timeout handling.
- [`lib/services/api_config.dart`](lib/services/api_config.dart) — shared API
  base URL selection.

## Duplicate and overlap assessment

- There is one automatic call from `initState()` for each created Campus Map
  state.
- Search, widget rebuilds, and app lifecycle/resume handling do not issue a
  building-list request.
- No automatic retry loop is present.
- Retry and Refresh intentionally call the same loader.
- Reopening the Campus Map creates a new state and makes a new initial request.
- Normal production construction uses the shared `BuildingApiService.instance`.
- While loading is true, Retry is not shown and Refresh is disabled. The timeout
  now waits for cancellation to settle before setting loading false.
- `fetchPublicBuildings()` coalesces concurrent requests with the same
  normalized search/category filters, including the unfiltered Campus Map
  request. The in-flight entry is cleared after success or failure, so Retry
  works after a timeout.

## Why Chrome may show the first request as pending

The locked dependency is `http` 1.6.0. Its web `BrowserClient` uses Fetch and an
`AbortController`; its `send()` wires the controller to an abortable request's
`abortTrigger`. The service now passes an `http.AbortableRequest`. The package's
IO client also supports abortable requests, preserving Android and other native
platform behavior without JavaScript-specific code.

The timeout callback completes the abort trigger and awaits the pending send
and response-body future to settle before surfacing the timeout. Thus the
screen does not re-enable Retry while that request is still in flight, assuming
the HTTP client honors the package's abortable-request contract.

## Implementation and verification

- [`lib/services/building_api_service.dart`](lib/services/building_api_service.dart)
  — abortable request and timeout cleanup, plus keyed single-flight handling
  for public building-list requests.
- [`test/building_api_service_test.dart`](test/building_api_service_test.dart)
  — concurrent request coalescing and timeout cancellation followed by a
  successful retry. The cancellation test client preserves and responds to the
  `AbortableRequest` contract.
- `flutter analyze` — passed with no issues.
- Focused building API and Campus Navigation widget tests — passed, 28 tests.
- Dynamic building route tests — passed, 3 tests.

Do not increase the timeout, remove Retry/Refresh, or alter saved locations,
map behavior, routing, GPS, geofence, authentication, or the backend.

## Browser-specific verification limits

Cancellation behavior was verified with an abort-aware test client and by
inspection of `http` 1.6.0's `BrowserClient` implementation. A deliberately
stalled Fetch was not run in Chrome, so removal of a pending entry from the
Chrome Network panel remains to be confirmed in a browser runtime.

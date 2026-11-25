# Building API Request Cancellation and Overlap Protection

## Summary

The public Campus Navigation building request now uses the installed
`package:http` abortable-request API. If the existing 15-second timeout expires,
the request's abort trigger is completed so supported clients can cancel the
network operation. The service waits for the request to settle before
returning the timeout error, preventing the screen from enabling Retry or
Refresh while that request is still cancelling.

Concurrent public building requests with the same normalized search and
category filters share one in-flight future. Once the request completes or
fails, its entry is removed, allowing a later Retry or Refresh to make a new
request.

## How browser cancellation works

The installed dependency is `http` 1.6.0. Its `BrowserClient` recognizes
`http.AbortableRequest`, listens to `abortTrigger`, and calls the Fetch
`AbortController`. The implementation uses this supported package API rather
than custom JavaScript. The package's IO client also supports abortable
requests, so the same code path applies to Android and other supported native
platforms.

The service timeout remains **15 seconds**. It covers both waiting for response
headers and reading the response body. On timeout, the service signals abort,
waits for the client request to settle, and then preserves the existing
timeout error message and offline fallback behavior.

## Single-flight behavior

`BuildingApiService.fetchPublicBuildings()` normalizes search/category values
and uses them as an in-flight request key. Calls with equivalent filters share
one future. The entry is cleared in `whenComplete`, covering both successful
responses and errors. A subsequent Retry or Refresh is therefore not blocked
by an earlier completed or timed-out request.

The existing UI Retry and Refresh controls, public endpoint, saved campus
locations, and B21/TEST building behavior are unchanged.

## Files changed

- [`lib/services/building_api_service.dart`](lib/services/building_api_service.dart)
  — abortable request handling, timeout cancellation and settlement, and keyed
  single-flight for public building fetches. The timeout remains 15 seconds by
  default; its duration can be shortened when constructing the service in
  tests.
- [`test/building_api_service_test.dart`](test/building_api_service_test.dart)
  — tests concurrent request coalescing, abort signaling on timeout, and a
  successful retry after cancellation.
- [`BUILDING_API_RUNTIME_OVERLAP_DIAGNOSTIC.md`](BUILDING_API_RUNTIME_OVERLAP_DIAGNOSTIC.md)
  — updated diagnostic describing the fix and remaining browser verification
  limit.

No map, marker, coordinate, routing, GPS, geofence, authentication, Laravel, or
database files were changed. The 35 saved campus locations and public `TEST`
(B21) record were not removed.

## Verification

- `flutter analyze` — passed with no issues.
- Focused building API and Campus Navigation widget tests — passed, 28 tests.
- Dynamic building route tests — passed, 3 tests.

The abort and retry behavior was tested using an abort-aware test client, and
the installed `http` 1.6.0 browser implementation was inspected. A deliberately
stalled Fetch was not run in Chrome; actual removal of a pending request from
Chrome DevTools remains unverified at runtime.

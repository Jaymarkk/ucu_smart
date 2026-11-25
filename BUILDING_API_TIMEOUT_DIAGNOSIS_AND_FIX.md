# Campus Map Building API Timeout: Diagnosis and Fix

## Summary

The Campus Map timeout was traced to the request Flutter Web made in Chrome, not to a slow Laravel buildings API or an invalid response format. The body-less public GET request included `Content-Type: application/json`, which is not a CORS-safelisted request header. From a different browser origin, that causes Chrome to issue a CORS preflight before sending the GET. The observed preflight response did not include the required allowed-methods and allowed-headers values.

The Flutter service now adds `Content-Type: application/json` only when a request has a JSON body. The Laravel endpoint, its response contract, and the database were left unchanged.

## Diagnosis

- The reported URL was `http://127.0.0.1:8000/api/buildings`, launched with `flutter run -d chrome`.
- A direct request to the Laravel endpoint returned HTTP 200 and valid JSON in approximately 0.9–2.7 seconds during probes. Its response was shaped as `{ "data": [...] }`.
- The sample response included the fields expected by Flutter, including `id`, `code`, `name`, and `category`.
- The observed OPTIONS response included `Access-Control-Allow-Origin: *`, but did not include `Access-Control-Allow-Methods` or `Access-Control-Allow-Headers`.
- Flutter's service had been adding `Content-Type: application/json` to every request, including GET requests without a body. This triggered the browser preflight.
- The service timeout remains 15 seconds. It was not increased because measured API response times did not justify changing it.

## Changes

- In `lib/services/building_api_service.dart`, send `Content-Type: application/json` only when the request includes a JSON body. The public GET remains unauthenticated and retains its `Accept: application/json` header.
- In `test/building_api_service_test.dart`, verify that the public GET omits `Content-Type` and that a JSON-body POST retains it.

## Validation

- `flutter analyze` — passed; no issues found.
- `flutter test test\building_api_service_test.dart test\widget_test.dart` — passed: 23 passed, 2 skipped, 0 failed.
- `flutter test test\building_api_service_test.dart` — passed: 6 passed, 0 failed.
- A live GET to the Laravel endpoint returned HTTP 200 with valid JSON.
- A Flutter Chrome app session could not be established during diagnosis, so the final UI behavior and Chrome network panel were not directly verified. Retry with `flutter run -d chrome`; in Chrome DevTools, confirm the public buildings request is a GET returning HTTP 200 without a preceding OPTIONS request.

## Scope and safety

- No Laravel source, API behavior, or database records were changed.
- No migrations, seeders, or destructive database operations were run.
- Existing map fallback, saved campus locations, markers, coordinates, routing, and authentication code were not changed.

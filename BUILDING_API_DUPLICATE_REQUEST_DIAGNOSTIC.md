# Campus Navigation Building API Request Diagnostic

## Summary

The Flutter source has one automatic public building-list request per
`CampusMapPage` state initialization. The same loader can also be called by the
existing Retry and Refresh controls. There is no automatic retry loop, and
typing in the building search does not call the API.

The reported first failure (~21 seconds) and later success (~2 seconds) are
consistent with an initial request that stalled or timed out followed by a
manual retry or refresh. Source inspection alone cannot establish that this is
what happened, nor identify the network-level cause. No files were changed for
this investigation.

## Request flow

1. `CampusMapPage.initState()` calls `_loadDynamicBuildings()`.
2. `_loadDynamicBuildings()` invokes
   `BuildingApiService.fetchPublicBuildings()`.
3. The service sends unauthenticated `GET /api/buildings` using the existing
   configured API base URL.
4. On failure, the screen preserves the saved campus locations, displays the
   existing fallback warning, and offers Retry. The Campus Locations panel also
   provides a manual Refresh control.

Relevant source:

- [`lib/main.dart`](lib/main.dart) — Campus Map initialization, request loader,
  fallback handling, Retry, and Refresh.
- [`lib/services/building_api_service.dart`](lib/services/building_api_service.dart)
  — public endpoint request and timeout/error handling.
- [`lib/services/api_config.dart`](lib/services/api_config.dart) — shared API
  base URL selection.

## Duplicate-request assessment

- **Search behavior:** does not make an API request.
- **Widget rebuilds:** do not call the request loader.
- **Lifecycle/resume:** there is no building-list lifecycle refresh.
- **Automatic retry:** none is implemented.
- **Manual retry/refresh:** each invokes the loader and intentionally starts
  another request.
- **Repeated screen creation:** disposing and reopening the Campus Map creates
  a new state and starts a new initial request.
- **Service instances:** normal app construction uses the shared
  `BuildingApiService.instance`. Tests and explicitly injected screens may use
  separate service instances; this does not establish that production creates
  two simultaneous requests.

## Timeout and observed timings

The HTTP send in `BuildingApiService` has a 15-second timeout. The code converts
a timeout into a building-service error. The browser request may remain visible
as pending depending on the underlying browser/client cancellation behavior.
If the user retries while that request is still in flight, the retry may
overlap it.

The DevTools observation (one failed request after approximately 21.05 seconds
and one successful request after approximately 2 seconds) does not by itself
show which UI action initiated the second request or why the first failed.
Possible causes such as connectivity delay, server readiness, browser network
handling, or a manual retry cannot be distinguished without the request
initiator and timing details.

## Recommended minimal correction

Do not remove Retry/Refresh or increase the timeout to mask the issue. First
inspect the Chrome Network panel's **Initiator**, request start times, status,
and Console output to determine whether the second request followed a user
retry/refresh or a second Campus Map initialization.

If evidence confirms overlap, consider a per-screen single-flight guard that
reuses the current in-flight load while preserving the explicit Retry/Refresh
behavior after it completes. If the first request remains pending after the
client timeout, separately verify whether the HTTP transport can cancel that
underlying request. No correction was applied pending runtime evidence and
approval.

## Verification limits

The source flow and 15-second timeout were inspected. The exact Chrome request
initiators, browser/client cancellation behavior, and server-side request logs
were not available, so the precise cause of the failed request remains
unconfirmed.

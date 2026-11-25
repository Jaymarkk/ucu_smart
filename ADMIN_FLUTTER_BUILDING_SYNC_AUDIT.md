# Admin-to-Flutter Building Synchronization Audit

**Audit type:** Read-only  
**Flutter project:** `C:\ucu_smart`  
**Laravel project:** `C:\xampp\htdocs\ucu-smart`

## Summary

The existing public buildings API and Flutter building-list integration are present. However, the current Laravel Add Building form does not provide a way to publish a building, while the public API only returns buildings whose `is_public` value is true. Consequently, a newly saved building that remains private is not returned to Flutter.

Git history identifies the original Admin action: a **“Public on Campus Navigation”** checkbox in the existing Add Building modal. It submitted the publication flag with the building form; it was not a background synchronization process. When enabled, the API could include that building, and Flutter would show it after refreshing or reloading its list.

The current report of a canceled Flutter Web request is not fully diagnosed. The Flutter service cancels the request when its 15-second timeout expires, but the reason the original Chrome request remains pending was not reproducible from the available browser session. No speculative timeout or networking change is recommended.

No source files or database records were changed during this audit. No migrations, seeders, rollbacks, resets, or destructive database operations were run.

## Current architecture and data flow

### Laravel Admin

1. The existing Add Building modal submits the building name, description, and optional image to the Admin building store route.
2. `BuildingController::store` validates the request, generates the building code, saves the building, and creates a linked `campus_locations` record if needed.
3. Newly created campus-location records have null map coordinates. This correctly avoids inventing a map marker.

### Laravel public API

- `GET /api/buildings` is registered as `api.buildings.index`.
- The public API controller filters records using `is_public = true`.
- Its response uses `{ "data": [...] }` and maps:
  - `building_code` to `code`
  - `building_name` to `name`
- It returns available campus-location details and only valid map coordinates. It does not invent routing information.

### Flutter

- `BuildingApiService` requests the public endpoint without student or Admin authentication.
- `BuildingRecord.fromJson` expects `id`, `code`, `name`, and `category`.
- The Campus Map loads public buildings, adds new active/public records to its existing locations list, supports search, and provides a refresh action.
- Selecting an API building displays available location information. A building without valid coordinates does not receive a marker; unverified route information does not enable directions.
- If fetching fails, the existing saved campus locations remain available and a Retry action is shown.
- The default Windows/Chrome API base is `http://127.0.0.1:8000/api`; a build-time `API_BASE_URL` override is supported.

## Original Admin publication action

Git history contains the original **“Public on Campus Navigation”** checkbox in the Add Building modal. It submitted an explicit `is_public` value:

- Checked: `is_public=1`, making the building eligible for the public API.
- Unchecked: `is_public=0`, leaving the building private.

The historical controller persisted that flag, and the public endpoint filtered on it. Flutter then fetched the published building through its existing API refresh/reload flow.

The separate publication status indicators and Publish/Unpublish list actions belonged to the broader interface that was later rolled back. They are not necessary to restore the original Add form action and are not recommended for restoration.

## Current synchronization gap

- The current Add Building form has no publication checkbox.
- The current store request validation does not accept `is_public`.
- The current store action does not set the submitted publication state.
- The public API excludes records where `is_public` is false.

Therefore, a newly added building that retains the private default will not appear in Flutter.

A prior read-only schema check in this workspace reported that `buildings.is_public` already exists and defaults to false. The live public API successfully queries this field. No schema change appears necessary based on the available evidence.

## Building API timeout investigation

### Verified

- The public API route is registered.
- A live request to `http://127.0.0.1:8000/api/buildings` returned HTTP 200 and valid `{ "data": [...] }` JSON during the audit.
- The observed response included the Flutter-required fields.
- The current Flutter GET sends `Accept` without a JSON `Content-Type` header, so that header alone should not trigger a CORS preflight.
- `BuildingApiService` uses a 15-second timeout and explicitly aborts its pending `AbortableRequest` when the timeout fires. The browser may then report the fetch as canceled.
- The service converts the timeout/abort into a generic building-service timeout message.
- Identical concurrent public-list requests are coalesced.
- The Campus Map page does not explicitly abort the request on disposal; its refresh action is disabled while loading.
- Flutter parses the body after the HTTP response arrives. JSON parsing does not explain a request that remains pending before a response.

### Not verified

The original user Chrome request and its browser Console details were not available for inspection. Therefore, the underlying reason that request remained pending has not been established. A canceled status alone does not distinguish an app timeout from an earlier browser, network, server, or runtime issue.

No timeout increase, API URL change, or Laravel CORS change is recommended without the actual failing request details.

### Evidence needed to continue diagnosis

From the actual Chrome DevTools Network entry, record only:

- Flutter page origin
- Request URL and method
- `Origin` and `Accept` request headers
- Whether a matching OPTIONS request appears, and its URL/status
- Canceled request status and total time
- Every Timing phase and duration
- The corresponding Chrome Console error, if any

Do not share cookies, authorization headers, tokens, HAR files, or copied cURL commands.

## Minimal proposed implementation

If implementation is authorized, the narrowly scoped restoration is:

1. Restore only the historical checkbox in `resources/views/admin/buildings/partials/add-modal.blade.php`.
2. Validate `is_public` in `app/Http/Requests/StoreBuildingRequest.php`.
3. Persist the selected boolean and provide an appropriate success message in `app/Http/Controllers/Admin/BuildingController.php`.
4. Add `is_public` to the fillable fields in `app/Models/Building.php`, preserving existing worktree changes.
5. Add an isolated Laravel feature test for published/private creation and public API visibility.

The existing API route/controller and Flutter fetching, search, and refresh code do not appear to need changes for the publication workflow.

Current Flutter detail messaging already indicates when a marker or verified route is unavailable. If stricter wording is required, a small copy-only adjustment and widget test could explicitly say the exact map location is not configured.

## Validation performed

- Flutter building API, dynamic route, and map/widget tests: **26 passed, 2 skipped, 0 failed**.
- Laravel `PublicBuildingEndpointTest`: **1 passed, 16 assertions** using isolated in-memory SQLite.
- Live public API request: **HTTP 200**, valid JSON, one public record observed.
- Laravel route list confirmed `GET /api/buildings`.
- The live API sample building had no map coordinates; Flutter must therefore list it without creating a marker or route.
- `flutter analyze` was not run during this read-only audit; no Flutter source was changed.
- A Laravel schema-inspection Artisan command could not render its output because the local PHP CLI lacks the `intl` extension. No schema-changing command was run.

## Scope and preservation

- No Laravel or Flutter source files were modified during this audit.
- No building, student, or other database records were modified.
- No migrations, seeders, rollbacks, resets, drops, truncates, or deletes were run.
- Existing Admin Add/View/Edit/View Rooms functionality was not changed.
- Student and Admin authentication, the Student API, the campus map, markers, coordinates, routing, and the temporary development geofence bypass were not changed.
- Existing unrelated Laravel worktree changes were inspected but left untouched.

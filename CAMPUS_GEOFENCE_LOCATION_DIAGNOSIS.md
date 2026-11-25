# Campus Geofence Location Rejection Diagnosis

**Project:** UCU SMART+  
**Diagnosis date:** 2026-11-12  
**Scope:** Read-only review of reported location rejections. No source code or campus coordinates were changed.

## Summary

The reported **82 m** and **45 m** location accuracy readings exceed the existing **30 m maximum accuracy**. The app therefore rejects those fixes as insufficiently accurate. These results do not establish that the user is outside the campus.

The **“Boundary location uncertain”** state means a fix passed the coordinate, freshness, and accuracy checks, but the fix's uncertainty overlaps the configured polygon boundary. The screenshot alone does not provide enough diagnostic data to determine how close that fix was to the boundary.

No evidence found in the inspected implementation indicates that swapped latitude/longitude order, polygon parsing, or the Android circular geofence trigger explains these foreground rejections. The configured polygon's structure and order were tested; those checks do **not** independently establish that it is an authoritative survey of UCU's actual perimeter.

## Findings

### GPS acquisition and accuracy

Flutter requests a high-accuracy fix with a 15-second timeout in [`campus_geofence_service.dart`](lib/services/campus_geofence_service.dart). A high-accuracy request is not a guarantee that the provider will return a fix with accuracy of 30 m or better.

The service validates the fix and its age, then applies the 30 m accuracy limit. Thus, the 82 m and 45 m readings are rejected by the existing threshold. They are not treated as proof of being outside campus.

### Freshness and boundary uncertainty

The existing maximum fix age is **120 seconds**. A fix must also meet the **30 m maximum accuracy** before polygon-boundary uncertainty is evaluated.

The uncertainty check uses the nearest polygon-edge distance and a **15 m buffer**. A fix is considered uncertain when its reported accuracy overlaps the boundary clearance (up to 45 m at the maximum accepted accuracy), or when it is within the implementation's 0.5 m edge tolerance. In this state, the app cannot safely distinguish which side of the perimeter the user is on.

The third screenshot does not include the fix's accuracy, age, coordinates, point-in-polygon result, nearest-edge distance, or calculated clearance. Therefore, the exact reason that particular fix fell within the uncertainty margin cannot be determined from the screenshot.

### Polygon parsing and coordinate order

The compile-time boundary configuration contains **37 coordinate pairs** in `[latitude, longitude]` order. The Flutter parser reads the first value as latitude and the second as longitude; GPS fixes use the provider's latitude and longitude fields in the same order. The configured-boundary test checks the point count and order in [`ucu_campus_boundary_config_test.dart`](test/ucu_campus_boundary_config_test.dart).

The point-in-polygon implementation uses ray casting. The nearest-edge distance uses a local latitude/longitude-to-meter approximation, which is appropriate for this small area and is not an apparent explanation for the reported accuracy rejections.

These are structural and implementation checks only. They do not prove that the configured coordinates are a verified or authoritative campus perimeter.

### Android geofence relationship

The Android circular geofence is an approximate event trigger, not the campus boundary and not proof of campus access. After an ENTER event, Android requests a fresh location and applies polygon and safety checks through [`CampusArrivalManager.kt`](android/app/src/main/kotlin/com/example/ucu_smart/CampusArrivalManager.kt) and [`CampusArrivalBoundaryPolicy.kt`](android/app/src/main/kotlin/com/example/ucu_smart/CampusArrivalBoundaryPolicy.kt).

This background flow is separate from the foreground Flutter verification message. A circular trigger can occur outside the polygon, but the trigger alone does not establish that the user is inside.

## Tests run

- `flutter test test\campus_geofence_service_test.dart` — **19 passed**.
- `flutter test --dart-define-from-file=config\ucu_campus_boundary.json test\ucu_campus_boundary_config_test.dart` — **2 passed**.
- Android `CampusArrivalBoundaryPolicyTest` — **passed**.
- An initial combined Flutter run supplied the configured-boundary define to a test that expects the default boundary to be unconfigured. That test failed under the mismatched test setup. Running the synthetic service tests without the define and the configured-boundary tests with the define separately passed.

These tests verify code behavior with synthetic fixtures and the configuration's structure; they do not verify a real-time device fix or independently certify the campus perimeter.

## Safe next steps

1. Do not relax the 30 m accuracy limit, 120-second freshness limit, or 15 m boundary buffer based on these screenshots.
2. Retry outdoors with a clear sky view, precise location enabled, and time for the device to obtain a better fix.
3. If the boundary-uncertain state persists, collect a diagnostic sample for that attempt:
   - fix timestamp and age;
   - reported accuracy;
   - point-in-polygon result;
   - nearest polygon-edge distance;
   - required uncertainty margin.
4. If diagnostics are added, keep them opt-in and debug-only, display data locally, and avoid persistent storage, uploads, or production logging of precise coordinates.
5. Before relying on the polygon for production restrictions, verify it against an authoritative campus perimeter source or a properly collected and approved perimeter survey. Do not substitute building points, map markers, or a geofence center for the perimeter.

## Files and changes

The diagnosis inspected the Flutter geofence service, configured boundary, relevant Flutter tests, and Android arrival-verification code. **No application source, polygon coordinates, map assets, routes, or backend authorization were changed as part of this diagnosis.**

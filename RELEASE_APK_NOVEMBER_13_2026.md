# UCU Smart+ Release APK — November 13, 2026

## Release artifact

- **APK:** `build/app/outputs/flutter-apk/app-release.apk`
- **Size:** 56,198,169 bytes (53.59 MiB)
- **SHA-256:** `4C7BB9DB10052C06CF547637BC0FD34B2440118A2D72F5A2B388B64FBCCA553E`
- **Build command:**

  ```powershell
  flutter build apk --release --dart-define-from-file=config\ucu_campus_boundary.json
  ```

- **Signing:** The current Android Release configuration signs with the
  project's debug signing key. This APK is not signed with a production key.

## Pre-build verification

- The formal Campus Access Restricted wording and status guidance are present.
- The restriction screen does not display the debug GPS diagnostics checkbox,
  panel, or diagnostic coordinates.
- Normal geofence policy is active: verified inside allows access, outside
  restricts access, and inaccurate, stale, unavailable, or boundary-uncertain
  results remain unverified/restricted.
- The configured boundary file exists and contains **37 coordinate pairs** in
  the configured order. The boundary test passed, and the first polygon
  coordinate was found in the Release AOT libraries for arm64-v8a,
  armeabi-v7a, and x86_64.
- No reverse-geofence testing flag or debug access bypass was found in app
  source/configuration.
- The Visitor session, Student/Admin authentication, campus map, markers,
  routing, and Laravel backend were not changed during this build request.

## Validation results

- `flutter analyze` — passed; no issues found.
- Focused Visitor, campus access, geofence, restriction UI, and widget tests —
  **55 passed**.
- Configured boundary tests — **2 passed**, including the 37-point order test.

## Build warnings and limitations

The Android build emitted Java source/target 8 obsolescence warnings and a
Geolocator Android deprecated-API note. The build completed successfully.

Physical-device GPS testing was not performed. Verify location permissions,
GPS accuracy, and real-device campus boundary behavior manually after
installing the APK.

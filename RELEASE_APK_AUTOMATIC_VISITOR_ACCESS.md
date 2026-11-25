# UCU Smart+ Release APK Preparation

Updated: November 12, 2026

## Release artifact

- APK: `build/app/outputs/flutter-apk/app-release.apk`
- Size: **56,198,169 bytes (53.6 MiB)**
- SHA-256: `F584B81ADC9B008D3966DF55338F9D2BE93B048C9075EAD7B0A9A3C3ADFB3CC7`
- Build command:

  ```powershell
  flutter build apk --release --dart-define-from-file=config\ucu_campus_boundary.json
  ```

- Signing: The APK uses the project's configured debug signing key, not a
  production release key.

## Pre-build verification

- Arrival-notification implementation, notification controls and tap
  navigation, and arrival-specific Android receivers are absent from the
  current app source.
- The Visitor verification UI does not provide the removed manual Retry
  Location Verification interaction.
- Visitor entry requires a fresh verification through the existing
  `CampusGeofenceService`.
- Active Visitor sessions use two consecutive reliable outside results before
  exit, 30-second foreground checks, and a check on app resume.
- Unavailable, inaccurate, stale, and boundary-uncertain readings do not count
  as proof of exit. A verified Visitor session has a 120-second temporary
  location-loss grace period.
- `config/ucu_campus_boundary.json` contains **37 points**. The configured
  boundary test passed, and the first configured coordinate was found in the
  Release APK's AOT libraries for arm64-v8a, armeabi-v7a, and x86_64.
- No debug bypass define is enabled in the Release build. The build command
  supplies only the campus-boundary define.
- Student and Admin authentication retain their role checks; Visitor access
  does not grant Student or Admin access.
- The Android manifest contains foreground `ACCESS_COARSE_LOCATION` and
  `ACCESS_FINE_LOCATION` permissions. It does not declare
  `ACCESS_BACKGROUND_LOCATION`, `POST_NOTIFICATIONS`, or
  `RECEIVE_BOOT_COMPLETED`, and has no arrival-specific receiver. The merged
  Release manifest retains Geolocator's location service.
- No map, route, or Laravel files were edited for Release preparation.

## Test results

- `flutter analyze` — passed; no issues found.
- Focused Visitor and access tests — **53 passed**.
- Configured-boundary tests — **2 passed**, including the 37-point order test.
- Android unit tests (`:app:testDebugUnitTest`) — passed.
- Full `flutter test` — **135 passed, 1 failed**.

### Existing route test failure

The unchanged Building 1-to-Marker 31 test expects:

```text
[(53,20.4),(38,20),(38,18),(34,16),(32.5,13)]
```

The current route implementation returns:

```text
[(53,20.4),(33,14),(32.5,13)]
```

The route implementation and test expectation were not changed.

## Limitations

- Physical-device testing was not performed.
- The APK is not signed with a production release key.
- The workspace does not contain Git metadata, so a repository diff could not
  be used to independently verify historical changes.

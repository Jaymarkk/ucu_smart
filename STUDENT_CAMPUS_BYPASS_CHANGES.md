# Student Campus Bypass Changes

> **Superseded:** The debug campus-access bypass described below has been
> removed. Current builds do not provide this bypass; see the current access
> behavior in [README.md](./README.md).

## Summary

The Student Portal was still showing **Verify Campus Location** because the
Student-only bypass is a compile-time flag, and the Android Studio
`main.dart` run configuration did not pass that flag. Its value therefore
defaulted to `false` when the app was launched from that configuration.

The Flutter campus gate now skips campus verification during the opted-in
debug Student login and authenticated Student Portal flow. The unsupported
Windows location provider no longer blocks Student Portal development.
Student login, Laravel API validation, Student role checks, and active account
status checks remain enabled. Admin and Visitor routes continue to require
campus verification.

## Modified Files

- `lib/widgets/campus_access_gate.dart` — skips geofence verification during
  the opted-in debug Student login and authenticated Student Portal routes;
  resumes the existing checks when navigating to Admin or Visitor routes.
- `.idea/runConfigurations/main_dart.xml` — passes
  `UCU_SMART_DEV_BYPASS_STUDENT_CAMPUS_GEOFENCE=true` when launching the
  Android Studio `main.dart` debug configuration.
- `test/campus_access_gate_test.dart` — verifies the Student-only gate behavior
  with an unsupported location provider and confirms Admin and Visitor routes
  remain restricted.
- `test/widget_test.dart` — tests Student login and dashboard navigation with
  the flag disabled and enabled.
- `README.md` — documents the debug launch flag and the need to restart the
  app after changing a compile-time value.

No Laravel or database files, map assets, marker coordinates, route graph,
navigation logic, or Admin authentication code were changed.

## Using the Development Bypass

Stop any running app, then start a new debug session with:

```powershell
Set-Location C:\ucu_smart
flutter run -d windows --dart-define=UCU_SMART_DEV_BYPASS_STUDENT_CAMPUS_GEOFENCE=true
```

The Android Studio `main.dart` debug run configuration also supplies this
define. The setting is compile-time, so hot reload will not apply a changed
value.

The bypass is opt-in and debug-only. It does not grant a token, skip Student
login, or bypass Laravel authorization. Admin and Visitor pages remain
geofenced. Profile and release builds do not honor the bypass.

## Validation

- `flutter analyze` — passed; no issues found.
- Relevant campus gate, Student login/navigation, authentication, and portal
  tests — passed (**34 tests**).
- Student login widget test with the bypass define enabled — passed.
- Android Studio run configuration XML — validated.

## Restoring Restrictions Before Production

The Student bypass defaults to `false` in builds where the
`UCU_SMART_DEV_BYPASS_STUDENT_CAMPUS_GEOFENCE` define is absent. Before
production:

1. Remove the Student bypass define from the Android Studio debug
   configuration.
2. Do not pass the define to any production or release build.
3. Keep the existing `CampusAccessGate` and geofencing implementation in
   place.
4. Verify the approved campus perimeter and production geofencing policy
   separately before enabling production campus restrictions.

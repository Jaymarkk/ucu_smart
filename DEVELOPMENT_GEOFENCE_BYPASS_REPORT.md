# Temporary Development-Only Campus Geofence Bypass

**Petsa:** 17 Nobyembre 2026  
**Project:** `C:\ucu_smart`

## Buod

Na-configure ang Campus Map bypass para sa normal na Flutter debug/development runs. Sa karaniwang `flutter run`, maaaring piliin ang **Continue as Visitor** at buksan ang Campus Map nang hindi hinihingi ang campus location verification.

Debug-only ang bypass. Naka-disable ito sa profile at release builds, kaya nananatili ang normal na production geofence policy.

## Paano gumagana

- Tinutukoy ng `campusMapDevelopmentBypassEnabled` sa `lib/services/campus_map_development_policy.dart` kung naka-debug mode ang kasalukuyang build at kung pinapayagan ang bypass.
- Default na `true` ang `UCU_SMART_DEV_CAMPUS_MAP_BYPASS` compile-time define para gumana ang plain `flutter run`. Maaari itong tahasang i-off sa debug gamit ang:

  ```powershell
  flutter run --dart-define=UCU_SMART_DEV_CAMPUS_MAP_BYPASS=false
  ```

- Hindi sapat ang define para ma-enable ang bypass sa profile o release: kailangan pa ring `kDebugMode == true`.
- Sa `lib/main.dart`, dumidiretso sa kasalukuyang Campus Map route ang Visitor action kapag aktibo ang bypass; hindi nito hinihintay o nire-refresh ang geofence.
- Nananatili ang Campus Access Gate at geofence service. Ang bypass ay isang policy condition para sa debug mode, hindi pag-aalis o pagpapalit ng normal geofence implementation.

## Login at navigation

- Nananatiling bukas ang Student at Admin login screens.
- Hindi binago ang Student Laravel API authentication, Sanctum token handling, secure storage, o session restoration.
- Hindi binago ang Admin authentication o authorization.
- Hindi binago ang Campus Map architecture, markers, coordinates, routes, assets, o campus boundary.
- Sa release/profile, ang Visitor at Campus Map ay nananatiling sakop ng geofence policy.

## Binagong files

1. `lib/services/campus_map_development_policy.dart` — ginawang default-on sa debug ang bypass; maaaring i-off sa compile-time define; nananatiling naka-gate sa `kDebugMode`.
2. `lib/main.dart` — idiniretso ang Visitor entry sa umiiral na Campus Map flow habang aktibo ang development bypass.
3. `test/campus_map_development_policy_test.dart` — sinubok ang debug default, debug opt-out, at release/profile rejection.
4. `test/widget_test.dart` — inangkop ang Visitor at login/dashboard widget expectations para sa bypass-on at bypass-off configurations.

Walang Laravel, database, o production configuration file na binago.

## Validation

- `flutter analyze` — **pumasa; walang issues**.
- Bypass naka-on:
  - **41 passed, 0 failed, 3 skipped** sa development bypass, visitor, widget, Student auth, at Admin auth tests.
  - Kasama sa mga test ang pagbukas ng Visitor sa Campus Map nang walang location request.
- Bypass naka-off gamit ang `--dart-define=UCU_SMART_DEV_CAMPUS_MAP_BYPASS=false`:
  - **39 passed, 0 failed, 3 skipped** sa policy, bypass, access-gate, at widget tests.
  - Kinumpirma ng normal Visitor geofence at protected-route tests na nananatili ang gate.
- `flutter build apk --release --no-pub` — **pumasa** at nakagawa ng release APK. Ang policy unit test ay nagpapatunay na hindi pinapagana ng release mode ang bypass kahit requested ang define. Hindi sinubukan ang APK sa aktuwal na device.

## Saklaw at limitasyon

Pansamantala itong development-only behavior para sa `flutter run`. Hindi ito dapat ituring na kapalit ng production campus geofence. Hindi binago o inalis ang CampusAccessGate, CampusGeofenceService, o campus boundary configuration. Hindi rin sinubukan ang GPS sa pisikal na device bilang bahagi ng validation na ito.

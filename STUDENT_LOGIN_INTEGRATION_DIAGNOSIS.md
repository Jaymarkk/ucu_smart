# UCU Smart+ Website Student Account to Flutter Login Diagnosis

**Petsa ng pagsusuri:** 17 Nobyembre 2026  
**Flutter project:** `C:\ucu_smart`  
**Laravel Website/Backend:** `C:\xampp\htdocs\ucu-smart`  
**Database na nakatakda sa Laravel environment:** `ucu_smart`

## Buod

May student login at session flow na sa Flutter, at pumasa ang mga napiling Flutter test para sa mocked API. Ngunit sa kasalukuyang Laravel source ng tinukoy na Website/Backend, walang rehistradong student API routes. Hindi rin nakikita roon ang Sanctum token issuance/revocation wiring o migration para sa personal access tokens.

Samakatuwid, **hindi mapapatunayan at hindi magagamit mula sa kasalukuyang Laravel source ang Flutter student login laban sa Website accounts**. May dokumentasyong nagsasabing student endpoints dati nang naipatupad; hindi ito tugma sa code at runtime route list na sinuri. Hindi matitiyak mula sa pagsusuring ito kung nasa ibang deployment o naunang code version ang implementation.

Hindi gumawa ng bagong authentication system. Walang binago sa application source o database records at walang migration na pinatakbo. Ang file na ito ang tanging nilikhang deliverable.

## 1. Website registration at student account

### Napatunayan sa source

- Gumagawa ang website student registration ng record gamit ang `App\Models\User`, sa default na `users` table.
- Itinatakda nito ang `role = student`, `status = pending`, at `username = student_id`.
- Kinakailangan ang walong digit na student ID at unique ito sa `users.student_id`; kailangan din ang unique na email.
- Hinahash ang password bago i-save at nagpapadala ng email-verification notification.
- Ang website login identifier ay `username`, hindi email. Para sa website-registered student, ang username ay student ID.
- Gumagamit ang website login ng Laravel authentication sa `username` at password. Hinaharang nito ang pending at rejected accounts; pagkatapos ng matagumpay na authentication, kailangan ding verified ang email at `status = active`.
- Ang model password cast ay `hashed`; ang registration code ay tumatawag din sa `Hash::make`.

### Mahahalagang implikasyon

- Hindi sapat ang matagumpay na registration para makapag-login: kailangang ma-verify ang email at ma-approve/ma-activate ang account.
- Ang Flutter username field ay tugma sa website username semantics kung student ID ang ipinasok. Hindi napatunayan ang pag-login gamit ang email o ibang identifier.
- Hindi sinuri ang database records o password hashes; walang live account credentials na ginamit.

## 2. Laravel student API at Sanctum

### Napatunayan sa kasalukuyang project

- Ang `bootstrap/app.php` ay nagrerehistro ng web routes, console routes, at health endpoint; hindi nito nirerehistro ang API routes.
- Walang `routes/api.php` sa project at walang API student controller na natagpuan.
- Ang `php artisan route:list --path=api/student` ay nagbalik ng walang tumutugmang routes.
- Walang `POST /api/student/login`, `GET /api/student/me`, o `POST /api/student/logout` sa kasalukuyang route list.
- May Sanctum package files sa `vendor`, ngunit ang `composer.json` at `composer.lock` na sinuri ay hindi nagpapakita ng Sanctum dependency. Hindi kasama sa kasalukuyang `App\Models\User` ang `HasApiTokens`; wala ring app route o controller code na tumatawag ng `createToken`, nagva-validate ng `auth:sanctum`, o nagre-revoke ng personal access token.
- Walang personal-access-token migration sa `database/migrations`.
- Dahil wala ang server endpoints at token wiring, hindi mapapatunayan ang aktuwal na API password verification, student-only server authorization, token creation/validation/revocation, API response profile shape, o kawalan ng account creation sa server login request.
- Ang Laravel model/provider at website registration ay tumutukoy sa iisang `User` model at `users` table. Ang `.env` at database config ay nagtatakda ng MySQL database na `ucu_smart`. Configuration evidence ito; hindi ito patunay na nakakonekta o nabasa ang aktuwal na database habang sinusuri.

### Pagkakaiba ng dokumentasyon at source

Ang [STUDENT_LOGIN_CHANGES.md](STUDENT_LOGIN_CHANGES.md) ay nagsasaad na may Sanctum student routes at may mga dating backend test. Hindi ito tugma sa kasalukuyang source files at sa aktuwal na `route:list` ng tinukoy na Laravel project. Ituring na **hindi beripikadong historical/deployment claim** hangga't hindi natutukoy ang eksaktong deployed code version.

## 3. Flutter student login at session

### Napatunayan sa source

- Ipinapadala ng Flutter JSON `username` at `password` sa `POST /api/student/login`.
- Inaasahan nito ang `access_token` at user profile sa response.
- Pagkatapos ng login, kinukuha nito ang profile sa `GET /api/student/me` gamit ang bearer token; sa logout, tumatawag ito ng `POST /api/student/logout`.
- Naka-implement ang persistent student-token storage sa `flutter_secure_storage`, sa hiwalay na key para sa student session.
- Sa session restoration, ipinapadala ang naka-save na token sa `/student/me`. Binubura nito ang expired/unauthorized token; sinusuri nito ang server response para sa `role = student` at `status = active`.
- Hindi iniimbak ang token hangga't hindi nakukumpirma ang profile. Kapag nag-logout, sinusubukan nitong tawagin ang server at nililinis din ang lokal na token/state.
- Kinukuha ang profile fields mula sa API at ginagamit ang current profile sa dashboard. Kinukuha rin ang dashboard data sa API.
- Walang registration request sa Flutter student login flow na sinuri.

### Limitasyon

Client-side role/status checks ay hindi kapalit ng server-side authorization. Dahil wala ang Laravel endpoints sa kasalukuyang source, hindi napatunayan ang end-to-end account login o ang server-side eligibility checks.

## 4. API host, browser, emulator, at pisikal na Android device

- May build-time `API_BASE_URL` override ang Flutter.
- Default sa Windows/desktop (kabilang ang Chrome target sa karaniwang desktop platform mapping): `http://127.0.0.1:8000/api`.
- Default sa Android emulator: `http://10.0.2.2:8000/api`.
- Para sa pisikal na Android phone, kailangang gamitin ang LAN IP ng development computer; hindi tumutukoy sa PC ang `localhost` ng telepono at hindi para sa pisikal na device ang `10.0.2.2`.
- May lokal na PHP server na nakita sa `127.0.0.1:8000`, mula sa tinukoy na Laravel project. Hindi ito nakikinig sa lahat ng network interfaces ayon sa process command line; kaya hindi ito naaabot ng phone sa LAN sa kasalukuyang bind address.
- Walang Android emulator o pisikal na Android device na nakita sa device enumeration. Hindi nasubukan ang network reachability mula sa mga iyon.
- Pinapahintulutan ng Android manifest ang cleartext HTTP, na angkop lamang sa lokal na development. Para sa production, gumamit ng HTTPS at huwag payagan ang cleartext traffic.
- Ang effective Laravel CORS configuration na nabasa sa runtime ay sumasaklaw sa `api/*` at pinapayagan ang origins, methods, at headers. Hindi CORS ang pangunahing naipakitang blocker sa lokal na configuration; wala kasing rehistradong student API routes. Maaaring iba ang configuration ng ibang deployment o reverse proxy.

## 5. Safe test results

Pinatakbo:

```powershell
Set-Location C:\ucu_smart
flutter test --no-pub --reporter expanded test\api_config_test.dart test\student_auth_service_test.dart test\campus_access_gate_test.dart
```

**Resulta: 30 passed, 0 failed.**

Saklaw ng mga test ang:

- API base URL defaults at override;
- mocked student login/profile/logout contract;
- token storage abstraction at session restoration;
- pagreject ng non-student at inactive profile;
- paghiwalay ng student at admin session;
- campus access gate behavior.

Mocked ang HTTP clients sa authentication tests. Kaya hindi pinatutunayan ng mga ito ang Laravel route availability, aktuwal na credentials, production connectivity, totoong secure-storage behavior sa installed device, o Android network access.

**Hindi pinatakbo ang Laravel test suite.** May `RefreshDatabase` ang mga umiiral na feature test; ang pagpapatakbo nito ay maaaring magpatakbo ng migrations, na ipinagbawal ng read-only na saklaw. Wala ring kasalukuyang Laravel student API test na nahanap sa test tree.

## 6. Pinakamaliit na inirerekomendang hakbang

1. Hanapin at ihambing ang dating kilalang student API implementation sa kasalukuyang `C:\xampp\htdocs\ucu-smart` source. Tiyaking ito ang tamang Website/Backend project at hindi ibang backend.
2. Kung ibabalik ang naunang implementation, panatilihin ang kasalukuyang Website `User`/`users` records at website credential semantics (`username`, na karaniwang student ID). Huwag gumawa ng hiwalay na user table o authentication system.
3. I-verify at aprubahan muna ang Sanctum dependency, token trait, API routes, at token-table migration plan. Huwag magpatakbo ng migration nang walang tahasang approval.
4. Ipatupad/beripikahin sa server ang password verification at student eligibility (verified email, `role = student`, `status = active`) para sa login at sa bawat protected student API call. Ibalik ang profile fields na inaasahan ng Flutter.
5. Kapag handa na ang API, subukan muna sa awtorisadong test account. Pagkatapos, hiwalay na kumpirmahin ang Chrome, Android emulator, at pisikal na Android host/network setup.

## Mga sinuring pangunahing file

### Flutter

- [lib/services/api_config.dart](lib/services/api_config.dart)
- [lib/services/student_api_service.dart](lib/services/student_api_service.dart)
- [lib/services/student_auth_service.dart](lib/services/student_auth_service.dart)
- [lib/screens/unified_login_screen.dart](lib/screens/unified_login_screen.dart)
- [lib/main.dart](lib/main.dart)
- [lib/screens/student_dashboard_screen.dart](lib/screens/student_dashboard_screen.dart)
- [lib/widgets/student_portal_components.dart](lib/widgets/student_portal_components.dart)
- [android/app/src/main/AndroidManifest.xml](android/app/src/main/AndroidManifest.xml)
- [test/api_config_test.dart](test/api_config_test.dart)
- [test/student_auth_service_test.dart](test/student_auth_service_test.dart)
- [test/campus_access_gate_test.dart](test/campus_access_gate_test.dart)

### Laravel Website/Backend

- [bootstrap/app.php](../xampp/htdocs/ucu-smart/bootstrap/app.php)
- [routes/web.php](../xampp/htdocs/ucu-smart/routes/web.php)
- [routes/auth.php](../xampp/htdocs/ucu-smart/routes/auth.php)
- [app/Http/Controllers/Auth/RegistrationController.php](../xampp/htdocs/ucu-smart/app/Http/Controllers/Auth/RegistrationController.php)
- [app/Http/Requests/Auth/LoginRequest.php](../xampp/htdocs/ucu-smart/app/Http/Requests/Auth/LoginRequest.php)
- [app/Http/Controllers/Auth/AuthenticatedSessionController.php](../xampp/htdocs/ucu-smart/app/Http/Controllers/Auth/AuthenticatedSessionController.php)
- [app/Models/User.php](../xampp/htdocs/ucu-smart/app/Models/User.php)
- [config/database.php](../xampp/htdocs/ucu-smart/config/database.php)
- [database/migrations/0001_01_01_000000_create_users_table.php](../xampp/htdocs/ucu-smart/database/migrations/0001_01_01_000000_create_users_table.php)
- [phpunit.xml](../xampp/htdocs/ucu-smart/phpunit.xml)

# Student Login and Portal — Flutter

## Implementation

Student Login uses the configured API base URL (`API_BASE_URL` or the platform
default). It is separate from Admin authentication and uses the Laravel Sanctum
student endpoints:

- `POST /api/student/login` with JSON `username` and `password`
- `GET /api/student/me` with the returned Sanctum bearer token
- `POST /api/student/logout` with the current bearer token
- `GET /api/student/dashboard`
- `GET /api/student/buildings`
- `GET /api/student/buildings/{building}/rooms`
- `GET /api/student/rooms/{room}`

The app validates the returned profile as `role: student` and `status: active`
before persisting the token. Student tokens use `flutter_secure_storage` under
a key separate from the Admin token; credentials and tokens are not logged.
Saved sessions are checked against `/student/me`. Student logout revokes the
server token and clears only the Student session. The Student Portal includes
an API-backed dashboard, searchable building availability list, building room
list, room details, and profile screen. Portal data is parsed into typed Dart
models and is not hardcoded in Flutter. Student pages remain subject to
`CampusAccessGate`; successful sign-in does not bypass campus restrictions.

## Changed files

- `lib/services/student_api_service.dart` — Student API requests, profile
  parsing, dashboard/building/room requests, and friendly HTTP/network errors.
- `lib/services/student_auth_service.dart` — Separate student authentication
  state and secure token storage.
- `lib/screens/student_login_screen.dart` — Validated username/password form,
  session restoration, and dashboard navigation.
- `lib/models/student_portal_models.dart` — Typed dashboard, building, and room
  response models.
- `lib/widgets/student_portal_components.dart` — Shared portal layout,
  loading/error/empty states, and Student sign-out controls.
- `lib/screens/student_dashboard_screen.dart` — API-backed dashboard.
- `lib/screens/student_room_availability_screen.dart` — Searchable building
  availability list.
- `lib/screens/student_building_details_screen.dart` — Building room list and
  room details.
- `lib/screens/student_profile_screen.dart` — Authenticated Student profile.
- `lib/main.dart` — Student authentication injection and portal routes.
- `test/student_auth_service_test.dart` — API contract, status errors,
  authorization, secure-store abstraction, restoration, and logout tests.
- `test/student_portal_models_test.dart` — Typed API response parsing tests.
- `test/student_portal_test.dart` — Mocked API and portal screen tests.
- `test/widget_test.dart` — Login validation, dashboard routing, sign-out,
  and campus-gate checks.

Admin authentication, Laravel source, database schema/data, campus map,
markers, and routes were not modified.

## Verification and rollout note

Flutter tests cover login/profile requests, dashboard/building/room API
requests, typed response parsing, portal loading/error/empty and success
states, secure token persistence/retrieval, session restoration,
non-student/inactive-profile rejection, Student-only logout, Admin auth
regression, and campus gating.

The backend Sanctum migration is reported as not yet approved/deployed. These
mocked-client tests do not establish that the real API, production database,
endpoint response shapes, or real-device sign-in is operational. Confirm the
central Laravel deployment and its approved Sanctum migration, compare the live
portal responses with the client models, and then validate with an authorized
test student before claiming production readiness.

## Central Laravel Sanctum deployment readiness audit

This audit was read-only. No migration was executed, no database records were
changed, and no credentials were displayed.

### Findings

- **Active database:** Runtime inspection of the central `ucu-smart` Laravel
  project confirmed the active connection is MySQL, connected successfully,
  and the selected database is `ucu_smart`.
- **Sanctum:** `laravel/sanctum` v4.3.3 is installed. The central Website
  `User` model uses `HasApiTokens`. There is no app-published
  `config/sanctum.php`; the installed package provides runtime defaults.
- **Personal access token migration:** The migration
  `database/migrations/2026_10_30_000000_create_personal_access_tokens_table.php`
  is pending on the connected database. Read-only runtime checks found no
  `personal_access_tokens` table and no matching migration record.
  Its `morphs('tokenable')` key is compatible with the Website `users.id`
  created by Laravel's `$table->id()`. The migration creates the normal Sanctum
  token fields and indexes. It must be run only against the reviewed central
  project and intended database.
- **Routes:** `POST /api/student/login` is public. `GET /api/student/me` and
  `POST /api/student/logout` use `auth:sanctum` and the `student` role
  middleware.
- **Login eligibility:** The API checks credentials using Laravel's configured
  web guard, requires a verified email, `role === student`, and
  `status === active`, and gives ineligible login attempts a generic 401.
  Logout revokes only the current token.
- **Authorization risk:** The current student middleware checks role but not
  current account status. A student's existing token may continue to access
  student routes after the account status changes from `active`. Add an
  active-status check to protected student routes before deployment.
- **Token lifetime:** The effective Sanctum global expiration is `null`, and
  student login sets no per-token expiry. Tokens have no configured time limit.
  A reasonable university-app baseline is a 30-day maximum (43,200 minutes)
  followed by reauthentication. Decide and configure the policy before release;
  a global Sanctum expiry affects all personal access tokens in this Laravel
  application.
- **Backup/recovery:** No backup artifact or documented recovery procedure was
  found in the inspected project/XAMPP tree. This does not establish that no
  external backups exist. Require an approved fresh backup and a successful
  restore rehearsal into an isolated database before applying the migration.

### Backend test evidence

`php artisan test --filter=StudentAuthenticationTest` passed: **14 tests,
54 assertions**. The feature test creates an in-memory SQLite schema and does
not modify the central database. Coverage includes student credential checks,
role/status/email eligibility, profile access, token revocation, rate limiting,
and existing Website login behavior.

### GO / NO-GO

**NO-GO for production migration or release at the time of this audit.**
Although the database target and pending migration were verified, first:

1. Enforce current `active` status on authenticated student endpoints.
2. Approve a token lifetime and configure/enforce it.
3. Confirm an approved backup exists and rehearse its restoration.
4. Review the migration plan and deploy during an approved window.
5. After deployment, verify migration status and test with an authorized
   student account without exposing credentials or tokens.

### Deployment commands for a later approved window

The following commands are documentation only; they were **not** executed.
Use a protected MySQL option file and backup destination managed by the
deployment operator; do not put credentials in the command line or repository.

```powershell
Set-Location C:\xampp\htdocs\ucu-smart

& C:\xampp\mysql\bin\mysqldump.exe --defaults-extra-file=C:\secure\mysql-backup.cnf --single-transaction --routines --triggers --events --databases ucu_smart --result-file=C:\secure-backups\ucu_smart_pre_sanctum_YYYYMMDD_HHMM.sql

php artisan migrate:status
php artisan migrate --pretend --path=database/migrations/2026_10_30_000000_create_personal_access_tokens_table.php
```

Verify the backup can be restored to an isolated database and review the
pretend output before obtaining explicit deployment approval. Only then apply
the migration:

```powershell
php artisan migrate --path=database/migrations/2026_10_30_000000_create_personal_access_tokens_table.php --force
php artisan migrate:status
```

Rolling back this migration drops `personal_access_tokens` and invalidates all
tokens stored in that table. Treat rollback or database restoration as an
approved recovery operation, not a routine step.

## Flutter Student Authentication integration audit

This was a read-only audit. No files were modified, and no credentials or
tokens were used or exposed.

### Configuration and API contract

- The Flutter API base URL comes from the build-time `API_BASE_URL`. If it is
  not supplied, the Android emulator default is
  `http://10.0.2.2:8000/api`. Physical Android devices must use the development
  computer's LAN IP, as described in the README.
- `StudentApiService` appends the student endpoints to that configured base:
  - `POST /api/student/login` sends JSON `username` and `password`.
  - `GET /api/student/me` sends the Sanctum bearer token.
  - `POST /api/student/logout` sends the Sanctum bearer token.
- Requests include JSON `Accept` and `Content-Type` headers.
- `StudentAuthService` stores the student token with
  `flutter_secure_storage`; its secure-storage key is separate from the Admin
  token key. Student and Admin authentication remain separate.
- The focused Student authentication tests passed: **9 tests**.

### Reachability and Android testing status

- The local host API on port 8000 responded. A no-token
  `GET /api/student/me` returned **401**, and a credential-free empty JSON
  login request returned **422**, consistent with protected profile access and
  required login fields.
- The central `ucu-smart` Laravel project registers all three student routes.
  The separate `ucu-smart-backend` project does not. Confirm that the central
  project—not the separate backend—is the server process used for the API.
- Flutter detected Windows and web targets, but no Android emulator or phone.
  Therefore connectivity from an Android device was **not verified**.
- The local API listener was bound to `127.0.0.1:8000`, which is not reachable
  by a physical phone over the network. For a phone test, serve the central
  project on `0.0.0.0`, allow the port through the development PC firewall,
  and run Flutter with:

```powershell
Set-Location C:\ucu_smart
flutter run --dart-define=API_BASE_URL=http://<PC_LAN_IP>:8000/api
```

Replace `<PC_LAN_IP>` with the development PC's actual LAN IPv4 address. Test
with an authorized test student only after confirming the server connects to
the central `ucu_smart` database and the Sanctum migration has been approved
and deployed. Local host probes and mocked tests do not prove Android-device or
production sign-in works.

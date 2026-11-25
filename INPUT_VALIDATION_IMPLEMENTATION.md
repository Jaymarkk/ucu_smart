    # Input Validation Implementation

    **Project:** UCU SMART+  
    **Updated:** November 12, 2026  
    **Scope:** Existing Flutter application forms and API error handling

    ## Summary

    Input validation was added to the existing login flows and documented existing
    Admin building form validation. The changes preserve the current Flutter,
    Laravel API contract, authentication behavior, and database operations.

    The workspace contains the Flutter project only. Laravel routes, controllers,
    Form Requests, and migrations were not present, so backend validation could not
    be inspected, implemented, or verified. The API must independently validate
    all submitted data; client-side checks are only for usability and are not a
    security boundary.

    ## Inputs reviewed

    | Screen / flow | Inputs | Validation |
    |---|---|---|
    | Shared login | Username/email identifier, password | Identifier is required; password is required. If the identifier is used for Admin sign-in, it must also be a valid email address. |
    | Student login | Student Portal username, password | Both required; existing login credentials are preserved without trimming or rewriting the password. |
    | Admin login | Email, password | Email is required, must match a basic email format, and is limited to 254 characters; password is required. |
    | Admin building create/edit | Building code, name, description, category, floor info, location details, map X/Y percentages, route node and status fields | Existing form requires applicable fields, enforces text limits and code syntax, accepts only finite map percentages in the 0–100 range, and requires X/Y coordinates as a pair. Optional fields remain optional. |
    | Student building search / room availability search | Search text | Search inputs are filters, not submitted records; empty search intentionally displays all available results. |
    | Profile | Read-only account fields | No editable profile inputs exist in the inspected screen. |

    No contact-number, account-registration, or password-change fields were found,
    so no unsupported validation rules or new inputs were added.

    ## Important changes

    ### Shared validators

    Added `lib/validation/input_validators.dart` with reusable required-field,
    email-format, and password-presence validators. Password length/complexity
    requirements were not invented because the existing API policy was unavailable.

    ```dart
    static String? requiredText(String? value, String label) {
      if (value == null || value.trim().isEmpty) {
        return '$label is required.';
      }
      return null;
    }

    static String? email(String? value) {
      final requiredError = requiredText(value, 'Email');
      if (requiredError != null) return requiredError;

      final address = value!.trim();
      if (address.length > 254 ||
          !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(address)) {
        return 'Enter a valid email address.';
      }
      return null;
    }

    static String? loginPassword(String? value) {
      if (value == null || value.isEmpty) return 'Password is required.';
      return null;
    }
    ```

    ### Form and API behavior

    - Applied the shared required-field and password validators to the unified and
      Student login forms.
    - Applied email and password validation to the dedicated Admin login form.
    - Failed local validation prevents the login request from being sent.
    - Student API `422 Unprocessable Entity` responses now surface field messages
      returned by Laravel. Unreadable or non-JSON responses use a safe fallback.
    - Existing Admin building form validation and successful-save feedback were
      retained; no backend payload or database behavior was changed.

    ## Modified files

    - `lib/validation/input_validators.dart` — reusable validation rules.
    - `lib/screens/unified_login_screen.dart` — username and password checks.
    - `lib/screens/student_login_screen.dart` — Student username and password checks.
    - `lib/screens/admin_login_screen.dart` — email format/length and password checks.
    - `lib/services/student_api_service.dart` — display Laravel-style validation
      messages for HTTP 422 responses.
    - `test/input_validators_test.dart` — required, email, and password validator
      tests.
    - `test/unified_login_screen_test.dart` — verifies empty login fields are
      rejected without API requests.
    - `test/student_auth_service_test.dart` — verifies API validation error mapping.
    - `test/widget_test.dart` — updates the expected shared-login field error.

    ## Test results

    - `flutter analyze` — passed; no issues found.
    - Focused input-validation and authentication tests — passed.
    - Full `flutter test` — 156 passed, 1 failed. The remaining failure is the
      existing Building 1-to-31 route expectation in `test/route_service_test.dart`.
      Route implementation and expectation were not changed as part of this task.

    ## Backend validation still required

    Before calling validation end-to-end complete, apply equivalent rules in the
    Laravel API. For every write endpoint, validate required fields, types, formats,
    length limits, authorization, and applicable uniqueness constraints on the
    server. Use Laravel validation/Form Requests and return the normal JSON `422`
    response shape. Check existing schema constraints and database state before
    adding unique rules or migrations. No Laravel source or database was changed
    for this Flutter-only implementation.

    ## Evidence screenshots

    No screenshots were captured in this workspace. The following views can be
    captured from the running app for the activity submission:

    1. **Empty fields:** open Login, leave both fields blank, press Login; capture
      the inline username and password errors.
    2. **Invalid email:** on the Admin Login screen, enter a malformed email and a
      non-empty password; capture the email format error.
    3. **Successful submission:** use a valid authorized test account against the
      configured backend and capture the resulting authenticated screen. Do not
      include credentials or tokens in the screenshot.
    4. **Backend validation error:** submit a controlled invalid test request that
      receives a Laravel 422 response and capture the displayed field message.

    Use authorized test accounts only and redact personal information before
    sharing screenshots.

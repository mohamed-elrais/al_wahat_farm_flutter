# Al Wahat Farm Operations

Flutter field-operations client for the Al Wahat farm, using the existing Supabase
tree/task workflow and the canonical coordinate geometry from the reference app.

## Configuration

Copy `config.example.json` to the ignored `config.json` and supply the public Supabase
project URL and anon/publishable key. Never place a service-role key in this app.

```sh
flutter run --dart-define-from-file=config.json
```

This project resolves and runs with Flutter 3.13.9 / Dart 3.1.5. A browser launch can
be selected explicitly with `flutter run -d chrome`. The iOS project is configured for
its existing iOS 11.0 target and Xcode 14.2-compatible pod releases. If CocoaPods reports
an encoding error when run directly, invoke it with a UTF-8 locale; Flutter's wrapper
handles the normal `flutter run` flow.

The immutable map renders from `assets/data/al_wahat_map_data.json`. Operational data
requires an authenticated active profile and farm membership.

## Verification

```sh
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

The ignored `config.json` may also contain disposable owner/engineer `TEST_EMAIL` and
`TEST_PASSWORD` values for the opt-in, read-only live hierarchy and QR gate. Run it
explicitly; it signs in through the public client, exercises the same RLS-scoped
repositories as the app, signs out, and never requires a service-role key:

```sh
flutter test test/integration/live_supabase_hierarchy_test.dart \
  --dart-define-from-file=config.json
```

The live gate intentionally enforces the declared 12 sections, 122 irrigation zones,
and 1,567 trees, then resolves one active real QR token without printing it. A failure
is a backend/product-data discrepancy, not permission to delete or deactivate rows
automatically.

See `REFERENCE_AUDIT.md`, `IMPLEMENTATION_PLAN.md`, and `FIDELITY_CHECKLIST.md` for
verified reference facts, phase gates, and known blockers.

# Al Wahat Farm Operations

Flutter field-operations client for the Al Wahat farm, using the existing Supabase
tree/task workflow and the canonical coordinate geometry from the reference app.

## Configuration

Copy `config.example.json` to the ignored `config.json` and supply the public Supabase
project URL and anon/publishable key. Never place a service-role key in this app.

```sh
flutter run --dart-define-from-file=config.json
```

This project resolves and runs with Flutter 3.44.7 / Dart 3.12.2. A browser launch can
be selected explicitly with `flutter run -d chrome`. The iOS project targets iOS 15.0
and uses Flutter's Swift Package Manager integration for native plugins, so CocoaPods
and the system Ruby are not required for this app.

Build and validate the iOS release with:

```sh
flutter build ios --release --no-codesign \
  --dart-define-from-file=config.json
```

For App Store distribution, sign in to the Apple Developer account in Xcode, select
the Runner team's signing configuration, increment the version/build number, and run:

```sh
flutter build ipa --release --dart-define-from-file=config.json
```

Immutable map geometry renders from `assets/data/al_wahat_map_data.json`. Trees,
planting pits, section counts, and irrigation-zone UUIDs come from the authenticated
Supabase hierarchy or its private offline cache. Regenerate and audit geometry with:

```sh
python3 tool/generate_map_data.py --audit-only
python3 tool/generate_map_data.py
```

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
and the current authoritative tree/pit snapshot, then resolves one active real QR
token without printing it. A failure is a backend/product-data discrepancy, not
permission to delete or deactivate rows automatically.

See `REFERENCE_AUDIT.md`, `IMPLEMENTATION_PLAN.md`, and `FIDELITY_CHECKLIST.md` for
verified reference facts, phase gates, and known blockers.

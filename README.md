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

See `REFERENCE_AUDIT.md`, `IMPLEMENTATION_PLAN.md`, and `FIDELITY_CHECKLIST.md` for
verified reference facts, phase gates, and known blockers.

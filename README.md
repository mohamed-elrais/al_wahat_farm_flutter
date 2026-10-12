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

Immutable map geometry renders from `assets/data/al_wahat_map_data.json`. Trees,
planting pits, section counts, and irrigation-zone UUIDs come from the authenticated
Supabase hierarchy or its private offline cache. Regenerate and audit geometry with:

```sh
python3 tool/generate_map_data.py --audit-only
python3 tool/generate_map_data.py
```

## Verification

```sh
# lib/l10n/gen holds raw `flutter gen-l10n` output, which is not dart-format clean.
dart format --output=none --set-exit-if-changed \
  lib/app lib/core lib/features lib/shared lib/main.dart test integration_test test_driver
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

## Web / PWA

The same app runs as an installable, offline-capable Progressive Web App, hosted on
Cloudflare Pages:

- Production: https://al-wahat-farm.pages.dev
- Staging: https://staging.al-wahat-farm.pages.dev

Don't link users to `*.netlify.app`: Netlify's site addresses are unreachable in
Egypt without a VPN, which is why the app moved to Cloudflare. See
`PWA_IMPLEMENTATION_PLAN.md` for the decisions and verification evidence.

Build and deploy (Node from `.nvmrc` is used only for the Cloudflare CLI):

```sh
./tool/build_web.sh                # build/web; compiles in only SUPABASE_URL + anon key
./tool/deploy_web.sh staging       # build, deploy, then verify every cached file
./tool/deploy_web.sh main          # production
CSP_MODE=report ./tool/deploy_web.sh staging    # Content-Security-Policy report-only (debugging)
```

The Content-Security-Policy (`tool/hosting/_headers`) is enforced by default. When a
feature needs a new origin or scheme, deploy staging with `CSP_MODE=report`, use the
feature, and look for `securitypolicyviolation` reports in the console before changing
the policy.

`tool/verify_deploy.py <url>` checks a deployment on its own. Cloudflare answers a
missing file with `index.html`, so it checks content types, not only status codes.
Roll back from the Cloudflare dashboard (Pages → al-wahat-farm → Deployments).

To serve a build locally, run `cd build/web && python3 -m http.server 8080`.
`localhost` counts as a secure context; a LAN IP doesn't, so camera and offline mode
won't work from one. Test phones against staging instead.

How the web build differs from native:

- **Offline data:** sqflite runs on SQLite compiled to WebAssembly, stored in IndexedDB
  (`web/sqlite3.wasm`, `web/sqflite_sw.js`). Regenerate them only as described in
  `web/vendor/README.md`, because the wasm must match the pinned `sqlite3` package.
- **Third-party scripts** (ZXing) and the Arabic and Roboto fonts are served from
  this origin, so the app never contacts a CDN and starts offline.
- **One tab at a time:** a second tab shows "open in another tab". This protects
  the offline queue.
- **Updates:** a banner offers to reload when a newer build is deployed. Nothing
  reloads on its own.
- **Known limitations:** no background sync (queued work uploads while the app is
  open), no push notifications, and iPhone users should install the app (Share →
  Add to Home Screen) so the browser keeps its offline data. Emoji or scripts the
  bundled fonts don't cover need a connection to render.

See `REFERENCE_AUDIT.md`, `IMPLEMENTATION_PLAN.md`, and `FIDELITY_CHECKLIST.md` for
verified reference facts, phase gates, and known blockers.

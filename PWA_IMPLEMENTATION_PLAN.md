# Al Wahat Farm — Full PWA Support Plan

> **Audience:** an AI coding agent (and the human reviewing it) working in this repository.
> **Goal:** the existing Flutter app runs as an installable, offline-capable Progressive Web
> App with **every feature the native app has**: login, offline app-open, map, QR scan,
> issues + photos, tasks + evidence, inspections, reviews, schedules, inventory, offline
> outbox sync, Arabic/RTL. The Android/iOS builds must not regress.
>
> Baseline facts verified on **2026-10-11** at commit `dfb8980`.
> **User answers (2026-10-11):** host = ~~Netlify~~ → **Cloudflare Pages** (Netlify's `*.netlify.app` IPs are blocked in Egypt, N8; switch approved by the user, D10), served at the **domain root** (`--base-href /`),
> test device = **iPhone 11** (plus the Mac's desktop browsers and the local Pixel_4 Android
> emulator). See §1.5 and §5.

---

## 0. How to use this plan (read first, every session)

### 0.1 Status legend

| Marker | Meaning |
|---|---|
| `- [ ]` | Not done. |
| `- [x]` | Done **and** its verification ran and passed in this repo. Evidence is recorded in the phase's *Evidence* block. |
| `- [ ] 👤` | Needs a **human on a real device or browser** (camera, install prompt, iOS Safari, etc.). The agent must **not** check it. The human checks it, or tells the agent the result and the agent records it verbatim. |
| `- [ ] ⛔ Blocked:` | Attempted and failed. Write the reason, what was tried, and the exact error. Never delete a blocked note; append to it. |

### 0.2 Anti-hallucination rules (mandatory)

1. **One phase at a time, in order.** Do not start Phase N+1 until every non-👤 item in Phase N is `[x]` and its **Gate** passes. 👤 items may stay open, but must be listed under "Open human checks" in the progress tracker.
2. **Never check a box from memory or expectation.** Check it only after running the command or opening the file that proves it. Paste the proof (command plus the relevant output lines, or `file:line`) into the phase's *Evidence* block.
3. **Verify every package API against the installed source, not the internet or recall.** Before calling any package API, open it under `~/.pub-cache/hosted/pub.dev/<package>-<version>/` and cite `file:line` in the evidence. Versions are pinned by `pubspec.lock`; read the version from there.
4. **Toolchain is fixed:** Flutter **3.13.9**, Dart **3.1.5** (see `toolchain-constraints` memory). Do not raise the SDK constraint (`>=3.1.5 <4.0.0`). Before adding any package, run `flutter pub add <pkg> --dry-run` and record the resolved version. If it does not resolve, the package is not allowed.
5. **Do not copy web snippets from current Flutter docs.** They target newer Flutter (`flutter_bootstrap.js`, `{{flutter_js}}` tokens, `_flutter.loader.load`). **3.13.9 supports none of these** (verified: 0 occurrences of `flutter_bootstrap` in `flutter_tools/lib`). This repo's `web/index.html` uses the 3.13 API `_flutter.loader.loadEntrypoint({serviceWorker: {serviceWorkerVersion}})`. Keep it.
6. **Only use the build flags listed in §1.3.** They were read from `flutter build web -h` on the local SDK. Do not invent flags.
7. **Native must keep working.** Any `dart:html` / `dart:js_util` code goes behind a **conditional import** (`if (dart.library.html)`) with a VM stub. `flutter analyze` and `flutter test` (VM) must stay green after every phase.
8. **Report failures honestly.** If a gate fails, mark items `⛔ Blocked:` and stop. Do not weaken a test to make it pass. Do not mark a phase done "pending device test".
9. **Ask the user before** changing any decision in §2, adding a dependency not named in this plan, choosing a hosting provider, or deleting user data or stores.
10. **Commits:** only when the user asks. The repo convention is one commit per phase on `main`, message `PWA Phase N — <title>`.
11. **Localization:** every new user-visible string goes into **both** `lib/l10n/arb/app_en.arb` and `app_ar.arb`. Then run `flutter gen-l10n`. `test/unit/l10n_parity_test.dart` must pass.

### 0.3 Standard verification commands

Run these at the end of **every** phase (the "standard gate"):

```sh
# Read-only format check. lib/l10n/gen is excluded: the committed files are raw
# `flutter gen-l10n` output and are NOT dart-format clean (verified P0.2). Never run
# `dart format .` in write mode (it would rewrite the generated files).
dart format --output=none --set-exit-if-changed lib/app lib/core lib/features lib/shared lib/main.dart test integration_test test_driver
flutter analyze
flutter test
./tool/build_web.sh        # canvaskit, --no-web-resources-cdn, Supabase-only defines (P0.7)
git status --short lib/l10n/gen   # must be empty: builds regenerate gen-l10n output; it must match the commit
```

From Phase 2 onward, also run this (native regression). `flutter doctor` on 2026-10-11 shows the Android toolchain with a warning (`[!]`, SDK 36.1.0). If the APK build fails for toolchain reasons unrelated to the change, record the error as ⛔ and ask the user. Do not skip silently:

```sh
flutter build apk --debug --dart-define-from-file=config.json
```

To serve a release build locally:

```sh
cd build/web && python3 -m http.server 8080        # http://localhost:8080 counts as a secure context
```

Camera and service workers need a **secure context**. `localhost` is treated as secure, a LAN IP is not. For iPhone testing deploy to the **Cloudflare Pages staging branch** (P0.8), which works in Egypt without VPN:

```sh
./tool/build_web.sh
nvm use && npx --yes wrangler@4.149.0 pages deploy build/web --project-name al-wahat-farm \
  --branch staging --commit-hash "$(git rev-parse HEAD)" --commit-message "<phase/step>" --commit-dirty=true
# → https://staging.al-wahat-farm.pages.dev   (never pass --force again; see N13)
```
👤

---

## 1. Verified baseline facts (ground truth, do not re-derive)

Each fact below was checked on 2026-10-11. If code changes invalidate one, update the row and its date.

### 1.1 App and platform code

| # | Fact | Evidence |
|---|---|---|
| F1 | `lib/` has **no** `dart:io`, `dart:html`, `Platform.` or `kIsWeb` usage. Only tests use `dart:io`. | `grep -rnE "dart:io\|Platform\.\|kIsWeb\|dart:html" lib` returns nothing |
| F2 | Storage is **sqflite only**. `AppDatabase.open()` calls `getDatabasesPath()` + `openDatabase()`, schema v3, tables `cache_entries`, `outbox`, `pending_photos` (photo **BLOBs**). | `lib/core/database/app_database.dart:29-38` |
| F3 | **sqflite has no web plugin.** The web plugin list is `app_links, connectivity_plus, flutter_image_compress_web, image_picker_for_web, mobile_scanner, shared_preferences_web, url_launcher_web`. On web `AppDatabase.open()` throws, and `main.dart` silently falls back to **in-memory stores**, so **all offline data (cache, outbox, queued photos, inspection stations) is lost on reload**. | `.flutter-plugins-dependencies` (`plugins.web`), `lib/main.dart:25-42` |
| F4 | Only one explicit SQL transaction exists: inspection station persistence. | `lib/features/inspections/data/inspection_station_local_store.dart:36` |
| F5 | Connectivity uses `connectivity_plus` 4.0.2. On web it uses `navigator.onLine` + `online`/`offline` events (NetworkInformation API when present). `onLine == true` does **not** prove the backend is reachable. | `~/.pub-cache/.../connectivity_plus-4.0.2/lib/src/web/dart_html_connectivity_plugin.dart:13-29` |
| F6 | Sync is triggered only on connectivity regained, after an enqueue, and manually. **No lifecycle or visibility trigger exists** (no `WidgetsBindingObserver` / `AppLifecycleListener` in `lib/`). | `lib/features/sync/domain/sync_engine.dart:20-24,62-71` |
| F7 | Photos: `ImagePicker.pickImage` → `FlutterImageCompress.compressWithList(minWidth:1920,minHeight:1080,quality:84,jpeg,keepExif:false)` → 10 MiB cap. | `lib/features/issues/data/issue_photo_service.dart:17-42`, `lib/features/tasks/data/task_evidence_service.dart:17-42` |
| F8 | `flutter_image_compress_web` 0.1.4+1 needs a global `window.pica`. Its README tells you to add `<script src="https://cdn.jsdelivr.net/npm/pica@9.0.1/dist/pica.min.js">`. On web, `keepExif` and `rotate` are unsupported, and resize width is `min(minWidth, srcWidth)` with height kept by aspect ratio (different semantics from native). | `.../flutter_image_compress_web-0.1.4+1/README.md` (Web section + feature table), `lib/src/pica.dart:42-59` |
| F9 | `mobile_scanner` 4.0.1 web uses ZXing via JS interop (`@JS('ZXing.BrowserMultiFormatReader')`). Its README requires `<script src="https://unpkg.com/@zxing/library@0.19.1">`. On web: QR only, no `analyzeImage`, `scanWindow`, `returnImage` or overlay. | `.../mobile_scanner-4.0.1/README.md:63-67,15-20`, `lib/src/web/zxing.dart:12`, `lib/mobile_scanner_web_plugin.dart:12` |
| F10 | Scanner screen uses `MobileScanner(onDetect, errorBuilder)` and shows localized permission-denied and unavailable states. | `lib/features/map/presentation/scanner_screen.dart:96-100,143-170` |
| F11 | Auth is **email + password only** (`signInWithPassword`). No OAuth, magic link or redirect URLs are needed. | `lib/core/supabase/auth_repository.dart:14` |
| F12 | `supabase_flutter` 2.8.4 on web persists the session in `window.localStorage`. | `.../supabase_flutter-2.8.4/lib/src/local_storage_web.dart:4-17` |
| F13 | Routing: go_router 13.2.0, `initialLocation: '/splash'`. **No URL strategy is set**, so web uses the default **hash** URLs (`/#/tasks/…`). | `lib/app/router.dart:36-52`; `grep usePathUrlStrategy lib` returns nothing |
| F14 | Routes needing parity: `/splash /login /home /issues[/:issueId] /map[/tree/:treeId[/report-issue]] /scan /tasks[/create, /create-inspection, /reviews[/:taskId], /:taskId[/inspection]] /more[/failed-ops, /schedules[/new, /:planId], /inventory[/new, /item/:itemId[/edit]]]` | `lib/app/router.dart:55-204` |
| F15 | Task photos are shown with `Image.network` on Supabase **signed URLs**. With CanvasKit the storage responses must allow CORS. | `lib/features/tasks/presentation/task_photo_viewer.dart:35,241,325` |
| F16 | Arabic glyphs depend on **device system fonts** (`_arabicFallback`: Geeza Pro / Noto Sans Arabic / …). Bundled Inter and Libre Baskerville are Latin-only. | `lib/app/theme/app_theme.dart:4-11` |
| F17 | Brand: `paper #F8F4E9`, `card #FFFDF7`, `ink #173D28`, `green #285C36`, `orange #CC6637`. Title EN "Al Wahat Farm Operations", AR "عمليات مزرعة الواحة". 1024² icon sources `assets/icon/app_icon.png`, `app_icon_foreground.png`. | `lib/app/theme/app_tokens.dart:4-8`, ARB `appTitle`, `file assets/icon/*` |
| F18 | No push-notification dependency exists, so **push is out of scope** (nothing to reach parity with). | `pubspec.yaml` |
| F19 | Only bundled data asset: `assets/data/al_wahat_map_data.json` (112 KB). | `pubspec.yaml`, `du` |

### 1.2 Web scaffold and build output

| # | Fact | Evidence |
|---|---|---|
| W1 | `web/` is the untouched Flutter template: name `al_wahat_farm_flutter`, description "A new Flutter project.", colors `#0175C2`, default Flutter-logo icons, `apple-mobile-web-app-status-bar-style: black`, no `lang`/`dir`, no theme-color meta. | `web/index.html`, `web/manifest.json`, `web/icons/*` (5–21 KB default PNGs) |
| W2 | `flutter build web --release` **succeeds** on 3.13.9 in about 67 s. Output: `main.dart.js` 4.0 MB, `canvaskit/` 15 MB, total 22 MB. One warning about missing `CupertinoIcons` (not referenced in `lib/`, so it comes from a dependency and is harmless). | local run 2026-10-11 |
| W3 | The release build loads **CanvasKit from `https://www.gstatic.com/flutter-canvaskit/0545f87…`** and fallback fonts from **`fonts.gstatic.com`**. Both are cross-origin, so the **service worker does not cache them, and an offline cold start with CanvasKit fails**. `--no-web-resources-cdn` exists to serve them locally. **P0.3 (2026-10-11):** with `--no-web-resources-cdn` the CanvasKit CDN URL is gone, but `main.dart.js` (CanvasKit build) **still contains `https://fonts.gstatic.com/s/` (the engine's fallback-font base) and `https://fonts.gstatic.com/s/roboto/v20/KFOmCnqEu92Fr1Me5WZLCzYlKw.ttf`**; the HTML-renderer build contains 0 `gstatic` refs. → P1.15. | P0.3 evidence |
| W4 | The generated service worker (3.13) **precaches only CORE** = `main.dart.js`, `index.html`, `assets/AssetManifest.json`, `assets/FontManifest.json`. Every other same-origin file in `RESOURCES` is cached **lazily on first fetch**. Navigation to `/` is **online-first**, falling back to cache. A `postMessage('downloadOffline')` caches all remaining `RESOURCES`. Requests whose path is not a `RESOURCES` key (e.g. `/tasks/123`) are **not handled**, so path-style deep links fail offline. `install` calls `skipWaiting()`. | `flutter_tools/lib/src/web/file_generators/js/flutter_service_worker.js:9-17,83-160`; `flutter_tools/lib/src/build_system/targets/web.dart:611-617` |
| W5 | `flutter_launcher_icons` 0.13.1 (already a dev dep) supports `web: {generate, image_path, background_color, theme_color}` and updates `web/manifest.json`. | `.../flutter_launcher_icons-0.13.1/README.md:25-29,96-102` |

### 1.3 Verified toolchain and packages

| # | Fact | Evidence |
|---|---|---|
| T1 | `flutter build web` flags available on 3.13.9: `--web-renderer {auto,canvaskit,html,skwasm}` (default `auto` = HTML on mobile, CanvasKit on desktop), `--pwa-strategy {none,offline-first}` (default offline-first), `--[no-]web-resources-cdn` (default on), `--base-href`, `--csp`, `--[no-]source-maps`, `--dart2js-optimization`, `--wasm` (experimental, not used). | `flutter build web -h` |
| T2 | **`sqflite_common_ffi_web` 0.4.2+1 resolves** with the current lock (`sqlite3 2.1.0`). It would add `dev_build, io, pool, process_run, pub_semver`. | `flutter pub add sqflite_common_ffi_web --dry-run` → "Would change 6 dependencies" |
| T3 | `sqflite_common_ffi_web` README: run `dart run sqflite_common_ffi_web:setup` to write `web/sqlite3.wasm` + `web/sqflite_sw.js`. Persistence is IndexedDB. It is cross-tab safe **only via SharedWorker**; where SharedWorker is missing ("Android Chrome as of 2022-10-20") it falls back to a basic worker that is **not cross-tab safe**. Marked **experimental** ("slow, not fully tested"). The setup tool's wasm URL is hardcoded and must match the `sqlite3` package version. Integration recipe: `if (kIsWeb) { databaseFactory = databaseFactoryFfiWeb; path = '<name>.db'; }`. | `~/.pub-cache/hosted/pub.dev/sqflite_common_ffi_web-0.4.2+1/README.md` |
| T4 | Dart SDK `dart:html` provides `BroadcastChannel`, `StorageManager.persist()/persisted()/estimate()`, `BeforeInstallPromptEvent`, `document.visibilityState`/`onVisibilityChange`, `window.isSecureContext`. | `bin/cache/dart-sdk/lib/html/dart2js/html_dart2js.dart:1533,1869,10446,17832,29228-29239,32577` |
| T5 | Flutter 3.13.9 has `AppLifecycleListener`, `SemanticsBinding.instance.ensureSemantics()` and `usePathUrlStrategy()` (flutter_web_plugins). | `packages/flutter/lib/src/widgets/app_lifecycle_listener.dart`, `semantics/binding.dart:87`, `flutter_web_plugins/lib/src/navigation/url_strategy.dart:26` |

### 1.4 Facts NOT verified yet (must be verified in the named phase, never assumed)

| # | Unknown | Verify in |
|---|---|---|
| U1 | Whether Android Chrome now supports SharedWorker (the README's note is from 2022). The design must work **without** it. | P3 |
| U2 | Camera (`getUserMedia`) for the QR scanner inside an **installed iOS PWA** (standalone mode). | P4 👤 |
| U3 | Whether iOS Safari's `<input capture>` returns JPEG or HEIC to `image_picker_for_web`. | P4 👤 |
| U4 | Supabase Storage CORS headers on signed URLs for CanvasKit `Image.network`. | P4 |
| U5 | Map rendering performance (CustomPainter, ~1.5k trees) under CanvasKit vs HTML. No low-end Android phone is available, so measure on the **iPhone 11**. Low-end Android performance stays an **accepted, recorded risk** (§5). | P0 👤 |
| U6 | Whether `sqlite3.wasm`/`sqflite_sw.js` fetched by the worker are served from the SW cache when offline. | P5 |
| ~~U7~~ | **Resolved 2026-10-11:** Netlify, domain root. The production domain is not chosen yet; use `<site>.netlify.app` until the user names a custom domain. | §5 |
| U9 | ~~Whether the CLI applies headers~~ **Mostly answered by N7:** the 27.12.0 help says deploy processes headers from `netlify.toml` or `_headers`. The plan still uses `_headers` (works for drag-and-drop too). P8.4 `curl` confirms the live result. | P8 |
| ~~U10~~ | **Resolved (N10):** `*.wasm` is served as `application/wasm`. No header override needed. | — |
| U11 | iPhone 11 iOS version (decides which Safari features exist). | P0 👤 |
| ~~U12~~ | **Resolved P0.4b:** Pixel_4 emulator = Android 13 (`sdk_gphone64_x86_64`) with **Chrome 109.0.5414.123** (old, Jan 2023) + WebView. Usable for functional checks only. | P0.4b |
| U13 | **Cause found 2026-10-11 → see N8/D12.** Original note: this Mac's network can't reach `*.netlify.app` at all (ports 80/443 time out; `netlify.com` works). Whether the iPhone on cellular and on the same Wi-Fi, and **the field workers' networks**, can reach it. If workers' networks block `netlify.app`, a **custom domain** may help only if the block is name-based (it resolved to Netlify IP 63.176.8.218 and the IP itself is unreachable here, so an IP-level block would also affect a custom domain on Netlify). Raise with the user before P8. | P0.7 👤 / P8 |
| U8 | iOS eviction of IndexedDB for non-installed sites (WebKit policy) and whether `navigator.storage.persist()` is granted. | P2 👤 |

### 1.5 Netlify and local deploy environment (verified 2026-10-11)

| # | Fact | Evidence |
|---|---|---|
| N1 | Headers can be set in `netlify.toml` (`[[headers]] for = "/*" [headers.values] …`) **or** in a plain-text `_headers` file, which "should end up in the folder you're deploying" (the publish dir). Headers are global and can't be scoped per branch or deploy context. Custom headers don't apply to proxied or function responses. | https://docs.netlify.com/routing/headers/ |
| N2 | Netlify's default for static assets: browser `Cache-Control: public, max-age=0, must-revalidate`; edge `Netlify-CDN-Cache-Control: public, s-maxage=31536000, must-revalidate`. A new deploy invalidates the edge cache. So by default **every file is revalidated by the browser**, which suits Flutter 3.13's non-hashed filenames (W4). | https://docs.netlify.com/platform/caching/ |
| N3 | CLI: `netlify login`, `netlify link` (writes `.netlify/state.json`), `netlify deploy --dir=<dir>` (draft by default), `--prod` for production. The CLI reads the publish dir from `--dir`, then from `netlify.toml` at the project root. The docs don't say whether CLI deploys apply `netlify.toml` headers (→ U9). | https://docs.netlify.com/cli/get-started/ |
| N4 | `netlify deploy` **runs a build by default**. `--no-build` = "Do not run build command before deploying." `--alias` = "the string at the beginning of the deploy subdomain" (gives a stable draft URL, e.g. for update tests). Other flags: `--site`, `--message`. | https://github.com/netlify/cli/blob/main/docs/commands/deploy.md |
| N5 | `netlify-cli` Node requirements: 27.12.0 → `>=22.13.0`; **22.4.0–26.2.0 → `>=20.12.2`**; 17.x–21.x → `>=18.14.0`. nvm default is still 18.13.0. **Installed and verified 2026-10-11: Node v22.13.1 (nvm) + `netlify-cli/27.12.0 darwin-x64 node-v22.13.1`** at `~/.nvm/versions/node/v22.13.1/bin/netlify`. (An older `netlify` binary also exists under v18.19.1; don't use it.) `netlify status` reported **"Your session has expired"**, so the user must run `netlify logout && netlify login` 👤. | `npm view netlify-cli@<v> engines.node`; `nvm ls`; `netlify --version`; `netlify status` |
| N7 | Flags verified in the **installed 27.12.0** (`netlify deploy --help`): `-d, --dir <path>`; `--no-build` ("Only use this if you have no need for a build or your project has already been built"); `--alias <name>` ("predictable deployment URLs"; avoid reusing a deployed branch name, so `staging` is fine); `-p, --prod`; `-m, --message`; `-s, --site`; `--json`. Deploy steps listed by the help: build unless `--no-build`, upload, then "Process redirects and headers from netlify.toml or _redirects/_headers files". | `netlify deploy --help` (2026-10-11) |
| N8 | **Egypt block (2026-10-11).** User: the site works only through a VPN, and per Netlify support-forum reports the user found (June–July 2026; WE, Vodafone, Orange, Etisalat), this is an Egypt-wide issue with Netlify IPs **35.157.26.135** and **63.176.8.218**. *The forum reports are user-provided; the agent didn't open them.* **Verified from this Mac:** `*.netlify.app` (incl. `al-wahat-farm.netlify.app`) resolves only to those two IPs, and both time out on 80/443. Netlify's **load balancer IPs 75.2.60.5 and 99.83.231.61** (`apex-loadbalancer.netlify.com`) **are reachable and serve this site**: `curl --resolve staging--al-wahat-farm.netlify.app:443:<ip>` → `HTTP/2 200`, `server: Netlify`, for both IPs. | P0 evidence ("Egypt block") |
| N9 | Netlify external-DNS doc: for an **apex (root) domain**, the recommended record is ALIAS/ANAME/flattened CNAME → `apex-loadbalancer.netlify.com`; the fallback is an **A record → `75.2.60.5`**. **Subdomains** are told to use a CNAME → `<site>.netlify.app`, which in Egypt resolves to the **blocked** IPs. The doc doesn't cover A records for subdomains or certificate provisioning (separate HTTPS doc). | https://docs.netlify.com/manage/domains/configure-domains/configure-external-dns/ |
| N10 | Live header check via 75.2.60.5 (staging deploy `6acb8a9a…`): `/` 200 `text/html`; `/flutter_service_worker.js` 200 `application/javascript`; `/canvaskit/canvaskit.wasm` 200 **`application/wasm`** (U10 ✓); `/manifest.json` 200 `application/json`; **`/_headers` 404** (D10 post-build copy confirmed necessary); every response has `cache-control: public,max-age=0,must-revalidate` (N2 ✓) and **`x-content-type-options: nosniff`** (our `_headers` applied via CLI deploy, U9 ✓). | P0 evidence ("Egypt block") |
| N11 | **sslip.io stopgap tried (2026-10-11), HTTPS failed.** `al-wahat-farm.75-2-60-5.sslip.io` resolves to 75.2.60.5. The user ran the production deploy (`6acb9cf4b35357d04b5b7829`, ready) and set the custom domain (getSite: `custom_domain al-wahat-farm.75-2-60-5.sslip.io`, `ssl False`). **HTTP works without VPN** (`HTTP/1.1 200`, `Server: Netlify`). HTTPS serves Netlify's default `CN=*.netlify.app` cert, `showSiteTLSCertificate` returns `null`, and the user-run `netlify api provisionSiteTLSCertificate` → **`JSONHTTPError: Unprocessable Entity`** (no detail shown). HTTP-only is unusable for the PWA (SW, camera and install need a secure context). The agent's own attempts to change the domain or deploy to production were **blocked by the auto-mode permission classifier**, so the user ran them. | P0 evidence |
| N12 | **Cloudflare Pages (candidate free host, verified 2026-10-11).** Reachable from this Mac without VPN: `https://pages.dev` → 301 (104.18.20.135); a real project `https://cloudflare-docs-7ou.pages.dev` → **200** (188.114.97.7). Free limits: 20,000 files/site, 25 MiB/file, `_headers` ≤ 100 rules / 2,000 chars per line, 100 projects. No static-asset bandwidth limit stated. `_headers` goes in the output dir, uses the **same syntax as Netlify**, and "will not itself be served". CLI: `wrangler` 4.149.0 needs Node `>=22.0.0` (v22.13.1 ✓). `wrangler pages deploy [directory] --project-name --branch --commit-hash --commit-message --commit-dirty` (from `--help`). It warns macOS 12.6 < 13.5 for the **local Workers runtime**, which isn't used by `pages deploy`. Build fits: 30 files, largest 6.3 MB. Other hosts tested: GitHub Pages 200 (no custom headers), Firebase `web.app` reachable (Spark: 360 MB/day transfer), Vercel reachable (Hobby = non-commercial only), Render reachable. | https://developers.cloudflare.com/pages/platform/limits/ , https://developers.cloudflare.com/pages/configuration/headers/ , `npx wrangler@4.149.0 pages deploy --help` |
| N13 | **Cloudflare Pages live (2026-10-11).** `wrangler whoami` → OAuth login, account `c2b683a25dc2241b3b260e632cfe240c`. `wrangler pages project create al-wahat-farm --production-branch main` **without `--force` failed**: wrangler 4.149.0 "Delegat[ed] to the latest version of Cloudflare Pages, now part of Cloudflare Workers", autoconfig found no `package.json`, guessed "Framework: Static, Build Command: `npx hugo`", the build failed, and it left `wrangler.jsonc` (assets dir `public`) + `.wrangler/cache/` in the repo (both removed; `.wrangler/` gitignored). With **`--force`** → "Successfully created the 'al-wahat-farm' project". Wrangler says `--force` is needed only once; later commands run directly against Pages. Deploy `--branch staging` → 29 files + `_headers`, `https://b97e5725.al-wahat-farm.pages.dev`, alias **`https://staging.al-wahat-farm.pages.dev`**. For the first ~minute HTTPS failed (`sslv3 alert handshake failure`, cert not issued yet), then: cert `CN=al-wahat-farm.pages.dev`, issuer Let's Encrypt YE1. Without VPN, every path is `HTTP/2 200` with `cache-control: public, max-age=0, must-revalidate` and `x-content-type-options: nosniff` (our `_headers`). Types: `/` text/html, `flutter_service_worker.js` + `main.dart.js` application/javascript, `canvaskit.wasm` **application/wasm**, `manifest.json` + map JSON application/json. **SPA fallback:** unknown paths (`/tasks/123`, `/_headers`) return **200 with `index.html`** (identical SHA-256), so `_headers` isn't exposed, but **a missing asset returns HTML with 200, not 404**. P2/P5 checks must verify asset bytes/content-type, not just status. | P0 evidence ("Cloudflare Pages") |
| N6 | Local devices: **iPhone 11** (user), desktop Chrome on the Mac (`flutter doctor` ✓), Safari on macOS 12.7.6, Android emulator **`Pixel_4`** (`flutter emulators`). No physical Android phone. | user answer; `flutter emulators` |

---

## 2. Architecture decisions

Changing any decision requires user approval (rule 9). Record approval in the Decision Log (§5).

| ID | Decision | Rationale (from facts) |
|---|---|---|
| **D1** | **Web storage = `sqflite_common_ffi_web`**, swapped in via a conditional `databaseFactory` configurator. **All existing `Sqflite*Store` classes stay unchanged.** | F2/F3/F4: the SQL stores, BLOB photos and transactions keep working through the same `sqflite` API (T3). Rejected: `SharedPreferencesCacheStore` (localStorage ~5 MB, strings only, no outbox/BLOB/transaction semantics); sembast/IndexedDB rewrite (rewrites 4 stores and their tests). |
| **D2** | **Single active tab.** A `BroadcastChannel('awf-tab')` guard lets only one tab own the DB and SyncEngine. Other tabs show a localized "Al Wahat is open in another tab. [Use here]" screen. | T3/U1: without SharedWorker, IndexedDB-backed sqlite is not cross-tab safe. **Even with a SharedWorker**, each tab runs its own `SyncEngine`, so two tabs could drain the same outbox at once. The guard is therefore needed on every browser, not just Android. Backend idempotency (`SUPABASE_OFFLINE_IDEMPOTENCY.md`) is a safety net, not the design. |
| **D3** | **Keep hash URL strategy.** Do **not** call `usePathUrlStrategy()`. | W4: the 3.13 SW only serves `RESOURCES` keys and `/`. Hash URLs always request `/`, so every deep link and reload works offline with no server rewrites. |
| **D4** | **Renderer = CanvasKit, served locally** (`--web-renderer canvaskit --no-web-resources-cdn`) **plus a bundled Arabic font.** P0 measures map performance. If CanvasKit fails the P0 threshold on the low-end phone, propose `html` to the user (do not switch silently). | W3: CDN CanvasKit and Google-hosted fallback fonts break offline. CanvasKit matches the existing goldens and draws the CustomPainter map consistently. F16: CanvasKit ignores system fonts, so Arabic would be tofu offline unless a font is bundled. |
| **D5** | **Keep Flutter's generated service worker** (`--pwa-strategy offline-first`). After the first successful authenticated load, post `downloadOffline` so all `RESOURCES` are precached. **Vendor every third-party JS file into `web/vendor/`** (pica, ZXing). No CDN at runtime. | W4: the SW supports `downloadOffline`. Lazily cached files would otherwise miss the first offline cold start. F8/F9: the CDN scripts must be same-origin to be cached. |
| **D6** | **Update UX:** detect a new SW taking control and show a localized, non-blocking "Update available — Reload" banner. **Never auto-reload** (unsaved form drafts). | W4: `install` calls `skipWaiting()`, so the new SW activates immediately but the running JS is old until reload. |
| **D7** | **No background sync.** Sync runs on app open, on visibility (tab/app foreground), on `online`, after enqueue and manually. The UI states that queued work uploads when the app is open. | Flutter cannot run Dart inside the SW. Background Sync API support is not universal (notably iOS Safari), so there's no parity path. |
| **D8** | **Install UX:** Android and desktop Chromium use `beforeinstallprompt` (T4) through an "Install app" action in More. iOS gets localized "Share → Add to Home Screen" instructions. Already-installed is detected via `display-mode: standalone` / `navigator.standalone`. | Field workers need the installed app for durable storage (U8) and full-screen use. |
| **D9** | **Push notifications: out of scope** (F18). | Parity only. |
| **D10** | **Hosting: Cloudflare Pages, domain root** (user approved the switch from Netlify on 2026-10-11, replacing the original Netlify decision). Project **`al-wahat-farm`** (production branch `main`) → production **https://al-wahat-farm.pages.dev**, staging **https://staging.al-wahat-farm.pages.dev** (`--branch staging`). **Build locally** with Flutter 3.13.9 (`tool/build_web.sh`) and upload the prebuilt `build/web` with **`npx --yes wrangler@4.149.0 pages deploy`** (Node v22.13.1 via `.nvmrc`). Cloudflare never runs Flutter, and the project has no Git connection. Headers live in **`tool/hosting/_headers`** (same syntax on Cloudflare and Netlify), copied into `build/web/` **after** the Flutter build. **Production deploys (`--branch main`) are run by the user**; the auto-mode permission classifier blocks the agent from production deploys and DNS/domain/cert changes. | N8: `*.netlify.app` is unreachable in Egypt without VPN, and the free `sslip.io` workaround got no HTTPS cert (N11). N12/N13: `*.pages.dev` is reachable without VPN, HTTPS is automatic, `_headers` is compatible, it's free. Copying `_headers` after the build keeps it out of the SW `RESOURCES` (W4). *Superseded Netlify setup (site `al-wahat-farm`, id `d56be6c1…`, custom domain `al-wahat-farm.75-2-60-5.sslip.io`) still exists; the user may delete it.* |
| **D12** | **Egypt reachability: Cloudflare Pages `*.pages.dev`** (D10) needs no custom domain or VPN; verified from this Mac on an Egyptian ISP (N13). A custom domain is optional later; if added, re-verify from Egypt without VPN. **Never send users `*.netlify.app` links.** P9 re-checks reachability without VPN. | N8, N11, N13. Superseded proposal: custom root domain → Netlify load balancer 75.2.60.5 (rejected: paid domain). |
| **D11** | **Web semantics:** enable `SemanticsBinding.instance.ensureSemantics()` on web **only if** P6 measurement shows acceptable cost. Otherwise keep Flutter's default "Enable accessibility" placeholder and document it. | T5; the recent accessibility commit `dfb8980` implies a11y matters. |

---

## 3. Progress tracker

| Phase | Title | Status | Open 👤 checks |
|---|---|---|---|
| P0 | Baseline, decisions, measurements, hosting (Cloudflare Pages) | ✅ gate passed 2026-10-11 | P0.8-6 (explicit iPhone cellular + Wi-Fi without VPN on production), U11 (iOS version) |
| P1 | Branded, CDN-free web shell (manifest, icons, index.html, fonts, vendored JS) | ✅ gate passed 2026-10-11 (except 👤 DevTools Manifest check) | Chrome DevTools → Application → Manifest shows no errors; iPhone visual check of staging |
| P2 | Persistent web storage (sqflite on IndexedDB) | ✅ gate passed 2026-10-11 | P2.10–P2.13 (logged-in offline/reload/logout/iPhone checks) |
| P3 | Single-tab guard and web sync triggers | ☐ | — |
| P4 | Camera, photos and QR scanner on web | ☐ | — |
| P5 | Offline cold start, SW precache and update flow | ☐ | — |
| P6 | Install UX, responsive/browser UX, accessibility | ☐ | — |
| P7 | Security and privacy on web | ☐ | — |
| P8 | Cloudflare Pages production hosting, headers and release | ☐ | — |
| P9 | Full feature-parity QA, docs and sign-off | ☐ | — |

---

## 4. Phases

Each phase lists **Goal → Preconditions → Tasks → Files → Gate → Evidence → Rollback**.

---

### Phase 0 — Baseline, decisions and measurements

**Goal:** confirm §1 is still true, get the open decisions from the user, and measure before changing anything. **No production code changes in this phase.**

**Preconditions:** clean `git status` (aside from this plan file).

**Tasks**

- [x] P0.1 Re-run the §1 evidence commands: `flutter --version`, the F1/F13 greps, the `plugins.web` list from `.flutter-plugins-dependencies`, `flutter build web -h`. Note any drift in Evidence. If a fact changed, update its §1 row before continuing.
- [x] P0.2 Run the standard gate (§0.3) on the untouched tree and record the test count, analyzer result and web build time/size as the **baseline**.
- [x] P0.3 Build twice: `--web-renderer canvaskit --no-web-resources-cdn` and `--web-renderer html`. Record the sizes of `build/web` and `main.dart.js`. Confirm with `grep -c gstatic build/web/main.dart.js` that the CanvasKit URL is no longer the CDN in the `--no-web-resources-cdn` build (record exact output, whatever it is).
- [x] P0.4 👤 **User result 2026-10-11 (approximate, not instrumented):** CanvasKit (`staging.al-wahat-farm.pages.dev`) map in **"1 to 3 sec"** and **"feel much smooth[er] than"** HTML (`html-test.al-wahat-farm.pages.dev`). iOS version not reported (U11 still open). Original task: renderer performance (U5) on the **iPhone 11** in Safari. Test URLs (both reachable without VPN, verified 200): **CanvasKit → https://staging.al-wahat-farm.pages.dev**, **HTML → https://html-test.al-wahat-farm.pages.dev** (deploy `646a2fb2`). Open `/map`, then pan/zoom for 30 s with **Safari Web Inspector** connected from the Mac (Develop menu → iPhone; Timelines → Rendering Frames). **Threshold:** median frame time ≤ 33 ms (≥ 30 fps) during pan, and first map paint ≤ 5 s after login. Record the iOS version (U11), Safari version and numbers for both renderers. Also record desktop Chrome numbers for reference.
- [x] P0.4b Check the Android emulator (U12): `flutter emulators --launch Pixel_4`, then `adb shell pm list packages | grep -i chrome`. Record whether Chrome is present. If it isn't, Android browser checks are recorded as **"not testable — no device"**, never as passed. Emulator results are **functional only**: never use them as performance evidence, and record emulator camera results as "emulated".
- [x] P0.5 Ask the user for (a) hosting provider, (b) root vs sub-path, (d) available devices. **Answered 2026-10-11:** Netlify; domain root; iPhone 11. Recorded in §5.
- [x] P0.5c Ask the user to approve D1–D11. **Approved as written, 2026-10-11** (§5).
- [x] P0.6 **Not needed:** CanvasKit was faster and smoother than HTML in P0.4, so D4 stands unchanged (§5). Original: if P0.4 shows CanvasKit below threshold and HTML above it, raise a D4 change proposal to the user. Do not proceed until answered.
- [ ] P0.8 **Egypt-reachable host (D10/D12): Cloudflare Pages.**
  - [x] 1. User created a free Cloudflare account and ran `npx wrangler@4.149.0 login` (`whoami` ✓).
  - [x] 2. Project `al-wahat-farm` created (needed `--force` once, N13). Stray autoconfig files removed; `.wrangler/` gitignored.
  - [x] 3. Repo made host-neutral: `tool/netlify/_headers` → **`tool/hosting/_headers`**, `tool/build_web.sh` updated, `netlify.toml` removed.
  - [x] 4. Staging deploy → **https://staging.al-wahat-farm.pages.dev**: HTTPS + headers verified from this Mac **without VPN** (N13).
  - [x] 5. 👤 **Done by the user 2026-10-11** → deployment `https://5e8fed33.al-wahat-farm.pages.dev` ("Uploaded 2 files (27 already uploaded)"). Agent verified production without VPN (Evidence). Original instruction: production deploy by the user (the classifier blocks the agent): `nvm use && npx --yes wrangler@4.149.0 pages deploy build/web --project-name al-wahat-farm --branch main --commit-hash "$(git rev-parse HEAD)" --commit-message "Baseline production" --commit-dirty=true` → https://al-wahat-farm.pages.dev. The agent then re-runs the N13 header check against production.
  - [ ] 6. 👤 iPhone 11 **without VPN** (cellular and Wi-Fi) opens https://staging.al-wahat-farm.pages.dev and shows the login screen.
- [x] P0.7 **Netlify staging path — SUPERSEDED by P0.8 (Cloudflare Pages)** because `*.netlify.app` is blocked in Egypt (N8). Kept as history; don't follow these steps. Sub-steps (historical):
  - [x] 1. CLI `netlify-cli@27.12.0` on Node v22.13.1 (N5, N7). `.nvmrc` = `22.13.1` created. **Every deploy shell runs `nvm use` first** (nvm default is 18.13.0; a stale `netlify` exists under v18.19.1). Before each deploy session confirm `nvm use && netlify --version` → `netlify-cli/27.12.0 … node-v22.13.1`. Fallback: drag-and-drop `build/web` at app.netlify.com.
  - [x] 2. User re-authenticated (`netlify status` → mohammedzelrais0@gmail.com, team "mohamd"). **Note:** the team's display name is "mohamd" but its **account slug is `mohammed-z-elrais`** (`netlify api listAccountsForUser`); `--account-slug mohamd` returns 404. Site created by `netlify sites:create --name al-wahat-farm --account-slug mohammed-z-elrais` (user asked the agent to create it; the name was left blank in the UI, so the agent chose it). The site is **not Git-connected** (no Netlify builds). `.netlify/state.json` links it; `.netlify/` is gitignored. **Don't use Netlify's "Import from Git" screen** for this site: with an empty build command it would publish the repository root.
  - [x] 3. `netlify.toml`: only `[build] publish = "build/web"`, no `command`.
  - [x] 4. `tool/netlify/_headers` (only `X-Content-Type-Options: nosniff` for now) and `tool/build_web.sh`. **The script differs from the original sketch:** unless `DEFINES` is set, it regenerates the gitignored `config.web.json` from `config.json` with **only `SUPABASE_URL` + `SUPABASE_ANON_KEY`**, so `TEST_EMAIL`/`TEST_PASSWORD` never reach the public bundle. Flags: `--release --web-renderer canvaskit --no-web-resources-cdn --base-href ${BASE_HREF:-/}`. It copies `_headers` after the build and fails if `"_headers"` appears in the SW `RESOURCES`.
  - [x] 5. Staging deploy: `nvm use && netlify deploy --dir=build/web --no-build --alias staging --message "…"` → **https://staging--al-wahat-farm.netlify.app** (production URL https://al-wahat-farm.netlify.app has no production deploy yet, by design until P8).
  - [x] 6. 👤 **User reported "it works" (2026-10-11)**: the staging URL loads (device/network not stated). From this Mac it is still ⛔ unreachable (below); U13 stays open for field networks. Original note: ⛔ Blocked (from this Mac): `curl` to **any** `*.netlify.app` host (including the `netlify.app` apex and IP 63.176.8.218) times out on ports 80 and 443, with and without the sandbox. `app.netlify.com`/`www.netlify.com` (200) and `api.netlify.com` (401) respond. Netlify's API reports the deploy `state: ready`. **This is a local network/ISP block, not a deploy fault (U13).** 👤 Next: open the staging URL on the iPhone 11 over **cellular data** and over the same Wi-Fi, and record whether the login screen appears on each.

  The Supabase anon key ends up in the public JS (expected, P7.1). Never put a service-role key in `config.json`. Password login needs no Supabase redirect-URL change (F11).

**Files (current, after P0.8):** `.nvmrc`, `tool/hosting/_headers`, `tool/build_web.sh`, `.gitignore` (`.netlify/`, `.wrangler/`), Evidence and §5.

**Gate:** P0.1–P0.3 and P0.4b evidence recorded; P0.5c answered; P0.7 staging URL serves the app over HTTPS; D4 confirmed or amended in §5.

**Evidence**
```
P0.7 — 2026-10-11
$ nvm use && node --version            -> v22.13.1   (.nvmrc = 22.13.1)
$ netlify --version                    -> netlify-cli/27.12.0 darwin-x64 node-v22.13.1
$ netlify status                       -> Email: mohammedzelrais0@gmail.com, Teams: mohamd
$ netlify api listAccountsForUser      -> name='mohamd' slug='mohammed-z-elrais' type='Free'
$ netlify sites:create --name al-wahat-farm --account-slug mohamd            -> Error: createSiteInTeam error: 404
$ netlify sites:create --name al-wahat-farm --account-slug mohammed-z-elrais -> id d56be6c1-f6d4-4267-afd2-caf761ba0bb1
    url https://al-wahat-farm.netlify.app  admin https://app.netlify.com/projects/al-wahat-farm
$ ./tool/build_web.sh                  -> Compiling lib/main.dart for the Web... 64.7s; 22M build/web
    (same CupertinoIcons warning as baseline W2)
  audit: config.web.json keys = [SUPABASE_ANON_KEY, SUPABASE_URL]; TEST_EMAIL absent; TEST_PASSWORD absent;
         supabase url compiled: True; www.gstatic.com/flutter-canvaskit refs in main.dart.js: 0
$ netlify deploy --dir=build/web --no-build --alias staging --message "P0.7 staging baseline dfb8980"
    deploy_id 6acb8a9a8aa94aab8dcf8d94  deploy_url https://staging--al-wahat-farm.netlify.app
$ netlify api getDeploy (6acb8a9a8aa94aab8dcf8d94) -> state ready; "11 new files uploaded";
    "1 header rule processed — All header rules deployed without errors"
$ curl -sv https://staging--al-wahat-farm.netlify.app/   -> resolved; "Connection timed out after 20003 milliseconds"
$ nc -z -G 5 63.176.8.218 443 / 80     -> closed/timeout (both)
$ curl https://netlify.app / https://al-wahat-farm.netlify.app/ -> 000 (timeout)
$ curl -sI https://app.netlify.com -> HTTP/2 200; https://www.netlify.com -> 200; https://api.netlify.com/api/v1/ -> 401
Retry (user: "try now"), 2026-10-11:
$ nslookup staging--al-wahat-farm.netlify.app -> 35.157.26.135, 63.176.8.218
$ nc -z -G 5 <each IP> 443          -> timeout (both); curl --resolve via 35.157.26.135 -> no response
$ scutil --proxy                     -> no proxy enabled; www.netlify.com -> 200
  => still unreachable from this Mac at the IP level (U13); reachability must be confirmed on another network 👤
User: "it works" (staging loads for the user). Mac re-check: all 6 paths still "(no response)".

P0.1 — 2026-10-11 (no drift)
$ flutter --version -> Flutter 3.13.9, Engine 0545f8705d, Dart 3.1.5
$ grep -rnE "dart:io|Platform\.|kIsWeb|dart:html" lib (excl. gen) -> no matches (rc=1)
$ grep -rn "usePathUrlStrategy|setUrlStrategy" lib -> no matches (rc=1)
plugins.web -> [app_links, connectivity_plus, flutter_image_compress_web, image_picker_for_web, mobile_scanner, shared_preferences_web, url_launcher_web]
flutter build web -h -> --base-href, --pwa-strategy, --web-renderer, --[no-]web-resources-cdn, --csp present

P0.2 — baseline gate (untouched lib/test)
$ dart format --set-exit-if-changed .  -> "Formatted 232 files (3 changed)": ONLY lib/l10n/gen/app_localizations{,_ar,_en}.dart
    (that run wrote them; restored with `git checkout -- lib/l10n/gen`; `flutter gen-l10n` then gives a 0-line diff vs commit,
     i.e. committed gen files == raw gen-l10n output, which is not dart-format clean)
$ dart format --output=none --set-exit-if-changed <all except lib/l10n/gen> -> "Formatted 229 files (0 changed)", rc=0
$ flutter analyze -> No issues found! (ran in 6.3s)
$ flutter test --reporter compact -> 02:12 +339 ~6: All tests passed!  (6 skips = live tests needing credentials/opt-in) — 2m15s
web build baseline -> ./tool/build_web.sh: 64.7s first compile, 22M build/web, main.dart.js 3.9M

P0.3 — renderer builds
canvaskit (--no-web-resources-cdn): build/web 22M, main.dart.js 3.9M, canvaskit/ 15M;
    gstatic URLs = [https://fonts.gstatic.com/s/, https://fonts.gstatic.com/s/roboto/v20/KFOmCnqEu92Fr1Me5WZLCzYlKw.ttf]
html (--no-web-resources-cdn): compile 63.4s; build/web 22M (canvaskit/ still copied, 15M), main.dart.js 3.9M; gstatic refs 0
Script fix: a rebuild without cleaning made tool/build_web.sh fail its own guard
    ("error: _headers is listed in the service worker RESOURCES"): Flutter lists files already in build/web.
    build_web.sh now runs `rm -rf build/web` before building; rerun -> rc=0, _headers in RESOURCES: False.
    (The 6acb8a9a… staging deploy predates this and had passed the guard.)

P0.4b — emulator
$ flutter emulators --launch Pixel_4; adb getprop -> boot_completed=1, Android 13, sdk_gphone64_x86_64
$ adb shell pm list packages -> com.android.chrome, com.google.android.webview, …overlay.googlewebview
$ dumpsys package com.android.chrome -> versionName=109.0.5414.123

Egypt block — 2026-10-11 (user: "the app only works with VPN"; forum reports user-provided)
$ nc -z -G 5 75.2.60.5 443      -> succeeded
$ curl -sI --resolve staging--al-wahat-farm.netlify.app:443:75.2.60.5 https://…/  -> HTTP/2 200, server: Netlify,
    cache-control: public,max-age=0,must-revalidate, x-content-type-options: nosniff; <title>al_wahat_farm_flutter</title>
    /flutter_service_worker.js 200 application/javascript; /canvaskit/canvaskit.wasm 200 application/wasm;
    /manifest.json 200 application/json; /_headers 404
$ nslookup apex-loadbalancer.netlify.com -> 75.2.60.5, 99.83.231.61
$ nslookup al-wahat-farm.netlify.app     -> 35.157.26.135, 63.176.8.218   (both blocked)
$ nc -z 99.83.231.61 443 -> succeeded; curl --resolve …:443:99.83.231.61 -> HTTP/2 200, server: Netlify

Cloudflare Pages — 2026-10-11 (all from this Mac, Egyptian ISP, no VPN)
staging: wrangler pages deploy --branch staging -> https://b97e5725.al-wahat-farm.pages.dev, alias https://staging.al-wahat-farm.pages.dev
    first ~minute: "sslv3 alert handshake failure"; then 200; cert CN=al-wahat-farm.pages.dev, issuer Let's Encrypt YE1
html-test: --branch html-test -> https://646a2fb2.al-wahat-farm.pages.dev, alias https://html-test.al-wahat-farm.pages.dev (200)
production (user-run): --branch main -> https://5e8fed33.al-wahat-farm.pages.dev
$ curl -sI https://al-wahat-farm.pages.dev{/,/flutter_service_worker.js,/main.dart.js,/canvaskit/canvaskit.wasm,/manifest.json,/assets/assets/data/al_wahat_map_data.json}
    -> all HTTP/2 200; text/html | application/javascript | application/javascript | application/wasm | application/json | application/json;
       cache-control: public, max-age=0, must-revalidate; x-content-type-options: nosniff
main.dart.js sha256 (first 16): production a316ec1514c07bfe = staging a316ec1514c07bfe = local build/web a316ec1514c07bfe
/_headers on staging -> 200 text/html, body sha256 == index.html (SPA fallback; header rules not exposed)

P0.4 prep — html variant deployed: netlify deploy --alias html-test -> https://html-test--al-wahat-farm.netlify.app (6acb92fc1c6d6801a1b9c1a3)
```

**Rollback:** remove `.nvmrc`, `tool/hosting/`, `tool/build_web.sh`. Hosting rollback is in P8. Delete the old Netlify site (`netlify sites:delete d56be6c1-…`) or the Cloudflare project **only on user request**.

---

### Phase 1 — Branded, CDN-free web shell

**Goal:** the web build has correct identity (name, colors, icons, language), loads **zero** runtime resources from third-party origins, and renders Arabic offline.

**Preconditions:** P0 gate passed.

**Tasks — manifest and icons**

- [x] P1.1 Add a `web:` block to `flutter_launcher_icons` in `pubspec.yaml` (`generate: true`, `image_path: "assets/icon/app_icon.png"`, `background_color: "#F8F4E9"`, `theme_color: "#173D28"`), per W5. Run `dart run flutter_launcher_icons`. Verify `web/icons/Icon-192.png` / `Icon-512.png` changed (`file web/icons/*` sizes and dimensions) and are the farm icon, not the Flutter logo (open the PNG with the Read tool to inspect it).
- [x] P1.2 Maskable icons: confirm whether flutter_launcher_icons regenerated `Icon-maskable-*.png` (read its source in `~/.pub-cache/.../flutter_launcher_icons-0.13.1/lib/web/` to see what it writes). If not, generate 192/512 maskable PNGs from `app_icon_foreground.png` on `#F8F4E9` with the **icon inside the central 80% safe zone**, using the same painter approach documented in `test/golden/app_icon_test.dart`. Do not hand-edit with external tools the agent cannot run.
- [x] P1.3 Rewrite `web/manifest.json` by hand after icon generation (the generator only touches colors):
  - `"name": "Al Wahat Farm Operations"`, `"short_name": "Al Wahat"`, `"description"`: a one-line English description
  - `"id": "./"`, `"start_url": "./"`, `"scope": "./"` (relative, so `--base-href` works)
  - `"display": "standalone"`, `"orientation": "any"` (tablets are supported, see `login_tablet_1024x1366.png`)
  - `"background_color": "#F8F4E9"`, `"theme_color": "#173D28"`, `"lang": "en"`, `"dir": "auto"`
  - the 4 icons with correct `purpose` (`any` / `maskable`)
  - Validate the JSON: `python3 -m json.tool web/manifest.json`.
- [x] P1.4 Decide whether to add a 180×180 `web/icons/apple-touch-icon.png` (iOS ignores the manifest icons). Generate it from `app_icon.png`.

**Tasks — index.html (keep the 3.13 loader API, rule 5)**

- [x] P1.5 Edit `web/index.html`:
  - `<html lang="en">` (Flutter sets semantics language at runtime; this is the static default)
  - `<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">`
  - `<meta name="theme-color" content="#173D28">`
  - `<meta name="description" content="…">` (same text as the manifest)
  - iOS: `apple-mobile-web-app-title` = "Al Wahat", status-bar style `default`, `apple-touch-icon` → the P1.4 file
  - `<title>Al Wahat Farm Operations</title>`
  - Keep `<base href="$FLUTTER_BASE_HREF">`, the `serviceWorkerVersion` script and the `loadEntrypoint` call **byte-for-byte unchanged**.
- [x] P1.6 Add a lightweight static **loading splash** inside `<body>` (CSS-only, paper background `#F8F4E9`, centered icon, bilingual "Loading…" / "جارٍ التحميل…"). Remove it in `onEntrypointLoaded` after `appRunner.runApp()` resolves. No external CSS or fonts.
- [x] P1.7 Add a `<noscript>` bilingual message.

**Tasks — vendored JS (D5)**

- [x] P1.8 Create `web/vendor/`. Download **exactly** these (the versions come from F8/F9):
  - `https://cdn.jsdelivr.net/npm/pica@9.0.1/dist/pica.min.js` → `web/vendor/pica-9.0.1.min.js`
  - `https://unpkg.com/@zxing/library@0.19.1/umd/index.min.js` → `web/vendor/zxing-library-0.19.1.min.js`. First confirm that the bare `https://unpkg.com/@zxing/library@0.19.1` URL from the README resolves to this UMD file: `curl -sIL` it and record the final URL. Vendor whatever file that URL serves.
  - Record each file's SHA-256 (`shasum -a 256`) and source URL in `web/vendor/README.md`, together with the licenses. **Verified: both MIT** (the plan's earlier "@zxing/library: Apache-2.0" was wrong; `@zxing/library@0.19.1/package.json` says MIT). Confirm the license from the package's own `package.json` / `LICENSE` fetched alongside, not from memory.
- [x] P1.9 *(script tags added and served as `application/javascript`; the `window.pica`/`window.ZXing` runtime check moves to P4.3/P4.7)* Reference them in `web/index.html` with relative `src="vendor/…"` `<script>` tags **before** `flutter.js`. Verify `window.pica` and `window.ZXing` are defined in DevTools console 👤 or by an integration check in P4.

**Tasks — fonts (D4, F16)**

- [x] P1.10 Bundle an Arabic font. Use **Noto Sans Arabic** (SIL OFL 1.1) from the official `notofonts/arabic` GitHub releases, or Google Fonts' `NotoSansArabic` variable TTF. Save it as `assets/fonts/NotoSansArabic-Variable.ttf`. Record the source URL, version, SHA-256 and the OFL text in `assets/fonts/NOTICE-NotoSansArabic.txt`. Check the file size; if it is over ~1 MB consider the static Regular/Bold pair instead and record the choice.
- [x] P1.11 Register the family in `pubspec.yaml` `fonts:` (e.g. `family: NotoSansArabic`, weights 400/600/700). Put `'NotoSansArabic'` **first** in `_arabicFallback` in `lib/app/theme/app_theme.dart`. This also gives native a consistent Arabic face; record that the native change was intended.
- [x] P1.12 Golden impact: run `flutter test`. If goldens with Arabic text change, inspect the diffs with the Read tool. Regenerate (`flutter test --update-goldens <file>`) **only** after confirming the new rendering is correct, and list each regenerated golden in Evidence.

**Tasks — CDN audit**

- [x] P1.13 Build with the §0.3 flags and serve `build/web`. In Chrome DevTools → Network (disable cache), load login, then switch language to Arabic. **Every request must be same-origin or the Supabase project origin.** Record the domain list. 👤 if the agent cannot drive a browser; otherwise use the integration test from P5.4.
- [x] P1.15 Remove the remaining `fonts.gstatic.com` references (W3/P0.3): the CanvasKit engine's fallback-font base and the Roboto v20 TTF. First find **why** each is used by reading the engine source shipped with the SDK (`$(flutter sdk path)/bin/cache/flutter_web_sdk/lib/_engine/`, grep `fonts.gstatic.com` and `roboto`), and cite `file:line`. Then make sure every glyph the app renders comes from a bundled font (Inter, Libre Baskerville, the P1.10 Arabic font, MaterialIcons). Verify in DevTools → Network that **no** `fonts.gstatic.com` request happens in EN and AR. A string in `main.dart.js` that's never fetched is acceptable; record which case applies.
- [x] P1.14 Static check: `grep -rnoE "https://[a-zA-Z0-9.-]+" build/web/index.html build/web/flutter.js` lists only expected entries. Record the output.

**Files:** `pubspec.yaml`, `web/index.html`, `web/manifest.json`, `web/icons/*`, `web/vendor/*`, `assets/fonts/NotoSansArabic-*`, `assets/fonts/NOTICE-NotoSansArabic.txt`, `lib/app/theme/app_theme.dart`, possibly `test/goldens/*`.

**Gate:** standard gate green. `python3 -m json.tool web/manifest.json` OK. Chrome DevTools → Application → Manifest shows **no errors** and the correct icons and name 👤. P1.13 shows no third-party origins. Do not rely on Lighthouse's "PWA" category; recent Lighthouse versions removed it. Use the Application panel's installability section.

**Evidence**
```
Phase 1 — 2026-10-11
P1.1/P1.2 icons: web-only config (scratchpad flutter_launcher_icons-web.yaml: android:false, ios:false, web.generate) +
  `dart run flutter_launcher_icons -f <it>` -> "Creating Icons for Web... ✓". git status: only web/favicon.png, web/icons/Icon-*.png,
  web/manifest.json changed (no android/ios files). Generator source: web_icon_generator.dart:38-41,133-137 = plain resize of the
  same image for maskable (no padding). app_icon.png badge spans ~x110–912/1024 (~78%, visual estimate) < 80% maskable safe zone.
  Icon-192/512 + maskable 192/512 PNG 192²/512²; favicon 16²; Read of Icon-maskable-192.png shows the palm badge.
P1.4 `sips -z 180 180 assets/icon/app_icon.png --out web/icons/apple-touch-icon.png` -> PNG 180x180.
P1.3 manifest rewritten; `python3 -m json.tool web/manifest.json` OK. orientation "any" matches native (no Android
  screenOrientation; iOS Info.plist allows portrait + landscape).
P1.5–P1.7 index.html: lang=en, viewport-fit=cover, theme-color, iOS title/status bar/touch icon, title; splash removed after
  `appRunner.runApp()` resolves (engine app_bootstrap.dart:56-62 returns Promise<FlutterApp>); bilingual <noscript>.
  base href / serviceWorkerVersion / loadEntrypoint({serviceWorker}) kept.
P1.8 `curl -sIL https://unpkg.com/@zxing/library@0.19.1` -> 301 location /@zxing/library@0.19.1/umd/index.min.js.
  pica-9.0.1.min.js 35895 B sha256 1f0987f8…2b70; zxing-library-0.19.1.min.js 292379 B sha256 c5837e48…42ce;
  package.json license: pica 9.0.1 MIT, @zxing/library 0.19.1 MIT. UMD headers set global `pica` and `globalThis.ZXing`.
P1.10 google/fonts commit 8b0a1d0f…44b5 ofl/notosansarabic/NotoSansArabic[wdth,wght].ttf -> 844676 B, TrueType,
  sha256 63111b5b…869e, METADATA license "OFL"; NOTICE-NotoSansArabic.txt has source + full OFL.
P1.11 pubspec family NotoSansArabic (400/600/700). app_theme.dart: 'NotoSansArabic' first in _arabicFallback;
  ThemeData(fontFamilyFallback: _arabicFallback) (theme_data.dart:336,536-538 in 3.13); fallback added to snackBar
  contentTextStyle and chip label/secondaryLabel styles (previously Inter with no fallback).
P1.15 engine source: canvaskit/fonts.dart:116-121 downloads Roboto from fonts.gstatic.com unless FontManifest has a
  "Roboto" family; font_fallbacks.dart:310 fallback prefix https://fonts.gstatic.com/s/ (used only for glyphs missing from
  all registered fonts). Fix: bundled Roboto (google/fonts 1c627bfa…aa5c ofl/roboto/Roboto[wdth,wght].ttf, 488584 B,
  sha256 d7598e12…a134, OFL, NOTICE-Roboto.txt) as pubspec family "Roboto".
  Known limitation: emoji/other scripts not covered by bundled fonts still trigger the online Noto fallback (tofu offline).
Gate: format (excl. gen) 229 files 0 changed; flutter analyze: No issues; flutter test: +339 ~6 All tests passed
  (no golden diffs -> P1.12 no regeneration needed); lib/l10n/gen unchanged; ./tool/build_web.sh 23M.
  FontManifest families: MaterialIcons, Inter, LibreBaskerville, Roboto, NotoSansArabic.
  SW RESOURCES include vendor/*.js, fonts, icons, manifest; "_headers" not in RESOURCES.
P1.13 (automated, headless Chrome 150, local server):
  EN with net log: page requests only to localhost (canvaskit/chromium/canvaskit.wasm, Inter, LibreBaskerville, Roboto,
    NotoSansArabic, MaterialIcons, vendor/*.js); 0 requests to fonts.gstatic.com / www.gstatic.com; all other external
    hosts are Chrome's own background traffic (safebrowsing, update, variations, DoH, gvt1). Rendered (<flutter-view>,
    splash element removed).
  AR + EN with ALL external hosts blocked (--host-resolver-rules "MAP * ~NOTFOUND , EXCLUDE localhost"), screenshots:
    Arabic login renders fully (no tofu, RTL), English renders; server log shows Roboto + NotoSansArabic served locally.
    (Screenshots crop the card's right edge: headless viewport wider than the 430 px capture; artifact, not an app bug.)
  AR net-log attempt: empty log (Chrome killed before flush), so it was replaced by the blocked-network screenshot method.
P1.14 http(s) URLs in build/web/index.html + flutter.js are all comments or an error-message string (index.html:12,
  flutter.js:98,127,223,267).
Staging deploy: wrangler --branch staging -> https://ffa6d264.al-wahat-farm.pages.dev. The alias first served new paths as
  index.html (text/html, old title) for a few seconds; re-check: alias and unique URL both serve image/png,
  application/javascript, font/ttf and title "Al Wahat Farm Operations". => After every deploy, wait for the alias and
  verify content-types (N13 SPA fallback).
```

**Rollback:** `git checkout -- web pubspec.yaml lib/app/theme/app_theme.dart assets/fonts`.

---

### Phase 2 — Persistent web storage (sqflite on IndexedDB)

**Goal:** on web, the cache, outbox, pending photo BLOBs, inspection stations and the locale setting survive reload and browser restart, using the **unchanged** `Sqflite*Store` classes (D1). The in-memory fallback must never be hit silently on web.

**Preconditions:** P1 gate passed.

**Tasks**

- [x] P2.1 `flutter pub add sqflite_common_ffi_web` (dependency, not dev). Confirm the resolved version in `pubspec.lock` is the T2 version or record the difference. Run `flutter pub get`.
- [x] P2.2 Read `~/.pub-cache/hosted/pub.dev/sqflite_common_ffi_web-<ver>/lib/sqflite_ffi_web.dart` and `bin/setup.dart`. Cite the exported symbols used (`databaseFactoryFfiWeb`, any options class) with `file:line`. Check whether the library itself is safe to import on VM/native. If it imports `dart:html` / `dart:js*` unconditionally, it **must** be imported only from the web side of a conditional import.
- [x] P2.3 Run `dart run sqflite_common_ffi_web:setup`. Verify `web/sqlite3.wasm` and `web/sqflite_sw.js` exist. Check the sqlite3.wasm version matches the `sqlite3` package version in `pubspec.lock` (T3 warns the URL is hardcoded): read `bin/setup.dart` for the URL it used and record it. **Commit both files** (reproducible builds, and they must sit in `RESOURCES` for the SW). Add a line to `web/vendor/README.md` describing how to regenerate them.
- [x] P2.4 Create a conditional database-factory seam:
  - `lib/core/database/database_platform.dart`: `export 'database_platform_io.dart' if (dart.library.html) 'database_platform_web.dart';`
  - Both implementations expose: `Future<void> configureDatabaseFactory()` and `Future<String> defaultDatabasePath(String fileName)`.
  - io: no-op configure; path = `p.join(await getDatabasesPath(), fileName)` (exactly today's behavior).
  - web: `databaseFactory = databaseFactoryFfiWeb;` path = `fileName` (README recipe, T3).
- [x] P2.5 Change `AppDatabase.open()` to use `defaultDatabasePath(fileName)` when `filePath` is null. Call `configureDatabaseFactory()` at the top of `_bootstrapServices()` in `lib/main.dart`. **No other change to `AppDatabase` or the stores.**
- [x] P2.6 Make storage failure visible instead of silent. When `_bootstrapServices` falls back to memory, set a flag on `AppServices` (e.g. `bool persistentStorageAvailable`). Show a localized persistent warning banner ("Offline storage unavailable — work will be lost if you close the app") on Home/More. Add EN+AR strings. Native behavior is unchanged except the banner appears in the same fallback case.
- [x] P2.7 Durable-storage request (web only, U8). Add `lib/core/web/web_platform.dart` (conditional export of `web_platform_stub.dart` / `web_platform_html.dart`). Start with `Future<bool?> requestPersistentStorage()` (calls `window.navigator.storage?.persist()`, T4; stub returns `null`) and `Future<({int? usage, int? quota})> storageEstimate()`. Call `requestPersistentStorage()` once after a successful login. Log the result with `SafeLog.event`.
- [x] P2.8 Show storage status in the Failed-ops / sync screen or More (web only): "Storage: persistent / best-effort", plus usage. EN+AR strings.
- [x] P2.9 Tests (VM): unit-test the io `defaultDatabasePath` and that `AppDatabase.open(filePath: inMemoryDatabasePath)` behavior is unchanged (existing tests must pass untouched). Widget-test the P2.6 banner with an `AppServices` whose flag is false.
- [ ] P2.10 👤 *(automated part done: DB opens in Chrome and creates `al_wahat_farm.db` in IndexedDB; the offline-queue + reload check needs a logged-in user)* Web persistence check. Build, serve and log in. Queue a task status change and an issue photo **offline** (DevTools → Network → Offline), then hard-reload while still offline. The outbox count and failed-ops entries are still present. Go online and the op drains. Close the browser fully, reopen, and the cached hierarchy loads offline. 👤 (or automated in P5.4 if feasible)
- [ ] P2.11 Inspection station transaction (F4) on web: run an inspection route offline, reload mid-route, and the station progress is restored (the web analog of `integration_test/offline_inspection_restart_test.dart`). 👤
- [ ] P2.12 Logout on web: after sign-out, DevTools → Application → IndexedDB shows **no private rows** (`awf_private:` cache keys, outbox, pending_photos empty). `clearPrivateData()` already does this through the stores, so this verifies it holds on IndexedDB. 👤
- [ ] P2.13 👤 iPhone 11 (U8): repeat P2.10 on staging in Safari **and** in the installed home-screen app. Record the `persist()` result for each.

**Files:** `pubspec.yaml`, `pubspec.lock`, `web/sqlite3.wasm`, `web/sqflite_sw.js`, `lib/core/database/database_platform*.dart`, `lib/core/database/app_database.dart`, `lib/main.dart`, `lib/core/app_services.dart`, `lib/core/web/web_platform*.dart`, ARB files, new tests.

**Gate:** standard gate green plus `flutter build apk --debug`. P2.10 passes on desktop Chrome. Evidence shows the IndexedDB database present in DevTools.

**Evidence**
```
Phase 2 — 2026-10-11
P2.1 flutter pub add sqflite_common_ffi_web -> lock 0.4.2+1 (sqlite3 2.1.0), "Changed 6 dependencies!" (= T2).
P2.2 lib/sqflite_ffi_web.dart exports createDatabaseFactoryFfiWeb, databaseFactoryFfiWeb(NoWebWorker), SqfliteFfiWeb*;
  internals use conditional exports (src/database_factory.dart, src/sqflite_ffi.dart, src/web/load_sqlite.dart:
  `export '..._io.dart' if (dart.library.html) '..._web.dart'`); on io databaseFactoryFfiWeb is a getter that throws
  (src/sqflite_ffi_io.dart). sqflite_common-2.5.3 sqflite_database_factory.dart:41 `set databaseFactory` (prints a warning
  only if already set) is re-exported by package:sqflite/sqflite.dart.
P2.3 DEVIATION: setup.dart hardcodes `sqlite3-2.2.0/sqlite3.wasm` (lib/src/setup/sqlite3_wasm_version.dart), but Dart sqlite3
  2.2.0 needs SDK >=3.2.0 (pub.dev API; 2.1.0 needs >=3.0.0), so the lock stays at 2.1.0. Ran
  `dart run sqflite_common_ffi_web:setup --no-sqlite3-wasm` -> "created: web/sqflite_sw.js (330196 bytes)"; the worker build
  dir .dart_tool/sqflite_common_ffi_web/setup/1.0.1+4/pubspec.lock has sqlite3 2.1.0. Downloaded release sqlite3-2.1.0
  sqlite3.wasm (686680 B, "WebAssembly (wasm) binary module version 0x1"). Checksums + regeneration rules in web/vendor/README.md.
P2.4/P2.5 lib/core/database/database_platform{,_io,_web}.dart; AppDatabase.open uses defaultDatabasePath(fileName);
  main.dart calls configureDatabaseFactory() first inside the storage try-block.
P2.6 AppServices.persistentStorageAvailable (default true; false on in-memory fallback, which now logs
  SafeLog 'storage_fallback' with the error); StorageWarningBanner on Home + More; EN/AR strings.
P2.7 lib/core/web/web_platform{,_stub,_html,_types}.dart: requestPersistentStorage() (navigator.storage persisted()/persist(),
  html_dart2js.dart:22751,29237-29240), storageStatus() (estimate()). Called once per session in
  AuthenticatedGate.didChangeDependencies; result logged as 'storage_persist'.
P2.8 StorageStatusTile on More (persistent vs best-effort + "X MB of Y MB used"); hidden when load() returns null (native).
P2.9 tests: test/unit/database/database_platform_test.dart (3) + test/widget/storage_status_test.dart (5) -> +8 passed.
Gate: format 239 files 0 changed (excl. gen); flutter analyze: No issues; flutter test: +347 ~6 All tests passed;
  ./tool/build_web.sh 24M; flutter build apk --debug -> "✓ Built build/app/outputs/flutter-apk/app-debug.apk" (64.4s);
  lib/l10n/gen diff = only the new storage* keys (from the ARB edits).
Web check (headless Chrome 150, local server):
  with --virtual-time-budget: sqflite_sw.js fetched but NOT sqlite3.wasm, IndexedDB metadata only -> virtual time stalls the
    worker (test artifact).
  real time 45 s (--enable-logging=stderr): server served /sqflite_sw.js and /sqlite3.wasm; no '[awf] storage_fallback' in the
    console; app reached /#/login; IndexedDB http_localhost_8765 has a 13.6 KB log containing "al_wahat_farm.db" (7 hits).
    Table names aren't greppable (stored pages are compressed), so schema creation is inferred from no-fallback + DB file.
```

**Rollback:** revert the files; `flutter pub remove sqflite_common_ffi_web`; delete `web/sqlite3.wasm` and `web/sqflite_sw.js`.

---

### Phase 3 — Single-tab guard and web sync triggers

**Goal:** only one tab owns the DB and SyncEngine (D2). Sync also runs when the app returns to the foreground (F6, D7). Offline detection does not lie when `navigator.onLine` is true but the network is dead.

**Preconditions:** P2 gate passed.

**Tasks — single tab (D2)**

- [ ] P3.1 Record U1: in DevTools → Application → Shared workers (desktop) and `chrome://inspect/#workers` on Android 👤, note whether `sqflite_sw.js` runs as a SharedWorker. **Implement the guard regardless.**
- [ ] P3.2 Add to `web_platform`: `TabLease` with `Future<bool> tryAcquire()`, `Stream<void> lostOwnership`, `void takeOver()`, built on `BroadcastChannel('awf-tab')` (T4). Protocol: on start, post `{type:'claim', id, ts}` and wait 300 ms. If an owner answers `{type:'owned', id}`, the claim fails. `takeOver()` posts `{type:'takeover', id}`, and the current owner releases and emits `lostOwnership`. Stub (VM/native): always owns.
- [ ] P3.3 In `main.dart`, acquire the lease **before** opening the database. If the lease isn't owned, run a minimal `SecondTabApp` (localized, branded) with a "Use here" button that calls `takeOver()` then `window.location.reload()`. On `lostOwnership`, the owning tab must stop the SyncEngine, close the DB (`AppDatabase.close()`) and show the same screen.
- [ ] P3.4 Unit-test the lease protocol with a fake channel (pure Dart logic separated from `dart:html`, so it runs on VM).
- [ ] P3.5 👤 Open the app in two tabs. The second shows the guard screen; "Use here" moves ownership; the first tab shows the guard screen; no console errors.

**Tasks — foreground sync trigger (D7)**

- [ ] P3.6 Add a platform-neutral foreground signal. Native: `AppLifecycleListener(onResume: …)` (T5). Web: `document.onVisibilityChange` where `visibilityState == 'visible'` (T4), via `web_platform`. Wire it so `SyncEngine.sync()` is called on foreground. Put the wiring in the sync scope, **not** inside `SyncEngine`, to keep it testable. Read `lib/features/sync/presentation/sync_scope.dart` first and follow its pattern.
- [ ] P3.7 Unit test: a fake foreground stream triggers `sync()` once per event, and `alreadyRunning` is respected.

**Tasks — honest connectivity (F5)**

- [ ] P3.8 On web only, treat a SyncEngine transient failure (`OperationFailureKind.offline`) while `navigator.onLine` is true as **degraded**. Do not flip the global offline state (that would block online-only screens incorrectly). The existing retry-on-trigger already covers recovery; just make sure the sync status UI shows "Waiting for connection" instead of a spinner. First read how `ConnectivityController` and the sync UI render today. If the existing UI already handles it, record "no change needed" with evidence.
- [ ] P3.9 👤 Chrome DevTools "Offline", then "Online": the app reflects both and drains the outbox on "Online".

**Files:** `lib/core/web/web_platform*.dart`, `lib/main.dart`, a new `lib/core/web/second_tab_app.dart` (or similar), `lib/features/sync/presentation/sync_scope.dart`, ARB files, tests.

**Gate:** standard gate green plus apk build; P3.4 and P3.7 tests pass; P3.5 and P3.9 recorded or explicitly left 👤.

**Evidence**
```
(paste here)
```

**Rollback:** revert; the guard is additive.

---

### Phase 4 — Camera, photos and QR scanner on web

**Goal:** issue photos, task evidence and QR scanning work in mobile browsers and in the installed PWA, with correct permission and error UX.

**Preconditions:** P3 gate passed; P1.9 scripts present.

**Tasks — photos (F7, F8)**

- [ ] P4.1 Read `image_picker_for_web-3.0.2/lib/image_picker_for_web.dart` and cite how `ImageSource.camera` is handled (expected: `<input type=file capture>`; verify, don't assume). Record whether `XFile.name` is populated on web, since `_safeFilename` relies on it.
- [ ] P4.2 Web compress semantics differ (F8): width capped at 1920, height by aspect ratio, EXIF dropped by canvas re-encode. Confirm this meets the product rule (≤10 MiB JPEG). No code change is expected; record the decision. If portrait images should cap height instead, add a web-only pre-computation. Ask the user first.
- [ ] P4.3 Error path: if `window.pica` is missing, the web plugin throws. Wrap the compress call so a missing-pica or compress failure maps to the existing `OperationFailure(invalidInput, …)` message instead of an uncaught JS error. Add a unit test with a fake compressor if the service has a seam. If it doesn't, add a minimal injectable compressor function, keeping native behavior identical.
- [ ] P4.4 👤 iPhone 11 Safari, browser **and** installed (staging). If P0.4b found Chrome, repeat on the Pixel_4 emulator (gallery only; emulated camera recorded as "emulated"). Report an issue with a camera photo and with a gallery photo, online and offline. The issue/photo syncs. Record the file size and type (U3: JPEG vs HEIC). If HEIC arrives and compress fails, record it as ⛔ and propose a fix to the user.
- [ ] P4.5 Task evidence: same as P4.4 via task detail. 👤
- [ ] P4.6 CORS (U4): open a task photo in the viewer on a CanvasKit build. If the image fails with a CORS error in the console, record it. Supabase Storage CORS is a backend setting, so **ask the user** rather than changing backend config. 👤 or automated via integration test with a live account.

**Tasks — QR scanner (F9, F10)**

- [ ] P4.7 Verify `window.ZXing` loads from `vendor/` (P1.9) and the scanner starts on desktop Chrome with a webcam. Scan a real tree QR (or a test QR rendered on screen with a known token) and confirm navigation to `/map/tree/:id`. 👤
- [ ] P4.8 Insecure context: when `window.isSecureContext == false`, show a localized message ("Camera requires a secure (https) connection") instead of the generic camera-unavailable state. Add it to `web_platform` and `scanner_screen.dart`, with EN+AR strings and a widget test via a fake.
- [ ] P4.9 👤 iPhone 11 Safari (browser and **installed**, U2), and desktop Chrome with the Mac webcam. Android Chrome: emulator only if available, marked "emulated". Steps: grant, deny, then re-grant camera permission. The deny path shows `scanCameraOff`. Record results per environment.
- [ ] P4.10 **Fallback if U2 fails** (camera unavailable in iOS standalone): add a "Enter tree code manually" action on the scanner screen that calls the same `_scanToken(raw)` path. **Only implement this if P4.9 shows a real gap**, and with user approval, because it adds UI to native too.
- [ ] P4.11 Scanner lifecycle: leaving `/scan` stops the camera (the browser camera indicator turns off). 👤

**Files:** `lib/features/issues/data/issue_photo_service.dart`, `lib/features/tasks/data/task_evidence_service.dart` (only if P4.3 needs a seam), `lib/features/map/presentation/scanner_screen.dart`, `lib/core/web/web_platform*.dart`, ARB files, tests.

**Gate:** standard gate green plus apk build; P4.3 and P4.8 tests pass; 👤 results recorded for at least desktop Chrome.

**Evidence**
```
(paste here)
```

**Rollback:** revert; the changes are additive.

---

### Phase 5 — Offline cold start, SW precache and update flow

**Goal:** after one online login, the installed app **cold-starts fully offline** (airplane mode, app killed) to the authenticated shell with cached data. New deployments are picked up safely (D5, D6).

**Preconditions:** P4 gate passed.

**Tasks**

- [ ] P5.1 Inspect the built `build/web/flutter_service_worker.js` `RESOURCES` map. Confirm it contains `canvaskit/…` (local, after `--no-web-resources-cdn`), `assets/fonts/NotoSansArabic…`, `assets/assets/data/al_wahat_map_data.json` (check the exact key), `vendor/pica-…`, `vendor/zxing-…`, `sqlite3.wasm`, `sqflite_sw.js`. Record the exact keys.
- [ ] P5.2 Precache everything (D5). Add `web_platform.requestOfflineDownload()`, which posts `'downloadOffline'` to `navigator.serviceWorker.controller` (W4). Call it once after the first successful authenticated bootstrap per SW version. Record the version via `serviceWorkerVersion` read from the page (a `window` global set in index.html) and store it in the non-private cache key `awf_sw_precached_version`.
- [ ] P5.3 Update detection (D6). In `web/index.html`, after `loadEntrypoint`, register `navigator.serviceWorker.addEventListener('controllerchange', …)`. **Ignore the first controller** (initial install), then dispatch `window.dispatchEvent(new Event('awf-sw-updated'))`. Expose it as `Stream<void> onAppUpdateAvailable` in `web_platform` (listen via `window.on['awf-sw-updated']`). Show a localized MaterialBanner/SnackBar "A new version is available" with a "Reload" button → `window.location.reload()`. Never reload automatically. EN+AR strings.
- [ ] P5.4 Automated web smoke (if feasible on 3.13.9): add `integration_test/web_smoke_test.dart`, run with `chromedriver --port=4444` and `flutter drive --driver=test_driver/integration_test.dart --target=integration_test/web_smoke_test.dart -d web-server --release`. It covers app boot → login screen renders → language toggle → no exceptions. If chromedriver/version mismatch blocks this, mark ⛔ with the exact error and rely on 👤 checks. Do not fake a pass.
- [ ] P5.5 👤 **Offline cold-start test** (U6), **iPhone 11 installed PWA** (required) and desktop Chrome installed PWA (required). Pixel_4 emulator installed PWA (optional, "emulated"):
  1. Online: install, log in, open Map, Tasks, Issues, Schedules, Inventory once.
  2. Wait for precache (DevTools → Application → Cache Storage shows a full `flutter-app-cache`).
  3. Kill the app, enable airplane mode, open the app.
  4. Expect: splash → authenticated shell with the cached hierarchy, map renders, Arabic text renders (switch language), the scanner shows offline messaging, and queueing a task action works.
  5. Disable airplane mode: the outbox drains.
  - Record results per platform. A failure on the iPhone 11 or desktop Chrome blocks P9 sign-off.
- [ ] P5.6 👤 Update test on the **same origin**: deploy build A with `--alias staging`, open/install it on the iPhone 11, then deploy build B (any visible change) with the same `--alias staging`. Expect the update banner without data loss; Reload shows B. The outbox persists across the update.
- [ ] P5.7 Supabase session offline: confirm the existing offline app-open behavior (`OFFLINE_PLAN.md` §7) holds on web when the access token is expired and offline. Read `OFFLINE_PLAN.md` §7 first and replicate its test scenario. 👤

**Files:** `web/index.html`, `lib/core/web/web_platform*.dart`, an app-level banner host (e.g. `lib/core/widgets/app_shell.dart`, read it first), ARB files, `integration_test/web_smoke_test.dart`.

**Gate:** standard gate green plus apk build; P5.1 evidence complete; P5.5 passes on at least one platform, with the other recorded.

**Evidence**
```
(paste here)
```

**Rollback:** revert; the SW strategy itself is unchanged.

---

### Phase 6 — Install UX, responsive/browser UX, accessibility

**Goal:** the PWA feels native on phones, works with mouse, keyboard and browser navigation on desktop, and stays accessible.

**Preconditions:** P5 gate passed.

**Tasks — install (D8)**

- [ ] P6.1 `web_platform`: `bool get isStandalone` (matchMedia `(display-mode: standalone)` or `navigator.standalone`), `bool get isIos` (UA check, documented as a heuristic), `Stream<void> installAvailable` + `Future<bool> promptInstall()` (capture and `preventDefault()` `beforeinstallprompt`, T4; call `.prompt()` later). Capture the event **in index.html** before Flutter boots (it can fire early) and stash it on `window`. Read it from Dart.
- [ ] P6.2 More screen (web, not standalone): an "Install app" tile. Chromium uses `promptInstall()`. iOS opens a localized sheet with "Share → Add to Home Screen" steps. Hide it when standalone. EN+AR strings; widget test via fake `web_platform`.
- [ ] P6.3 👤 Install on the iPhone 11 (Safari → Share → Add to Home Screen) and desktop Chrome (install prompt). Pixel_4 emulator Chrome optional ("emulated"). The launched app is standalone, with the correct name, icon, splash colors and status bar.

**Tasks — layout and browser behavior**

- [ ] P6.4 Safe areas: with `viewport-fit=cover` (P1.5), confirm `MediaQuery.padding` respects the iPhone notch and home indicator in standalone mode. Check the bottom nav in `app_shell.dart` isn't covered. 👤
- [ ] P6.5 Browser back/forward and refresh on every route in F14: the router state is correct, no blank screens, and the auth redirect still applies. Write a widget test only where logic changes; otherwise 👤 checklist.
- [ ] P6.6 Map on desktop: mouse-wheel/trackpad zoom and drag pan work. Read `farm_map_screen.dart` to see whether it uses `InteractiveViewer` (which supports wheel zoom) or custom gestures; add `PointerScrollEvent` handling only if missing. The map's `Directionality(ltr)` lock must stay.
- [ ] P6.7 Text fields: browser autofill for email/password on login (wrap in `AutofillGroup` with `autofillHints` if not present; read `login_screen.dart` first). Enter key submits.
- [ ] P6.8 Wide screens: phone/tablet breakpoints already exist (see golden `login_tablet_1024x1366.png`). Confirm that on desktop ≥1280 px the content doesn't stretch unusably. If it does, constrain the max content width in the shell. Golden or screenshot evidence.
- [ ] P6.9 RTL on web: switch to Arabic; layout mirrors, the map stays LTR, Arabic glyphs render with the bundled font. 👤 screenshot.
- [ ] P6.10 Context menu and text selection: confirm no browser context menu appears over the map canvas (Flutter handles it). Record only.

**Tasks — accessibility (D11)**

- [ ] P6.11 Measure: build with and without `SemanticsBinding.instance.ensureSemantics()` on web (called in `main` behind `kIsWeb`). Compare map pan frame time (P0.4 method) 👤. If the cost is ≤ 10%, enable it; otherwise keep the default placeholder. Record the decision in §5.
- [ ] P6.12 👤 Screen reader smoke: VoiceOver on the iPhone 11 (installed PWA) and VoiceOver on macOS Chrome can log in and reach Tasks. TalkBack is untested (no Android device); record it as such.

**Files:** `web/index.html`, `lib/core/web/web_platform*.dart`, `lib/features/profile/presentation/profile_screen.dart` (More), `lib/features/auth/presentation/login_screen.dart`, `lib/core/widgets/app_shell.dart`, `lib/features/map/presentation/farm_map_screen.dart`, `lib/main.dart`, ARB files, tests.

**Gate:** standard gate green plus apk build; widget tests for P6.2 pass; 👤 items recorded.

**Evidence**
```
(paste here)
```

**Rollback:** revert per file.

---

### Phase 7 — Security and privacy on web

**Goal:** web adds no new data-exposure paths compared with native.

**Preconditions:** P6 gate passed.

**Tasks**

- [ ] P7.1 Confirm the compiled output contains only the **anon** key: `grep -c "service_role" build/web/main.dart.js` → 0. The anon key being visible in JS is expected. Record it.
- [ ] P7.2 Logout clears everything private on web: IndexedDB rows (P2.12), `localStorage` Supabase session key (F12, removed by `signOut`), and **no private data in Cache Storage**. The SW caches only `RESOURCES`, which are public app files; verify by listing Cache Storage keys after a session. 👤 / DevTools.
- [ ] P7.3 Signed photo URLs may sit in the browser HTTP cache until expiry. Record the expiry constant used in `task_photo_viewer.dart:35` (`_expirySeconds`) and accept or flag it to the user.
- [ ] P7.4 Security headers (applied in P8 hosting config): `Strict-Transport-Security`, `X-Content-Type-Options: nosniff`, `Referrer-Policy: strict-origin-when-cross-origin`, `Permissions-Policy: camera=(self), microphone=(), geolocation=()`. Draft a **Content-Security-Policy** and test it in report-only mode first: `default-src 'self'; script-src 'self' 'wasm-unsafe-eval'; connect-src 'self' https://<project>.supabase.co wss://<project>.supabase.co; img-src 'self' data: blob: https://<project>.supabase.co; style-src 'self' 'unsafe-inline'; worker-src 'self'; font-src 'self'`. **Every directive must be validated against the real console**; CanvasKit and the sqlite worker may need adjustments. Check whether `--csp` (T1) is required by testing with and without it. Record the final policy and any violations.
- [ ] P7.5 Run the `security-review` skill on the PWA diff if the user requests it. Otherwise record "not run".

**Files:** hosting config (P8), possibly `web/index.html`.

**Gate:** P7.1 is 0; P7.2 verified; P7.4 CSP produces zero violations in report-only mode across a full P9 walkthrough (may be finalized in P8).

**Evidence**
```
(paste here)
```

**Rollback:** remove headers from the hosting config.

---

### Phase 8 — Cloudflare Pages production hosting, headers and release

**Goal:** one reproducible command builds the PWA, and Cloudflare Pages serves it at the domain root over HTTPS with correct headers, reachable in Egypt without VPN (D10, D12).

**Preconditions:** P7 gate passed; P0.8 staging works.

**Tasks**

- [ ] P8.1 Finalize `tool/build_web.sh`. It checks `web/sqlite3.wasm`, `web/sqflite_sw.js` and `web/vendor/*` exist (fail if missing), keeps `rm -rf build/web` + the post-build `_headers` copy, and asserts `"_headers"` is **not** in the SW `RESOURCES`.
- [ ] P8.2 Write the final `tool/hosting/_headers` (N12 syntax; ≤ 100 rules; ≤ 2,000 chars/line):
  - `/*`: the P7.4 security headers and the final CSP (enforcing, after report-only showed zero violations).
  - Caching: **keep the default** `public, max-age=0, must-revalidate` (N13). Flutter 3.13 filenames aren't content-hashed, so don't add long `max-age`/`immutable`.
  - Content types are already correct (N13), so add no overrides.
- [ ] P8.3 Missing-asset trap (N13 SPA fallback): add a check to `tool/build_web.sh` or a post-deploy script that fetches each `RESOURCES` key from the deployed URL and asserts the response **content-type is not `text/html`** for non-HTML keys (catches a missing `sqlite3.wasm`/vendor file silently served as `index.html`). Run it against staging.
- [ ] P8.4 Verify headers on staging and production: `curl -sI` for `/`, `/index.html`, `/flutter_service_worker.js`, `/main.dart.js`, `/canvaskit/canvaskit.wasm`, `/sqlite3.wasm`, `/manifest.json`. Record the outputs. Run **from this Mac without VPN** (Egyptian ISP).
- [ ] P8.5 Re-run P1.13 (no third-party origins), the P7.4 CSP check and Application → Manifest installability against staging. 👤
- [ ] P8.6 👤 Production deploy by the user: `nvm use && npx --yes wrangler@4.149.0 pages deploy build/web --project-name al-wahat-farm --branch main --commit-hash "$(git rev-parse HEAD)" --commit-message "PWA <short sha>"`. The agent records the deployment URL from the output.
- [ ] P8.7 Custom domain: optional (D12). If the user wants one later, add it in the Cloudflare dashboard (Pages → Custom domains, 👤), then re-run P8.4 from Egypt without VPN. Changing origin = new PWA install + new IndexedDB, so warn users to sync first and reinstall.
- [ ] P8.8 Optional CI (ask the user first): a workflow pinned to Flutter 3.13.9 running the standard gate plus `tool/build_web.sh`. Deploying from CI needs a `CLOUDFLARE_API_TOKEN` + `CLOUDFLARE_ACCOUNT_ID` in CI secrets, never in the repo.

**Files:** `tool/build_web.sh`, `tool/hosting/_headers`, `.nvmrc`, `.gitignore` (`.wrangler/`, `.netlify/`), optionally `.github/workflows/web.yml`.

**Gate:** P8.3 and P8.4 pass; production URL loads without VPN; the iPhone 11 installs from production and passes P5.5 👤.

**Evidence**
```
(paste here)
```

**Rollback:** Cloudflare dashboard → Pages → `al-wahat-farm` → Deployments → pick the previous production deployment → "Rollback to this deployment" (👤). Revert the repo files.

---

### Phase 9 — Full feature-parity QA, docs and sign-off

**Goal:** prove every feature works on web, and document it.

**Preconditions:** P8 gate passed.

**9.1 Parity matrix.** For each cell write ✅ / ❌ (with a note) / n/a. 👤 for device columns. The agent may fill "Desktop Chrome" if it can drive a browser; otherwise everything is 👤.

| Feature (route) | Web concern | Desktop Chrome | Android emulator Chrome (functional only) | iPhone 11 Safari (installed) | Offline |
|---|---|---|---|---|---|
| Login (`/login`) | F11/F12, autofill | | | | n/a (online first time) |
| Offline app-open / session restore | P2, P5.7 | | | | |
| Home dashboard (`/home`) | — | | | | |
| Farm map + layers + section filter (`/map`) | D4 perf, wheel zoom, LTR lock | | | | |
| Tree detail + planting pits (`/map/tree/:id`) | — | | | | |
| Report issue + photo (`…/report-issue`) | F8, P4 | | | | |
| QR scan (`/scan`) | F9, HTTPS, U2 | | | | offline msg |
| Issues list/detail (`/issues…`) | — | | | | |
| Tasks list + month calendar (`/tasks`) | — | | | | |
| Task create (`/tasks/create`) | outbox | | | | |
| Task detail, status changes, evidence photos, photo viewer (`/tasks/:id`) | F15 CORS | | | | |
| Inspection create + runner, restart persistence (`/tasks/create-inspection`, `…/inspection`) | F4 | | | | |
| Engineer reviews queue/detail (`/tasks/reviews…`) | offline review queue | | | | |
| Schedules list/form/detail (`/more/schedules…`) | — | | | | |
| Inventory list/item/form (`/more/inventory…`) | — | | | | |
| Failed ops: retry/discard (`/more/failed-ops`) | — | | | | |
| Sync badges + drain on reconnect/foreground | P3 | | | | |
| Language switch EN↔AR + RTL | P1.10 font | | | | |
| Profile + logout clears private data | P2.12/P7.2 | | | | |
| Install prompt / iOS instructions | D8 | | | | n/a |
| Update banner | D6 | | | | n/a |
| Second-tab guard | D2 | | n/a | n/a | |

**Tasks**

- [ ] P9.1 Fill the matrix 👤. Every ❌ becomes a ⛔ item in the owning phase, which is reopened.
- [ ] P9.2 Native regression: `flutter test` (all), `flutter build apk --debug`, and 👤 `flutter run` on the iPhone 11 (native build) or an iOS simulator (Xcode 14.2), plus the Pixel_4 emulator, with a smoke test of login, map, scan and offline queue.
- [ ] P9.3 Update `README.md` with a **Web / PWA** section: build command (`tool/build_web.sh`), local serve, required secure context, regenerating `sqlite3.wasm`/vendor files, Cloudflare Pages deploy steps (`nvm use`, `npx --yes wrangler@4.149.0 pages deploy build/web --project-name al-wahat-farm --branch staging|main`, `tool/hosting/_headers`, dashboard rollback), the Egypt note (never `*.netlify.app`), known limitations (D7 no background sync, D9 no push, iOS needs install for durable storage, Android single tab).
- [ ] P9.4 Update the memory directory: add a `pwa-architecture` memory summarizing D1–D11 and the key files (`web_platform`, `database_platform`, vendored JS, build script), and link it from `MEMORY.md`.
- [ ] P9.5 Final standard gate plus apk build; record the final web bundle size against the P0 baseline.
- [ ] P9.6 Set every phase in §3 to ✅ only if its gate evidence exists. List any remaining 👤 items explicitly. **The plan is complete only when no ⛔ items remain and the user accepts any open 👤 items.**

**Evidence**
```
(paste here)
```

---

## 5. Decision log and user answers

| Date | ID | Question / change | Answer / approved by |
|---|---|---|---|
| 2026-10-11 | P0.5a | Hosting provider and domain | **Netlify** (user). Custom domain: not given → `<site>.netlify.app` until named (P8.7). |
| 2026-10-11 | P0.5b | Root or sub-path (`--base-href`) | **Domain root** → `--base-href /` (user: "i think domain root"; confirm when the custom domain is chosen). |
| 2026-10-11 | P0.5c | Approve D1–D11 | **Approved as written** (user). |
| 2026-10-11 | P0.5d | Devices available for 👤 checks | **iPhone 11** (user). Also available locally: desktop Chrome + Safari on the Mac and the Pixel_4 Android emulator (N6). |
| 2026-10-11 | Risk | No physical Android phone | Android results are emulator-only and functional only. Low-end Android performance and Android camera/QR are **untested**, and must be reported as such at sign-off, never as passed. User to accept at P9.6. |
| 2026-10-11 | P0.8 / D12 | Egypt reachability | User: "i need a working free solution without VPN", so a paid domain is rejected. sslip.io on Netlify: HTTP only, cert 422 (N11). Agent proposed Cloudflare Pages; the user created the account, logged in and replied "done" = **approved switching D10 to Cloudflare Pages**. Staging live and verified without VPN (N13). |
| 2026-10-11 | P0.7 | Netlify site | `al-wahat-farm` (id `d56be6c1-f6d4-4267-afd2-caf761ba0bb1`, account slug `mohammed-z-elrais`), CLI-created, not Git-connected. Staging: https://staging--al-wahat-farm.netlify.app. Production: https://al-wahat-farm.netlify.app (empty until P8). |
| 2026-10-11 | P0.7 | Deploy method | **CLI**: user installed Node v22.13.1 + `netlify-cli@27.12.0` (verified, N5/N7). Supersedes the earlier same-day note about v20.19.2 / 26.2.0. Drag-and-drop is the fallback. Login session expired: user to re-login. |
| 2026-10-11 | D4 | Renderer confirmed after P0.4 | **CanvasKit confirmed.** User on iPhone 11: CanvasKit map in 1–3 s and much smoother than HTML. Rough user report, not instrumented. |
| | D11 | Web semantics on/off after P6.11 | |

---

## 6. File map (expected new/changed files)

| File | Phase | Purpose |
|---|---|---|
| `web/index.html` | P1, P5, P6 | Meta, splash, vendored scripts, SW update event, install-prompt capture (3.13 loader kept) |
| `web/manifest.json`, `web/icons/*` | P1 | Identity and icons |
| `web/vendor/pica-9.0.1.min.js`, `web/vendor/zxing-library-0.19.1.min.js`, `web/vendor/README.md` | P1 | Offline third-party JS with checksums and licenses |
| `assets/fonts/NotoSansArabic-*.ttf`, `assets/fonts/NOTICE-NotoSansArabic.txt` | P1 | Offline Arabic glyphs |
| `web/sqlite3.wasm`, `web/sqflite_sw.js` | P2 | sqflite web runtime |
| `lib/core/database/database_platform{,_io,_web}.dart` | P2 | Conditional DB factory and path |
| `lib/core/web/web_platform{,_stub,_html}.dart` | P2–P6 | Browser APIs behind conditional import: persist/estimate, tab lease, visibility, SW update, offline download, install, secure context |
| `lib/core/web/second_tab_app.dart` | P3 | Guard screen |
| `lib/main.dart`, `lib/core/app_services.dart` | P2, P3, P6 | Bootstrap changes |
| `lib/app/theme/app_theme.dart` | P1 | Arabic font first in fallback |
| `lib/features/map/presentation/scanner_screen.dart` | P4 | Secure-context message (and optional manual entry) |
| `lib/features/{issues,tasks}/data/*_service.dart` | P4 | Compress-failure mapping (only if needed) |
| `lib/features/sync/presentation/sync_scope.dart` | P3 | Foreground sync trigger |
| `lib/features/profile/presentation/profile_screen.dart` | P2, P6 | Storage status, install tile |
| `lib/l10n/arb/app_{en,ar}.arb` | all | New strings (both files) |
| `integration_test/web_smoke_test.dart` | P5 | Web smoke (if feasible) |
| `tool/build_web.sh`, `tool/hosting/_headers`, `.nvmrc` (`22.13.1`), `.gitignore` (`.netlify/`, `.wrangler/`) | P0.7, P0.8, P8 | Reproducible build, headers copied post-build, Cloudflare Pages deploy via `npx wrangler@4.149.0` |
| `README.md` | P9 | Web docs |

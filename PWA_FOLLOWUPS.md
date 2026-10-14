# PWA follow-ups

Things found while finishing the PWA feature (`PWA_IMPLEMENTATION_PLAN.md`). Each item says what
was seen, what was done, and what is still open. Nothing here blocks using the web app today.

Started 2026-10-12 after testing on the Pixel_4 emulator and the user's iPhone 11 (installed PWA);
updated 2026-10-13 after desktop Chrome, emulator and native runs. "Seen" means observed; "not
verified" means reasoned from code.

## Fixed (2026-10-13/14)

| # | What was wrong | Fix | Verified |
|---|---|---|---|
| 1 | "Warning database has been locked for 0:00:10" on every launch. Not a transaction misuse: the ~2.6 MB farm hierarchy was rewritten on every launch and held the database for over 10 s on a phone browser | `PersistentFarmHierarchyCache` stores a SHA-256 of the JSON and skips the write when unchanged (0278c4c) | desktop Chrome on staging: second launch logs `farm_hierarchy_cache_write {skipped=true}`; not re-checked on a phone |
| 2 | Logout deleted unsynced offline work without warning | Logout asks first when the outbox has pending or failed changes (60fc168) | widget tests (cancel keeps the session; confirm signs out) |
| 3 | Home date line was the fixed text "Sunday · 12 July" | Today's date in the app language (60fc168) | widget test (EN + AR); staging showed "TUESDAY · 13 OCTOBER" |
| 4 | Unknown address was a dead end; Schedules title wrapped as "Schedule s"; inspection tasks listed raw route/photo flags; two user-facing strings said "Supabase" | "Go to Home" button; title scales down (golden updated); flags hidden; plain wording (60fc168) | tests; staging screenshot of the unknown-route page |
| 5 | Offline token refresh logged an uncaught `Error` every ~20 s | The router's auth listener handles stream errors (gotrue 2.11.1 reports refresh failures there) (60fc168) | code + gotrue source; not re-observed offline with an expired token |
| 6 | Launch waited for the full network refresh before drawing | The farm hierarchy shows from the device cache at once and refreshes in the background; a failed refresh keeps it (0278c4c) | unit tests; staging warm start showed Home within 10 s |
| 7 | The 2.6 MB cache row was rewritten every launch | Same fingerprint as #1 | as #1 |
| 8 | The offline download fetched both CanvasKit engines (~6 MB each) | Only the variant this browser loads, by the engine's own test (d189167) | fresh Chrome profile cached only `canvaskit/chromium/`, offline reload rendered; Safari path not run (check the next iPhone offline start) |
| 9 | The first reload after an update ran the old build | `index.html` gives flutter.js 15 s instead of 4 s to activate the new service worker (d189167) | staging: build A → deploy B → one reload ran B |
| — | Native Android offline start showed "Unable to load farm data" ("Row too big to fit into CursorWindow", the 2.6 MB row) | Large cache values are read in 256K-character slices (de98a48) | Pixel_4 native app offline: Home and Map from cache |
| — | `lib/core/supabase/auth_repository.dart` was never committed (`.gitignore` `supabase/` matched it), so a clean checkout could not build | Rule anchored to `/supabase/`, file committed (b5bcb4b) | clean worktree analyzes clean and builds for the iOS simulator |
| — | iPhone Safari's quota showed as "39321.6 MB" in More → Offline storage | Sizes from 1 GB up show in GB ("38.4 GB") | unit test |
| — | Map tree sheet hidden under the bottom bar on wide, short windows; side panel showed the zone uuid | Sheets on the root navigator; zone code; panel scrolls (eefdd71) | test + desktop Chrome 1280x510 |

## Still open

1. **Re-check on a phone:** #1 (no "database has been locked" line on launch), #5 (no uncaught
   errors offline with an expired session), #8 on the iPhone (offline start after this update).
2. **Leaving the shell re-creates the login gate.** Opening an unknown address and coming back
   re-runs the authenticated bootstrap (a short spinner). Rare, and unchanged by these fixes.
3. **Other `.order()` calls are descending.** postgrest 2.4.1's `order()` defaults to
   `ascending: false`. Inspections and farm data were fixed on 2026-10-14 (b67fc64). Tasks
   (`created_at`, `assigned_at`), issues (`created_at`) and memberships
   (`operational_context_repository.dart`, `created_at`) still load newest first; check whether
   that is intended. Memberships decide the default farm, so change that one with care.
4. **Inspection map and GPS on phones (2026-10-14):** verified in widget tests and on staging in
   desktop Chrome with a simulated position; not yet on the iPhone or a real Android phone. Check
   that iOS asks for location once, the blue dot follows you in the field, and the aisle hints
   match where you stand.

## Inspections (2026-10-14)

| What was wrong | Fix | Verified |
|---|---|---|
| The runner opened the **last** unsaved station: items arrived newest first (postgrest default), so a real Section A session saved stations 1–7, then 153 down to 147 | Items and observations load ascending; the runner takes the lowest unsaved station whatever the order (b67fc64) | regression test with reversed items; staging shows "Aisle 1 of 8 · station 8 of 22" on that session |
| No sense of place: raw coordinates, no map, silent aisle turns, ~1,100 px per station, Save below the fold | Section map with done/issue/current trees and route (full screen, tap a saved tree to reopen it); aisle line, turn card, next trees; physical left/right cards, healthy by default; fixed "All healthy · next" bar (40d04dd) | widget tests; screenshots in EN and AR |
| No way to see your position | Opt-in GPS (geolocator 10.1.1): blue dot plus distance and aisle hints in the inspection, locate button on the Map tab; never moves the walk (40d04dd) | widget tests; staging Map tab and inspection with a simulated position |
| Location never worked in the web app (MissingPluginException) | `build_web.sh` clears `.dart_tool/flutter_build`; `Permissions-Policy: geolocation=(self)` (2a17d6e) | staging: blocked message when denied, dot and hints when granted |
| A manager watching someone else's inspection saw only "Take over" | Read-only section map and aisle line under it (2a17d6e) | widget test; staging |

## Decided

- **Desktop right-click on the map** opens Chrome's own menu (Back, Reload, Inspect…). Hiding it
  with `BrowserContextMenu.disableContextMenu()` would also remove the copy/paste menu in text
  fields, so it stays as is (user, 2026-10-14).

## Workarounds to remove when Flutter/Dart is upgraded

The toolchain is pinned to Flutter 3.13.9 / Dart 3.1.5. Each item below exists only because a
newer package needs a newer Dart. When upgrading, re-test the feature, then delete the
workaround.

| Workaround | Why it exists | Remove when |
|---|---|---|
| `tool/patches/sqlite3-2.1.0-memory-vfs-growth.patch` and `tool/build_sqflite_worker.sh` (they build `web/sqflite_sw.js`) | sqlite3 2.1.0 made the 2.6 MB cache write take about 40 s | `sqlite3` ≥ 2.2 is allowed (needs Dart 3.2); check that its in-memory VFS no longer copies the whole file on every append |
| `encodeJpegForUpload` in `lib/core/web/web_platform_html.dart` | flutter_image_compress_web 0.1.4+1 (pica) failed on iPhone Safari | flutter_image_compress_web ≥ 0.1.5 (needs Dart 3.4) works on an iPhone |
| `SturdyQrReader` in `lib/core/web/web_qr_reader.dart`, with vendored zxing-wasm 3.1.4 (zxing-cpp) | mobile_scanner 4.0.1's ZXing JS loop never read a real tag on the iPhone; zxing-cpp reads it | a newer mobile_scanner reads tags on an iPhone (check which decoder it uses); test with `tool/web_harness/qr_scanner.dart` |
| `fontFamilyFallback: ['Roboto']` on the map painter's labels | CanvasKit 3.13 downloads Noto fonts from Google for text whose style names no family | Flutter's web renderer checks glyphs against the bundled fonts by default |
| `offlinePrecacheKeys` (`lib/core/web/precache_keys.dart`) mirrors the engine's CanvasKit variant test | Flutter 3.13 lists both variants in the service worker | a Flutter upgrade: re-check `browserSupportsCanvaskitChromium` and the variant file names |
| `timeoutMillis: 15000` in `web/index.html` | flutter.js 3.13's 4 s default loaded the old build after an update | a newer flutter.js / `flutter_bootstrap.js` handles updates differently |
| `rm -rf .dart_tool/flutter_build` in `tool/build_web.sh` | Flutter 3.13 reused a stale `web_plugin_registrant.dart`, so a newly added plugin (geolocator) was missing from the web build | a Flutter version that regenerates the registrant when plugins change (add a plugin, build twice, check `main.dart.js`) |

## Things to re-test on devices

- **Camera permission on iOS:** the scanner stops the camera when you leave the Scan tab. Check
  whether iOS asks for camera permission again each time you return. If it is annoying, keep the
  camera paused instead of stopped.
- **Real Android phone.** Everything Android so far is emulator-only. Untested: low-end
  performance, the camera and photos, QR scanning, and `persist()` for a real WebAPK install.
- **Screen readers:** deferred by the user (plan P6.12).

## Testing notes

- **Emulator camera:** the Pixel_4 emulator's back camera (`virtualscene`) never returns frames to
  Chrome's `getUserMedia` (nor to the native scanner); the front camera works in Chrome (6–8 s to
  start). Test the QR loop with `tool/web_harness/qr_scanner.dart` in desktop Chrome and a fake
  camera file, as described at the top of that file.
- **Emulator network:** on 2026-10-13 the Pixel_4 lost networking (netsim Wi-Fi sees
  "AndroidWifi" but will not connect, even after `-no-snapshot-load`). Wiping its data would
  probably fix it but also removes the logged-in sessions and the installed PWA there.
- **One device at a time:** do not run the iOS simulator and the Android emulator together; the
  Mac cannot handle both (user, 2026-10-13).
- **DevTools on the emulator:** `adb forward tcp:9333 localabstract:chrome_devtools_remote`. Don't
  attach DevTools (profiler or network emulation) to the sqlite shared worker across a reload; it
  hangs the app's database open.
- **Location in headless Chrome:** `Emulation.setGeolocationOverride` and
  `Browser.grantPermissions` last only while that DevTools connection is open, so set both and
  tap in one script (scratchpad `geotap.mjs` did this). Without the override Chrome asks macOS,
  which refuses ("User denied Geolocation"). Earlier refusals are remembered per profile and carry
  into new contexts, so use a fresh `--user-data-dir`. `tool/web_harness/location.dart` checks
  geolocator_web on its own.
- **Headless Chrome:** the page reports `visibilityState = hidden`, so route transitions can stay
  frozen mid-animation in screenshots; load the URL directly to check a page.
- **Deploying from a fresh shell:** `export NVM_DIR="$HOME/.nvm"` and put `/usr/local/bin` first
  (Python 3.14; macOS's 3.9 lacked 308 handling before 2aa4c71). CocoaPods 1.17.0 is in
  `/usr/local/Cellar/cocoapods/1.17.0/bin` (not linked).

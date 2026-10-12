# PWA follow-ups

Things to look at once the PWA feature (`PWA_IMPLEMENTATION_PLAN.md`) is signed off. Each item
says what was seen, where, and what to check first. Nothing here blocks using the web app today.

Written 2026-10-12 after testing on the Pixel_4 emulator (Chrome DevTools protocol) and the
user's iPhone 11 (installed PWA). "Seen" means observed; "not verified" means reasoned from code.

## Bugs and risks (do first)

1. **"Warning database has been locked for 0:00:10" on every launch.**
   - Seen: logged by sqflite in Android Chrome on each start of the logged-in app.
   - Meaning: a database call outside a transaction waited 10 s for an open transaction to
     finish. Startup is slower than it needs to be, and code that awaits the outer call while
     holding the transaction can deadlock.
   - Check first: every `db.transaction(...)` body uses its `txn`/executor argument and never
     `_database.db` (for example `SqfliteCacheStore.writeWithExecutor`, the outbox and
     pending-photo stores, `InspectionStationLocalStore`). Not verified whether native shows it.
2. **Logout deletes unsynced offline work without warning.**
   - `AppServices.clearPrivateData()` clears the outbox and pending photos
     (`lib/core/app_services.dart`).
   - Native behaves the same; this was not introduced by the web work.
   - Suggested: when the outbox is not empty, confirm before signing out ("N changes have not
     been uploaded").
3. **Home date header is fixed text.** `homeDateEyebrow` in `lib/l10n/arb/app_en.arb` (and the
   Arabic file) is the literal "Sunday · 12 July". Replace it with a formatted current date.
4. **Production security policy (CSP) is still report-only.**
   - Staging enforces it, and the emulator showed no violations after the font fix.
   - Before switching: log in on staging, upload a photo and scan a tag. Then run
     `CSP_MODE=enforce ./tool/deploy_web.sh main`.

## Speed

5. **The map waits for a full network refresh** (about 7 s on the emulator) before drawing,
   even when cached data is already on the device. Consider showing the cached hierarchy at once
   and refreshing in the background (`DefaultFarmHierarchyRepository.load`).
6. **The farm hierarchy cache is one 2.6 MB JSON row, rewritten on every launch.** It is fast
   since the sqlite patch, but skipping the write when the data has not changed, or storing rows
   per tree, would save work on every start.
7. **The offline download fetches both CanvasKit engines** (`canvaskit/` and
   `canvaskit/chromium/`, about 6 MB each). A browser only uses one of them, so
   `precacheAppShell` could skip the other and save about 6 MB of storage per device.
8. **The first reload after an update runs the old code.** flutter.js 3.13 gives the new service
   worker 4 s, then loads with the old one. The new code runs from the next launch. Options: wait
   longer for the new worker, or reload once more automatically after the update banner's reload.

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

## Things to re-test on devices

9. **QR scanning on the iPhone** with `SturdyQrReader` (zxing-cpp since `sturdy-3`). Verified in
   Chrome with a fake camera fed the iPhone's own frame; ZXing JS could not read that frame. Long-press the scan screen's message box for the reader's live numbers. If the
   decoder never succeeds on iOS, options are a "scan from photo" button (decode a full-resolution
   still taken with the iPhone camera) or manual tree-code entry (plan P4.10).
10. **Camera permission on iOS:** the scanner now stops the camera when you leave the Scan tab.
    Check whether iOS asks for camera permission again each time you return. If it is annoying,
    keep the camera paused instead of stopped.
11. **Real Android phone.** Everything Android so far is emulator-only. Untested: low-end
    performance, the camera and photos, QR scanning, and `persist()` for a real WebAPK install.
    On the emulator, Chrome made a plain shortcut install: `persisted()` was false, and More still
    offers "Install app".
12. **Screen readers:** decide on Flutter's "Enable accessibility" placeholder (plan D11 / P6.11)
    and do a VoiceOver pass on the installed iPhone app (P6.12).

## Open items in the plan (see §3 of `PWA_IMPLEMENTATION_PLAN.md`)

- ⛔ P5.4 needs the user's acceptance: the `flutter drive` test was replaced by DevTools-protocol
  checks.
- P0.8-6: production on iPhone over cellular and Wi-Fi without VPN (explicit check).
- P5.6: the update flow on the iPhone. The emulator showed the banner and the second-launch
  update.
- P5.7: an expired session token while offline.
- P6.3–P6.5 (install on desktop Chrome, iPhone safe areas, browser back/forward/refresh),
  P6.10 (desktop right-click on the map).
- P8.5: logged-in walkthrough with the CSP checked, then enforce in production (item 4).
- P9.2: run the native app on the iPhone or simulator and on the Pixel_4 to check for regressions.

## Testing notes

- **Emulator camera:** the Pixel_4 emulator's back camera (`virtualscene`) never returns frames to
  Chrome's `getUserMedia`; the front camera works (6–8 s to start). Test the QR loop with
  `tool/web_harness/qr_scanner.dart` in desktop Chrome and a fake camera file, as described at the
  top of that file.
- **DevTools on the emulator:** `adb forward tcp:9333 localabstract:chrome_devtools_remote`. Don't
  leave a profiler attached to the sqlite shared worker across a reload; that hung the app once.

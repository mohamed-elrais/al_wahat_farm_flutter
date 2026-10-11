# Vendored web scripts

Third-party scripts the web plugins expect as globals. They are served from this
origin (not a CDN) so the service worker can cache them for offline use
(PWA_IMPLEMENTATION_PLAN.md, D5). They are loaded by `web/index.html` before
`flutter.js`.

| File | Global | Needed by | Source | License | SHA-256 |
|---|---|---|---|---|---|
| `pica-9.0.1.min.js` | `window.pica` | `flutter_image_compress_web` 0.1.4+1 (photo compression) | https://cdn.jsdelivr.net/npm/pica@9.0.1/dist/pica.min.js | MIT (`pica@9.0.1/package.json`) | `1f0987f8a2e9cf6993ca6bb21ff34b56600b4af6e39c46290b89df55acda2b70` |
| `zxing-library-0.19.1.min.js` | `ZXing` | `mobile_scanner` 4.0.1 web (QR scanning) | https://unpkg.com/@zxing/library@0.19.1/umd/index.min.js (the target of the README URL `https://unpkg.com/@zxing/library@0.19.1`) | MIT (`@zxing/library@0.19.1/package.json`) | `c5837e4858a3775173bab09ee36e6052545c7880c9d7452e2f464770c6e642ce` |

The versions are the ones the plugin READMEs name. Update them only together with
the plugin, re-download from the same URLs, and update the checksums above
(`shasum -a 256 web/vendor/*.js`).

## SQLite for the web database (`web/sqlite3.wasm`, `web/sqflite_sw.js`)

Used by `sqflite_common_ffi_web` 0.4.2+1 (see `lib/core/database/database_platform_web.dart`).
They live in `web/` (not `web/vendor/`) because the package loads them from those
paths.

| File | Source | SHA-256 |
|---|---|---|
| `sqflite_sw.js` | Built locally: `dart run sqflite_common_ffi_web:setup --no-sqlite3-wasm` (compiles the package's shared worker against `sqlite3` 2.1.0) | `2ea5708257325f2eb43f46f14bd053122ab145ec71bed1bf5af7884e3b33d370` |
| `sqlite3.wasm` | https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-2.1.0/sqlite3.wasm | `5ec135f5407f5626982717034ce0d3346ae4e630d86253da57319c78c8513562` |

Do **not** run the setup without `--no-sqlite3-wasm`: version 0.4.2+1 hardcodes the
`sqlite3-2.2.0` wasm, but the Dart `sqlite3` package is pinned at 2.1.0 because 2.2.0
needs Dart 3.2. The wasm must come from the release matching `sqlite3` in
`pubspec.lock`. If that version changes, re-run the setup with `--force
--no-sqlite3-wasm` and download the matching wasm.

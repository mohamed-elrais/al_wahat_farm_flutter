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
| `sqflite_sw.js` | Built locally with `tool/build_sqflite_worker.sh`: the package's shared worker compiled against `sqlite3` 2.1.0 plus `tool/patches/sqlite3-2.1.0-memory-vfs-growth.patch` | `56e4247f282b8aa89d2ca69752477615f931491319a0399e49769531ad0f27af` |
| `sqlite3.wasm` | https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-2.1.0/sqlite3.wasm | `5ec135f5407f5626982717034ce0d3346ae4e630d86253da57319c78c8513562` |

**Why the patch:** in `sqlite3` 2.1.0 the in-memory file behind the IndexedDB file
system copies the whole file into a new exact-size array on every write past its
end. sqlite grows files one page at a time, so writing the 2.6 MB farm hierarchy
cache took ~40 s on a Pixel 4 emulator (profiled 2026-10-12). The patch keeps
files as views over a buffer with doubling capacity; a randomized check against a
plain model matched over 60,000 operations, and 10 MB of 8 KB appends went from
4.9 s to 17 ms on the Dart VM. Newer `sqlite3` releases need Dart 3.2+.

Do **not** run `dart run sqflite_common_ffi_web:setup` on its own: it rebuilds an
unpatched worker, and without `--no-sqlite3-wasm` it also fetches the
`sqlite3-2.2.0` wasm (the Dart `sqlite3` package is pinned at 2.1.0 because 2.2.0
needs Dart 3.2). The wasm must come from the release matching `sqlite3` in
`pubspec.lock`. If that version changes, the build script stops; port the patch
and download the matching wasm.

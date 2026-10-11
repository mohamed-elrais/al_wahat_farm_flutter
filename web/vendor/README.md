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

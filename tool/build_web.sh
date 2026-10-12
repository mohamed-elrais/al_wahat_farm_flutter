#!/bin/sh
# Builds the PWA into build/web for Cloudflare Pages (see PWA_IMPLEMENTATION_PLAN.md, D10).
#
# Environment: DEFINES (defines file), BASE_HREF (default /), CSP_MODE
# (report | enforce, default report).
#
# Only SUPABASE_URL and SUPABASE_ANON_KEY are compiled into the public bundle:
# unless DEFINES points at a file, config.web.json is regenerated from
# config.json with just those two keys, so test credentials never reach the web.
set -eu
cd "$(dirname "$0")/.."

if [ -z "${DEFINES:-}" ]; then
  DEFINES=config.web.json
  if [ ! -f config.json ]; then
    echo "error: config.json not found (copy config.example.json)" >&2
    exit 1
  fi
  python3 - "$DEFINES" <<'EOF'
import json
import sys

source = json.load(open('config.json'))
keys = ('SUPABASE_URL', 'SUPABASE_ANON_KEY')
missing = [key for key in keys if not str(source.get(key, '')).strip()]
if missing:
    sys.exit('error: config.json is missing ' + ', '.join(missing))
with open(sys.argv[1], 'w') as out:
    json.dump({key: source[key] for key in keys}, out, indent=2)
EOF
fi

# Files the web build cannot work without (see web/vendor/README.md).
for required in web/sqlite3.wasm web/sqflite_sw.js \
  web/vendor/zxing-library-0.19.1.min.js \
  web/vendor/zxing-wasm-reader-3.1.4.js web/vendor/zxing_reader-3.1.4.wasm; do
  if [ ! -s "$required" ]; then
    echo "error: missing $required (see web/vendor/README.md)" >&2
    exit 1
  fi
done

if ! flutter --version | grep -q 'Flutter 3.13.9'; then
  echo "warning: expected Flutter 3.13.9 (see toolchain constraints)" >&2
fi

# Start clean: Flutter lists every file already in build/web in the service
# worker's RESOURCES, including a _headers copied there by a previous run.
rm -rf build/web

flutter build web --release \
  --web-renderer canvaskit \
  --no-web-resources-cdn \
  --base-href "${BASE_HREF:-/}" \
  --dart-define-from-file="$DEFINES"

# Fill the CSP: Supabase origin from the same defines the app uses, and
# hashes of index.html's inline scripts. CSP_MODE=enforce sends
# Content-Security-Policy; the default keeps it report-only until the policy
# has been checked in a logged-in session.
python3 - "$DEFINES" "${CSP_MODE:-report}" <<'EOF'
import base64
import hashlib
import json
import re
import sys
from urllib.parse import urlsplit

url = urlsplit(json.load(open(sys.argv[1]))['SUPABASE_URL'])
origin = f'{url.scheme}://{url.netloc}'
headers = open('tool/hosting/_headers').read()
headers = headers.replace('__SUPABASE_WS_ORIGIN__', f'wss://{url.netloc}')
headers = headers.replace('__SUPABASE_ORIGIN__', origin)
page = open('build/web/index.html', encoding='utf-8').read()
inline = re.findall(r'<script>(.*?)</script>', page, re.S)
hashes = ' '.join(
    "'sha256-%s'" % base64.b64encode(hashlib.sha256(body.encode()).digest()).decode()
    for body in inline)
headers = headers.replace('__INLINE_SCRIPT_HASHES__', hashes)
if sys.argv[2] == 'enforce':
    headers = headers.replace('Content-Security-Policy-Report-Only:',
                              'Content-Security-Policy:')
elif sys.argv[2] != 'report':
    sys.exit('error: CSP_MODE must be report or enforce')
if '__SUPABASE' in headers or '__INLINE' in headers:
    sys.exit('error: unfilled placeholder in _headers')
open('build/web/_headers', 'w').write(headers)
EOF
if grep -q '"_headers"' build/web/flutter_service_worker.js; then
  echo "error: _headers is listed in the service worker RESOURCES" >&2
  exit 1
fi

du -sh build/web

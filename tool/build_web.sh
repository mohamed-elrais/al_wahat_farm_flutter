#!/bin/sh
# Builds the PWA into build/web for Cloudflare Pages (see PWA_IMPLEMENTATION_PLAN.md, D10).
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

cp tool/hosting/_headers build/web/_headers
if grep -q '"_headers"' build/web/flutter_service_worker.js; then
  echo "error: _headers is listed in the service worker RESOURCES" >&2
  exit 1
fi

du -sh build/web

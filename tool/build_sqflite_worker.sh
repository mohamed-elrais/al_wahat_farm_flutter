#!/bin/sh
# Rebuilds web/sqflite_sw.js (the web database's shared worker) against
# sqlite3 2.1.0 with tool/patches/sqlite3-2.1.0-memory-vfs-growth.patch applied.
# See web/vendor/README.md. The app's own dependencies are not changed: the
# override applies only to the worker's build workspace under .dart_tool.
set -eu
cd "$(dirname "$0")/.."

version=2.1.0
source="${PUB_CACHE:-$HOME/.pub-cache}/hosted/pub.dev/sqlite3-$version"
if ! grep -A7 '^  sqlite3:' pubspec.lock | grep -q "version: \"$version\""; then
  echo "error: pubspec.lock no longer resolves sqlite3 $version; update the patch" >&2
  exit 1
fi
if [ ! -d "$source" ]; then
  echo "error: $source not found (run flutter pub get)" >&2
  exit 1
fi

# Creates the package's build workspace (and a stock worker) if missing.
dart run sqflite_common_ffi_web:setup --no-sqlite3-wasm
workspace=$(ls -d .dart_tool/sqflite_common_ffi_web/setup/*/ | tail -n 1)

patched=.dart_tool/awf_sqlite3_patched
rm -rf "$patched"
cp -R "$source" "$patched"
chmod -R u+w "$patched"
patch -d "$patched" -p1 < tool/patches/sqlite3-2.1.0-memory-vfs-growth.patch

printf 'dependency_overrides:\n  sqlite3:\n    path: %s\n' \
  "$(cd "$patched" && pwd)" > "$workspace/pubspec_overrides.yaml"
(cd "$workspace" && dart pub get && dart run webdev build -o web:build)

cp "$workspace/build/sqflite_sw.dart.js" web/sqflite_sw.js
shasum -a 256 web/sqflite_sw.js

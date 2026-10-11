#!/bin/sh
# Builds the PWA, deploys it to Cloudflare Pages, and checks every
# service-worker resource on the deployed URL (PWA_IMPLEMENTATION_PLAN.md, D10).
#
# Usage: tool/deploy_web.sh staging   -> https://staging.al-wahat-farm.pages.dev
#        tool/deploy_web.sh main      -> https://al-wahat-farm.pages.dev (production)
set -eu
cd "$(dirname "$0")/.."

branch="${1:?usage: tool/deploy_web.sh staging|main}"

./tool/build_web.sh

# wrangler needs the Node version pinned in .nvmrc; nvm.sh is not -u safe.
set +u
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
. "$NVM_DIR/nvm.sh"
nvm use >/dev/null
set -u

dirty=""
if [ -n "$(git status --porcelain)" ]; then
  dirty="--commit-dirty=true"
fi
# shellcheck disable=SC2086
npx --yes wrangler@4.149.0 pages deploy build/web \
  --project-name al-wahat-farm \
  --branch "$branch" \
  --commit-hash "$(git rev-parse HEAD)" \
  --commit-message "$(git log -1 --format=%s)" \
  $dirty

if [ "$branch" = "main" ]; then
  url="https://al-wahat-farm.pages.dev"
else
  url="https://$branch.al-wahat-farm.pages.dev"
fi
sleep 10
python3 -I tool/verify_deploy.py "$url"

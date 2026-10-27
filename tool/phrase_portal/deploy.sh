#!/usr/bin/env bash
# Build the static portal and upload it to the VPS web root served by nginx
# (vhost portal.surveyscriber.com -> /var/www/surveyscriber-portal, /api/ -> backend).
#
# Usage (from the repo root or this folder):
#   bash tool/phrase_portal/deploy.sh            # build + upload
#   bash tool/phrase_portal/deploy.sh --build    # build only (dist/)
#
# Override with env: SSH_HOST, SSH_PORT, SSH_USER, SSH_KEY, WEB_ROOT
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
DIST="$HERE/dist"
SSH_HOST="${SSH_HOST:-158.69.1.183}"
SSH_PORT="${SSH_PORT:-2222}"
SSH_USER="${SSH_USER:-naija}"
SSH_KEY="${SSH_KEY:-$HOME/.ssh/nijahomzs}"
WEB_ROOT="${WEB_ROOT:-/var/www/surveyscriber-portal}"

echo "[1/3] test"
node --test "$HERE/test.js" >/dev/null

echo "[2/3] build -> $DIST"
rm -rf "$DIST"
mkdir -p "$DIST/assets/banks"
cp "$HERE/public/index.html" "$HERE/public/app.js" "$HERE/public/bank-logic.js" "$HERE/public/styles.css" "$DIST/"
# Baseline banks: used only until a bank is published on the server (first save publishes the full bank).
cp "$REPO/assets/property_inspection/phrase_texts.json" "$DIST/assets/banks/inspection.json"
cp "$REPO/assets/property_valuation/phrase_texts.json" "$DIST/assets/banks/valuation.json"
node -e "JSON.parse(require('fs').readFileSync('$DIST/assets/banks/inspection.json','utf8'));JSON.parse(require('fs').readFileSync('$DIST/assets/banks/valuation.json','utf8'))"
( cd "$DIST" && git -C "$REPO" rev-parse --short HEAD > BUILD 2>/dev/null || date -u +%Y%m%dT%H%M%SZ > BUILD )
ls -la "$DIST" "$DIST/assets/banks"

if [[ "${1:-}" == "--build" ]]; then exit 0; fi

echo "[3/3] upload -> $SSH_USER@$SSH_HOST:$WEB_ROOT"
SSH=(ssh -p "$SSH_PORT" -i "$SSH_KEY" -o IdentitiesOnly=yes -o BatchMode=yes)
"${SSH[@]}" "$SSH_USER@$SSH_HOST" "mkdir -p '$WEB_ROOT/assets/banks'"
scp -P "$SSH_PORT" -i "$SSH_KEY" -o IdentitiesOnly=yes -o BatchMode=yes \
  "$DIST"/index.html "$DIST"/app.js "$DIST"/bank-logic.js "$DIST"/styles.css "$DIST"/BUILD \
  "$SSH_USER@$SSH_HOST:$WEB_ROOT/"
scp -P "$SSH_PORT" -i "$SSH_KEY" -o IdentitiesOnly=yes -o BatchMode=yes \
  "$DIST"/assets/banks/*.json "$SSH_USER@$SSH_HOST:$WEB_ROOT/assets/banks/"
"${SSH[@]}" "$SSH_USER@$SSH_HOST" "ls -la '$WEB_ROOT' '$WEB_ROOT/assets/banks' && cat '$WEB_ROOT/BUILD'"
echo "Deployed. Check: curl -s -H 'Host: portal.surveyscriber.com' http://$SSH_HOST/ | head -c 200"

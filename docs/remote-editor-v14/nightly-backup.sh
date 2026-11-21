#!/bin/bash
# SurveyScriber nightly backup: database + report storage, encrypted, 30-day rolling.
# Run as the deploy user (naija) from cron. See DEPLOY-NOTES.md section 5.
#
# One-time setup (as naija):
#   install -m 700 -d ~/ss-backups
#   [ -f ~/.ss-backup-pass ] || { umask 077; openssl rand -hex 32 > ~/.ss-backup-pass; }
#   COPY ~/.ss-backup-pass TO A PASSWORD MANAGER. Without it the backups cannot be opened.
#   crontab -e  ->  30 2 * * * /home/naija/ss-nightly-backup.sh >> /home/naija/ss-backups/backup.log 2>&1
#
# Off-server copy (spec: backups must be off-server): set OFFSITE_CMD in ~/.ss-backup.env, e.g.
#   OFFSITE_CMD='rclone copy "$FILE" remote:surveyscriber-backups/'
#   OFFSITE_CMD='scp -P 22 -i ~/.ssh/backup_key "$FILE" user@backuphost:/backups/'
# $FILE is each encrypted file made today. If OFFSITE_CMD is empty the backup stays on this server
# and the log says so.
set -u
set -o pipefail
APP=/home/ubuntu/surveyscriber-backend
OUT=$HOME/ss-backups
PASS=$HOME/.ss-backup-pass
KEEP_DAYS=30
TS=$(date +%Y%m%d_%H%M%S)
[ -f "$HOME/.ss-backup.env" ] && . "$HOME/.ss-backup.env"
OFFSITE_CMD="${OFFSITE_CMD:-}"

log() { echo "$(date '+%F %T') $*"; }
[ -s "$PASS" ] || { log "FAIL: $PASS missing or empty"; exit 1; }
mkdir -p "$OUT" && chmod 700 "$OUT"
cd "$APP" || { log "FAIL: no $APP"; exit 1; }
set -a; . ./.env >/dev/null 2>&1; set +a
URL="${DATABASE_URL%%\?*}"
STORE="$(readlink -f "${MEDIA_LOCAL_ROOT:-storage}")"

enc() { openssl enc -aes-256-cbc -pbkdf2 -salt -pass "file:$PASS"; }

DB="$OUT/ss-db-$TS.dump.enc"
pg_dump --no-owner -Fc "$URL" | enc > "$DB" || { log "FAIL: database dump"; rm -f "$DB"; exit 1; }
FILES="$OUT/ss-storage-$TS.tgz.enc"
tar czf - -C "$(dirname "$STORE")" "$(basename "$STORE")" | enc > "$FILES" || { log "FAIL: storage archive"; rm -f "$FILES"; exit 1; }
chmod 600 "$DB" "$FILES"
for f in "$DB" "$FILES"; do
  [ -s "$f" ] || { log "FAIL: empty file $f"; exit 1; }
  # prove it opens with the key, so a bad key is found today, not on restore day
  openssl enc -d -aes-256-cbc -pbkdf2 -pass "file:$PASS" -in "$f" >/dev/null || { log "FAIL: cannot decrypt $f"; exit 1; }
  log "ok $(basename "$f") $(stat -c %s "$f") bytes"
  if [ -n "$OFFSITE_CMD" ]; then
    FILE="$f" bash -c "$OFFSITE_CMD" && log "offsite ok $(basename "$f")" || log "WARN: offsite copy failed for $(basename "$f")"
  fi
done
[ -n "$OFFSITE_CMD" ] || log "WARN: no OFFSITE_CMD, backups are on this server only"

# rolling retention: nothing older than KEEP_DAYS stays
find "$OUT" -maxdepth 1 -type f \( -name 'ss-db-*.enc' -o -name 'ss-storage-*.enc' \) -mtime +"$KEEP_DAYS" -print -delete | sed 's/^/deleted old: /'
log "done"

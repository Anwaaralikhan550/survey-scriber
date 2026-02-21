#!/bin/bash
# H4 FIX: Database Restore Script
# Usage: ./scripts/restore-database.sh /path/to/backup.sql.gz
#
# WARNING: This will DROP and recreate all tables!
# Only run in maintenance window after confirming backup integrity.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] INFO:${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARN:${NC} $1"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1"
}

# Check arguments
if [ -z "$1" ]; then
    log_error "Usage: $0 /path/to/backup.sql.gz"
    exit 1
fi

BACKUP_FILE="$1"
DATABASE_URL="${DATABASE_URL:-}"

# Validate backup file exists
if [ ! -f "$BACKUP_FILE" ]; then
    log_error "Backup file not found: $BACKUP_FILE"
    exit 1
fi

# Validate required tools
command -v psql >/dev/null 2>&1 || { log_error "psql is required but not installed."; exit 1; }
command -v gunzip >/dev/null 2>&1 || { log_error "gunzip is required but not installed."; exit 1; }

# Validate DATABASE_URL
if [ -z "$DATABASE_URL" ]; then
    if [ -f "$(dirname "$0")/../.env" ]; then
        source "$(dirname "$0")/../.env"
    fi

    if [ -z "$DATABASE_URL" ]; then
        log_error "DATABASE_URL environment variable is required"
        exit 1
    fi
fi

# Parse DATABASE_URL
if [[ "$DATABASE_URL" =~ ^postgresql://([^:]+):([^@]+)@([^:]+):([^/]+)/(.+)$ ]]; then
    DB_USER="${BASH_REMATCH[1]}"
    DB_PASS="${BASH_REMATCH[2]}"
    DB_HOST="${BASH_REMATCH[3]}"
    DB_PORT="${BASH_REMATCH[4]}"
    DB_NAME="${BASH_REMATCH[5]}"
else
    log_error "Invalid DATABASE_URL format"
    exit 1
fi

log_warn "===== DATABASE RESTORE WARNING ====="
log_warn "This will restore the database from: $BACKUP_FILE"
log_warn "Target database: $DB_NAME on $DB_HOST:$DB_PORT"
log_warn "ALL EXISTING DATA WILL BE REPLACED!"
log_warn "===================================="
echo ""
read -p "Type 'RESTORE' to confirm: " CONFIRM

if [ "$CONFIRM" != "RESTORE" ]; then
    log_info "Restore cancelled"
    exit 0
fi

log_info "Starting database restore..."

# Verify backup integrity
log_info "Verifying backup integrity..."
if ! gzip -t "$BACKUP_FILE" 2>/dev/null; then
    log_error "Backup file is corrupted!"
    exit 1
fi
log_info "Backup integrity verified"

# Perform the restore
log_info "Restoring database: $DB_NAME"
export PGPASSWORD="$DB_PASS"

gunzip -c "$BACKUP_FILE" | psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
    --quiet \
    --single-transaction \
    2>&1

unset PGPASSWORD

log_info "Database restored successfully from: $BACKUP_FILE"
log_warn "Remember to run 'npx prisma migrate deploy' if there are pending migrations"

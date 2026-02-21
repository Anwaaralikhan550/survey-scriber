#!/bin/bash
# H4 FIX: Automated Database Backup Script
# Usage: ./scripts/backup-database.sh
# Cron: 0 2 * * * /path/to/backend/scripts/backup-database.sh >> /var/log/surveyscriber-backup.log 2>&1

set -e

# Configuration (can be overridden via environment variables)
BACKUP_DIR="${BACKUP_DIR:-/var/backups/surveyscriber}"
RETENTION_DAYS="${RETENTION_DAYS:-30}"
DATABASE_URL="${DATABASE_URL:-}"

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

# Validate required tools
command -v pg_dump >/dev/null 2>&1 || { log_error "pg_dump is required but not installed."; exit 1; }
command -v gzip >/dev/null 2>&1 || { log_error "gzip is required but not installed."; exit 1; }

# Validate DATABASE_URL
if [ -z "$DATABASE_URL" ]; then
    # Try to load from .env file
    if [ -f "$(dirname "$0")/../.env" ]; then
        source "$(dirname "$0")/../.env"
    fi

    if [ -z "$DATABASE_URL" ]; then
        log_error "DATABASE_URL environment variable is required"
        log_error "Set it directly or ensure .env file exists in backend directory"
        exit 1
    fi
fi

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Generate timestamp for backup filename
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/surveyscriber_backup_$TIMESTAMP.sql.gz"

log_info "Starting database backup..."
log_info "Backup directory: $BACKUP_DIR"
log_info "Retention: $RETENTION_DAYS days"

# Parse DATABASE_URL to extract connection details
# Format: postgresql://user:password@host:port/database
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

# Perform the backup
log_info "Dumping database: $DB_NAME"
export PGPASSWORD="$DB_PASS"

pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
    --format=plain \
    --no-owner \
    --no-acl \
    --verbose \
    2>/dev/null | gzip > "$BACKUP_FILE"

unset PGPASSWORD

# Verify backup file was created and has content
if [ -f "$BACKUP_FILE" ] && [ -s "$BACKUP_FILE" ]; then
    BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    log_info "Backup created successfully: $BACKUP_FILE ($BACKUP_SIZE)"
else
    log_error "Backup file was not created or is empty"
    exit 1
fi

# Clean up old backups
log_info "Cleaning up backups older than $RETENTION_DAYS days..."
DELETED_COUNT=$(find "$BACKUP_DIR" -name "surveyscriber_backup_*.sql.gz" -mtime +$RETENTION_DAYS -delete -print | wc -l)
log_info "Deleted $DELETED_COUNT old backup(s)"

# List current backups
CURRENT_BACKUPS=$(find "$BACKUP_DIR" -name "surveyscriber_backup_*.sql.gz" | wc -l)
log_info "Current backups retained: $CURRENT_BACKUPS"

# Optional: Test backup integrity by checking gzip
if gzip -t "$BACKUP_FILE" 2>/dev/null; then
    log_info "Backup integrity verified"
else
    log_error "Backup integrity check failed!"
    exit 1
fi

log_info "Backup completed successfully"
echo "---"

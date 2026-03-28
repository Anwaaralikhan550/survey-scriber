-- Run this as a PostgreSQL admin/superuser (NOT as limited app user).
-- Creates dedicated shadow database for Prisma Migrate.

CREATE DATABASE surveyscriber_shadow_db;

-- Optional but recommended: make app user owner of shadow DB.
ALTER DATABASE surveyscriber_shadow_db OWNER TO surveyscriber;

-- Optional: if your org does not allow ownership changes, use grants.
GRANT ALL PRIVILEGES ON DATABASE surveyscriber_shadow_db TO surveyscriber;

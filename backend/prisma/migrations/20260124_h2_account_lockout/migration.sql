-- H2 FIX: Add account lockout fields for brute-force protection
-- OWASP A7: Identification and Authentication Failures mitigation

-- Add failed login attempt counter
ALTER TABLE users
ADD COLUMN failed_login_attempts INT NOT NULL DEFAULT 0;

-- Add lockout timestamp (NULL = not locked)
ALTER TABLE users
ADD COLUMN locked_until TIMESTAMP(3) NULL;

-- Add index for efficient lockout queries
CREATE INDEX idx_users_locked_until ON users (locked_until)
WHERE locked_until IS NOT NULL;

-- Add comment for documentation
COMMENT ON COLUMN users.failed_login_attempts IS 'Counter for consecutive failed login attempts. Reset on successful login.';
COMMENT ON COLUMN users.locked_until IS 'Account locked until this timestamp. NULL means not locked.';

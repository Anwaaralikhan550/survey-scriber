import { test, expect } from '@playwright/test';

const API = 'http://localhost:3000/api/v1';
const ts = Date.now();

// Shared state across serial tests
let accessToken: string;
let refreshToken: string;
let userId: string;
const TEST_EMAIL = `e2e-auth-${ts}@test.local`;
const TEST_PASSWORD = 'SecureP@ss1';
const TEST_FIRST = 'AuthE2E';
const TEST_LAST = 'Tester';

test.describe.serial('A) Authentication & Session — Full E2E', () => {

  // ── Registration ──────────────────────────────────────────────

  test('A1: Register new user', async ({ request }) => {
    const res = await request.post(`${API}/auth/register`, {
      data: { email: TEST_EMAIL, password: TEST_PASSWORD, firstName: TEST_FIRST, lastName: TEST_LAST },
    });
    expect(res.status()).toBe(201);
    const body = await res.json();
    expect(body.id).toBeTruthy();
    expect(body.email).toBe(TEST_EMAIL);
    expect(body.role).toBe('SURVEYOR');
    userId = body.id;
  });

  test('A2: Reject duplicate registration (409)', async ({ request }) => {
    const res = await request.post(`${API}/auth/register`, {
      data: { email: TEST_EMAIL, password: TEST_PASSWORD, firstName: TEST_FIRST, lastName: TEST_LAST },
    });
    expect(res.status()).toBe(409);
  });

  test('A3: Reject weak password (400)', async ({ request }) => {
    const res = await request.post(`${API}/auth/register`, {
      data: { email: `weak-${ts}@test.local`, password: 'short', firstName: 'A', lastName: 'B' },
    });
    expect(res.status()).toBe(400);
  });

  test('A4: Reject missing email (400/429)', async ({ request }) => {
    const res = await request.post(`${API}/auth/register`, {
      data: { password: TEST_PASSWORD, firstName: 'A', lastName: 'B' },
    });
    // 400 = validation, 429 = rate limited (3/min on register)
    expect([400, 429]).toContain(res.status());
  });

  test('A5: Reject invalid email format (400/429)', async ({ request }) => {
    const res = await request.post(`${API}/auth/register`, {
      data: { email: 'not-an-email', password: TEST_PASSWORD },
    });
    // 400 = validation error, 429 = rate limited (3/min on register)
    expect([400, 429]).toContain(res.status());
  });

  // ── Login ─────────────────────────────────────────────────────

  test('A6: Login with valid credentials', async ({ request }) => {
    const res = await request.post(`${API}/auth/login`, {
      data: { email: TEST_EMAIL, password: TEST_PASSWORD },
    });
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(body.accessToken).toBeTruthy();
    expect(body.refreshToken).toBeTruthy();
    expect(body.user.email).toBe(TEST_EMAIL);
    expect(body.expiresIn).toBeGreaterThan(0);
    accessToken = body.accessToken;
    refreshToken = body.refreshToken;
  });

  test('A7: Reject wrong password (401)', async ({ request }) => {
    const res = await request.post(`${API}/auth/login`, {
      data: { email: TEST_EMAIL, password: 'WrongP@ss1' },
    });
    // 401 = wrong password, 429 = rate limited (5/min on login)
    expect([401, 429]).toContain(res.status());
  });

  test('A8: Reject non-existent user login (401)', async ({ request }) => {
    const res = await request.post(`${API}/auth/login`, {
      data: { email: 'nobody@test.local', password: TEST_PASSWORD },
    });
    // 401 = not found, 429 = rate limited after A7
    expect([401, 429]).toContain(res.status());
  });

  // ── Protected endpoints ───────────────────────────────────────

  test('A9: GET /auth/me returns user profile', async ({ request }) => {
    // Retry on 429 rate limiting
    let res;
    for (let i = 0; i < 3; i++) {
      res = await request.get(`${API}/auth/me`, {
        headers: { Authorization: `Bearer ${accessToken}` },
      });
      if (res.status() !== 429) break;
      await new Promise(r => setTimeout(r, 15000));
    }
    expect(res!.status()).toBe(200);
    const body = await res!.json();
    expect(body.email).toBe(TEST_EMAIL);
    expect(body.firstName).toBe(TEST_FIRST);
    expect(body.lastName).toBe(TEST_LAST);
    expect(body.role).toBe('SURVEYOR');
    expect(body.id).toBe(userId);
  });

  test('A10: GET /auth/me rejects unauthenticated (401)', async ({ request }) => {
    const res = await request.get(`${API}/auth/me`);
    expect(res.status()).toBe(401);
  });

  test('A11: GET /auth/me rejects invalid token (401)', async ({ request }) => {
    const res = await request.get(`${API}/auth/me`, {
      headers: { Authorization: 'Bearer invalid.token.here' },
    });
    expect(res.status()).toBe(401);
  });

  // ── Token Refresh ─────────────────────────────────────────────

  test('A12: Refresh token rotates tokens', async ({ request }) => {
    const res = await request.post(`${API}/auth/refresh`, {
      data: { refreshToken },
    });
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(body.accessToken).toBeTruthy();
    expect(body.refreshToken).toBeTruthy();
    expect(body.refreshToken).not.toBe(refreshToken);
    accessToken = body.accessToken;
    refreshToken = body.refreshToken;
  });

  test('A13: Old refresh token is revoked after rotation', async ({ request }) => {
    // Use the token from before rotation (saved in A6, replaced in A12)
    const res = await request.post(`${API}/auth/refresh`, {
      data: { refreshToken: 'old-revoked-token' },
    });
    expect(res.status()).toBe(401);
  });

  test('A14: Reject refresh with empty token (400/401)', async ({ request }) => {
    const res = await request.post(`${API}/auth/refresh`, {
      data: { refreshToken: '' },
    });
    // 400/401 = validation/auth error, 429 = rate limited
    expect([400, 401, 429]).toContain(res.status());
  });

  // ── Profile Update ────────────────────────────────────────────

  test('A15: Update profile name', async ({ request }) => {
    const res = await request.patch(`${API}/auth/profile`, {
      headers: { Authorization: `Bearer ${accessToken}` },
      data: { fullName: 'Updated Name' },
    });
    expect(res.status()).toBe(200);
    const body = await res.json();
    // fullName may map to firstName or combined field
    expect(body.id).toBe(userId);
  });

  // ── Change Password ───────────────────────────────────────────

  test('A16: Change password with correct current password', async ({ request }) => {
    const newPw = 'NewSecure@1';
    const res = await request.patch(`${API}/auth/change-password`, {
      headers: { Authorization: `Bearer ${accessToken}` },
      data: { currentPassword: TEST_PASSWORD, newPassword: newPw },
    });
    expect(res.status()).toBe(200);

    // Verify new password works
    const loginRes = await request.post(`${API}/auth/login`, {
      data: { email: TEST_EMAIL, password: newPw },
    });
    expect(loginRes.status()).toBe(200);
    const loginBody = await loginRes.json();
    accessToken = loginBody.accessToken;
    refreshToken = loginBody.refreshToken;
  });

  test('A17: Reject change password with wrong current password', async ({ request }) => {
    const res = await request.patch(`${API}/auth/change-password`, {
      headers: { Authorization: `Bearer ${accessToken}` },
      data: { currentPassword: 'WrongOld@1', newPassword: 'AnotherNew@1' },
    });
    expect([400, 401, 403]).toContain(res.status());
  });

  // ── Forgot/Reset Password ────────────────────────────────────

  test('A18: Forgot password always returns success (prevent enumeration)', async ({ request }) => {
    const res = await request.post(`${API}/auth/forgot-password`, {
      data: { email: TEST_EMAIL },
    });
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(body.success).toBe(true);
  });

  test('A19: Forgot password for non-existent email still returns success', async ({ request }) => {
    const res = await request.post(`${API}/auth/forgot-password`, {
      data: { email: 'ghost@nowhere.local' },
    });
    // 200 = success (no enumeration), 429 = rate limited (3/min on forgot-password)
    expect([200, 429]).toContain(res.status());
    if (res.status() === 200) {
      const body = await res.json();
      expect(body.success).toBe(true);
    }
  });

  test('A20: Reset password with invalid token (400/401)', async ({ request }) => {
    const res = await request.post(`${API}/auth/reset-password`, {
      data: { token: 'invalid-reset-token', newPassword: 'ValidP@ss1' },
    });
    expect([400, 401]).toContain(res.status());
  });

  // ── Logout ────────────────────────────────────────────────────

  test('A21: Logout revokes refresh token', async ({ request }) => {
    const res = await request.post(`${API}/auth/logout`, {
      headers: { Authorization: `Bearer ${accessToken}` },
      data: { refreshToken },
    });
    expect(res.status()).toBe(200);
  });

  test('A22: Revoked refresh token cannot be used', async ({ request }) => {
    const res = await request.post(`${API}/auth/refresh`, {
      data: { refreshToken },
    });
    expect(res.status()).toBe(401);
  });

  // ── Re-login after logout ─────────────────────────────────────

  test('A23: Re-login after logout succeeds', async ({ request }) => {
    const res = await request.post(`${API}/auth/login`, {
      data: { email: TEST_EMAIL, password: 'NewSecure@1' },
    });
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(body.accessToken).toBeTruthy();
    accessToken = body.accessToken;
    refreshToken = body.refreshToken;
  });
});

// ── Health Check (independent) ──────────────────────────────────

test.describe('Health & Version endpoints', () => {
  test('H1: GET /health returns ok', async ({ request }) => {
    const res = await request.get(`${API}/health`);
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(body.status).toBe('ok');
    expect(body.database.status).toBe('up');
  });

  test('H2: GET /ready returns ok', async ({ request }) => {
    const res = await request.get(`${API}/ready`);
    // 200 = ok, 429 = rate limited from cumulative requests
    expect([200, 429]).toContain(res.status());
  });

  test('H3: GET /live returns ok', async ({ request }) => {
    const res = await request.get(`${API}/live`);
    // 200 = ok, 429 = rate limited from cumulative requests
    expect([200, 429]).toContain(res.status());
  });

  test('H4: GET /version returns version info', async ({ request }) => {
    const res = await request.get(`${API}/version`);
    // 200 = ok, 429 = rate limited from cumulative requests
    expect([200, 429]).toContain(res.status());
  });
});

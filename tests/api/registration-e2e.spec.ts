import { test, expect } from '@playwright/test';

const API_BASE = 'http://localhost:3000/api/v1';

test.describe('API E2E: Full Registration + Login + Auth Flow', () => {
  const timestamp = Date.now();
  const TEST_EMAIL = `e2e-full-flow-${timestamp}@test.local`;
  const TEST_PASSWORD = 'Test1234!';
  const TEST_FIRST_NAME = 'E2E';
  const TEST_LAST_NAME = 'FullFlow';

  let accessToken: string;
  let refreshToken: string;
  let userId: string;

  test('Step 1: Register new user via API', async ({ request }) => {
    const response = await request.post(`${API_BASE}/auth/register`, {
      data: {
        email: TEST_EMAIL,
        password: TEST_PASSWORD,
        firstName: TEST_FIRST_NAME,
        lastName: TEST_LAST_NAME,
      },
    });

    expect(response.status()).toBe(201);
    const body = await response.json();
    expect(body.email).toBe(TEST_EMAIL);
    expect(body.role).toBe('SURVEYOR');
    expect(body.id).toBeTruthy();
    userId = body.id;
    console.log(`Registered user: ${userId} (${TEST_EMAIL})`);
  });

  test('Step 2: Reject duplicate registration', async ({ request }) => {
    const response = await request.post(`${API_BASE}/auth/register`, {
      data: {
        email: TEST_EMAIL,
        password: TEST_PASSWORD,
        firstName: TEST_FIRST_NAME,
        lastName: TEST_LAST_NAME,
      },
    });

    expect(response.status()).toBe(409);
    const body = await response.json();
    expect(body.message).toContain('already');
    console.log('Duplicate registration correctly rejected with 409');
  });

  test('Step 3: Reject registration with weak password', async ({ request }) => {
    const response = await request.post(`${API_BASE}/auth/register`, {
      data: {
        email: `weak-pw-${timestamp}@test.local`,
        password: 'short',
        firstName: 'Weak',
        lastName: 'Password',
      },
    });

    expect(response.status()).toBe(400);
    console.log('Weak password correctly rejected with 400');
  });

  test('Step 4: Login with registered credentials', async ({ request }) => {
    const response = await request.post(`${API_BASE}/auth/login`, {
      data: {
        email: TEST_EMAIL,
        password: TEST_PASSWORD,
      },
    });

    expect(response.status()).toBe(200);
    const body = await response.json();
    expect(body.accessToken).toBeTruthy();
    expect(body.refreshToken).toBeTruthy();
    expect(body.user.email).toBe(TEST_EMAIL);
    expect(body.user.firstName).toBe(TEST_FIRST_NAME);
    expect(body.user.lastName).toBe(TEST_LAST_NAME);
    expect(body.expiresIn).toBeTruthy();

    accessToken = body.accessToken;
    refreshToken = body.refreshToken;
    console.log(`Login successful, got access token (expires in ${body.expiresIn}s)`);
  });

  test('Step 5: Reject login with wrong password', async ({ request }) => {
    const response = await request.post(`${API_BASE}/auth/login`, {
      data: {
        email: TEST_EMAIL,
        password: 'WrongPassword1!',
      },
    });

    expect(response.status()).toBe(401);
    console.log('Wrong password correctly rejected with 401');
  });

  test('Step 6: Access protected /auth/me endpoint', async ({ request }) => {
    const response = await request.get(`${API_BASE}/auth/me`, {
      headers: {
        Authorization: `Bearer ${accessToken}`,
      },
    });

    expect(response.status()).toBe(200);
    const body = await response.json();
    expect(body.email).toBe(TEST_EMAIL);
    expect(body.firstName).toBe(TEST_FIRST_NAME);
    expect(body.lastName).toBe(TEST_LAST_NAME);
    expect(body.role).toBe('SURVEYOR');
    console.log(`Authenticated access to /auth/me successful for ${body.email}`);
  });

  test('Step 7: Reject unauthenticated access to /auth/me', async ({ request }) => {
    const response = await request.get(`${API_BASE}/auth/me`);
    expect(response.status()).toBe(401);
    console.log('Unauthenticated access correctly rejected with 401');
  });

  test('Step 8: Refresh access token', async ({ request }) => {
    const response = await request.post(`${API_BASE}/auth/refresh`, {
      data: {
        refreshToken: refreshToken,
      },
    });

    expect(response.status()).toBe(200);
    const body = await response.json();
    expect(body.accessToken).toBeTruthy();
    expect(body.refreshToken).toBeTruthy();
    // Token should have rotated
    expect(body.refreshToken).not.toBe(refreshToken);
    console.log('Token refresh successful, tokens rotated');

    accessToken = body.accessToken;
    refreshToken = body.refreshToken;
  });

  test('Step 9: Forgot password (always returns success)', async ({ request }) => {
    const response = await request.post(`${API_BASE}/auth/forgot-password`, {
      data: {
        email: TEST_EMAIL,
      },
    });

    expect(response.status()).toBe(200);
    const body = await response.json();
    expect(body.success).toBe(true);
    console.log('Forgot password returns success (email enumeration prevention)');
  });

  test('Step 10: Forgot password with non-existent email (still returns success)', async ({ request }) => {
    const response = await request.post(`${API_BASE}/auth/forgot-password`, {
      data: {
        email: 'nonexistent@test.local',
      },
    });

    expect(response.status()).toBe(200);
    const body = await response.json();
    expect(body.success).toBe(true);
    console.log('Forgot password for unknown email correctly returns success (security)');
  });

  test('Step 11: Logout with current refresh token', async ({ request }) => {
    // Re-login to get a fresh token pair for logout test
    const loginResponse = await request.post(`${API_BASE}/auth/login`, {
      data: {
        email: TEST_EMAIL,
        password: TEST_PASSWORD,
      },
    });
    expect(loginResponse.status()).toBe(200);
    const loginBody = await loginResponse.json();
    const freshAccessToken = loginBody.accessToken;
    const freshRefreshToken = loginBody.refreshToken;

    const response = await request.post(`${API_BASE}/auth/logout`, {
      data: {
        refreshToken: freshRefreshToken,
      },
      headers: {
        Authorization: `Bearer ${freshAccessToken}`,
      },
    });

    expect(response.status()).toBe(200);
    console.log('Logout successful');
  });
});

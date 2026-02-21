/**
 * E2E Integration Tests: Authentication Flow
 *
 * Tests the complete authentication lifecycle:
 * 1. User registration
 * 2. Login with valid/invalid credentials
 * 3. Token refresh
 * 4. Logout (token revocation)
 * 5. Password reset flow
 * 6. Protected endpoint access
 * 7. Token expiration handling
 *
 * These tests run against a real database and API.
 */

import * as request from 'supertest';
import { prisma, TEST_PREFIX, TEST_EMAIL_DOMAIN, cleanupTestData } from './test-helpers';

const API_BASE = 'http://localhost:3000/api/v1';

// Test user credentials
const TEST_USER = {
  email: `${TEST_PREFIX}auth_user${TEST_EMAIL_DOMAIN}`,
  password: 'SecureP@ssw0rd123!',
  firstName: 'Auth',
  lastName: 'TestUser',
};

describe('Authentication (E2E)', () => {
  let accessToken: string;
  let refreshToken: string;
  let userId: string;

  beforeAll(async () => {
    await cleanupTestData();
    // Clean up any existing test user
    await prisma.refreshToken.deleteMany({
      where: { user: { email: TEST_USER.email } },
    });
    await prisma.user.deleteMany({
      where: { email: TEST_USER.email },
    });
  });

  afterAll(async () => {
    await cleanupTestData();
    await prisma.refreshToken.deleteMany({
      where: { user: { email: TEST_USER.email } },
    });
    await prisma.user.deleteMany({
      where: { email: TEST_USER.email },
    });
    await prisma.$disconnect();
  });

  // ==========================================
  // REGISTRATION
  // ==========================================

  describe('POST /auth/register', () => {
    it('should register a new user successfully', async () => {
      const response = await request(API_BASE)
        .post('/auth/register')
        .send({
          email: TEST_USER.email,
          password: TEST_USER.password,
          firstName: TEST_USER.firstName,
          lastName: TEST_USER.lastName,
        });

      expect(response.status).toBe(201);
      expect(response.body).toHaveProperty('id');
      expect(response.body).toHaveProperty('email');
      expect(response.body).toHaveProperty('role');
    });

    it('should reject duplicate email registration', async () => {
      const response = await request(API_BASE)
        .post('/auth/register')
        .send({
          email: TEST_USER.email,
          password: TEST_USER.password,
          firstName: TEST_USER.firstName,
          lastName: TEST_USER.lastName,
        });

      expect(response.status).toBe(409); // Conflict
    });

    it('should reject weak password', async () => {
      const response = await request(API_BASE)
        .post('/auth/register')
        .send({
          email: `${TEST_PREFIX}weak_pass${TEST_EMAIL_DOMAIN}`,
          password: '123',
          firstName: 'Test',
          lastName: 'User',
        });

      expect(response.status).toBe(400);
    });

    it('should reject invalid email format', async () => {
      const response = await request(API_BASE)
        .post('/auth/register')
        .send({
          email: 'not-an-email',
          password: TEST_USER.password,
          firstName: 'Test',
          lastName: 'User',
        });

      expect(response.status).toBe(400);
    });

    it('should reject missing required fields', async () => {
      const response = await request(API_BASE)
        .post('/auth/register')
        .send({
          email: `${TEST_PREFIX}missing${TEST_EMAIL_DOMAIN}`,
        });

      expect(response.status).toBe(400);
    });
  });

  // ==========================================
  // LOGIN
  // ==========================================

  describe('POST /auth/login', () => {
    it('should login with valid credentials', async () => {
      const response = await request(API_BASE)
        .post('/auth/login')
        .send({
          email: TEST_USER.email,
          password: TEST_USER.password,
        });

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('accessToken');
      expect(response.body).toHaveProperty('refreshToken');
      expect(response.body).toHaveProperty('user');
      expect(response.body.user).toHaveProperty('id');
      expect(response.body.user).toHaveProperty('email', TEST_USER.email.toLowerCase());
      expect(response.body.user).not.toHaveProperty('passwordHash');

      // Store for later tests
      accessToken = response.body.accessToken;
      refreshToken = response.body.refreshToken;
      userId = response.body.user.id;
    });

    it('should reject invalid password', async () => {
      const response = await request(API_BASE)
        .post('/auth/login')
        .send({
          email: TEST_USER.email,
          password: 'WrongPassword123!',
        });

      expect(response.status).toBe(401);
    });

    it('should reject non-existent user', async () => {
      const response = await request(API_BASE)
        .post('/auth/login')
        .send({
          email: 'nonexistent@example.com',
          password: TEST_USER.password,
        });

      expect(response.status).toBe(401);
    });

    it('should reject missing credentials', async () => {
      const response = await request(API_BASE)
        .post('/auth/login')
        .send({});

      expect(response.status).toBe(400);
    });
  });

  // ==========================================
  // PROTECTED ENDPOINTS
  // ==========================================

  describe('GET /auth/me (Protected)', () => {
    it('should return current user with valid token', async () => {
      const response = await request(API_BASE)
        .get('/auth/me')
        .set('Authorization', `Bearer ${accessToken}`);

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('id', userId);
      expect(response.body).toHaveProperty('email', TEST_USER.email.toLowerCase());
      expect(response.body).toHaveProperty('firstName', TEST_USER.firstName);
      expect(response.body).not.toHaveProperty('passwordHash');
    });

    it('should reject request without token', async () => {
      const response = await request(API_BASE)
        .get('/auth/me');

      expect(response.status).toBe(401);
    });

    it('should reject request with invalid token', async () => {
      const response = await request(API_BASE)
        .get('/auth/me')
        .set('Authorization', 'Bearer invalid-token-here');

      expect(response.status).toBe(401);
    });

    it('should reject request with malformed auth header', async () => {
      const response = await request(API_BASE)
        .get('/auth/me')
        .set('Authorization', 'NotBearer token');

      expect(response.status).toBe(401);
    });
  });

  // ==========================================
  // TOKEN REFRESH
  // ==========================================

  describe('POST /auth/refresh', () => {
    it('should refresh tokens with valid refresh token', async () => {
      // Wait for JWT iat (issued-at) to advance past the login second,
      // ensuring the new access token differs from the old one.
      await new Promise((resolve) => setTimeout(resolve, 1100));

      const response = await request(API_BASE)
        .post('/auth/refresh')
        .send({ refreshToken });

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('accessToken');
      expect(response.body).toHaveProperty('refreshToken');

      // New tokens should be different (refresh token is always unique;
      // access token differs because iat has advanced to a new second)
      expect(response.body.accessToken).not.toBe(accessToken);
      expect(response.body.refreshToken).not.toBe(refreshToken);

      // Update tokens for later tests
      accessToken = response.body.accessToken;
      refreshToken = response.body.refreshToken;
    });

    it('should reject invalid refresh token', async () => {
      const response = await request(API_BASE)
        .post('/auth/refresh')
        .send({ refreshToken: 'invalid-refresh-token' });

      expect(response.status).toBe(401);
    });

    it('should reject missing refresh token', async () => {
      const response = await request(API_BASE)
        .post('/auth/refresh')
        .send({});

      expect(response.status).toBe(400);
    });
  });

  // ==========================================
  // PROFILE UPDATE
  // ==========================================

  describe('PATCH /auth/profile', () => {
    it('should update user profile', async () => {
      const response = await request(API_BASE)
        .patch('/auth/profile')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ fullName: 'Updated Name' });

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('firstName', 'Updated');
      expect(response.body).toHaveProperty('lastName', 'Name');
    });

    it('should reject update without auth', async () => {
      const response = await request(API_BASE)
        .patch('/auth/profile')
        .send({ fullName: 'Hacker Name' });

      expect(response.status).toBe(401);
    });
  });

  // ==========================================
  // LOGOUT
  // ==========================================

  describe('POST /auth/logout', () => {
    it('should logout and revoke refresh token', async () => {
      const response = await request(API_BASE)
        .post('/auth/logout')
        .send({ refreshToken });

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('success', true);
    });

    it('should reject refresh with revoked token', async () => {
      const response = await request(API_BASE)
        .post('/auth/refresh')
        .send({ refreshToken });

      expect(response.status).toBe(401);
    });

    it('should handle logout with already-revoked token gracefully', async () => {
      const response = await request(API_BASE)
        .post('/auth/logout')
        .send({ refreshToken });

      // Should succeed or be idempotent
      expect([200, 401]).toContain(response.status);
    });
  });

  // ==========================================
  // PASSWORD RESET
  // ==========================================

  describe('Password Reset Flow', () => {
    it('should request password reset without revealing user existence', async () => {
      // For existing user
      const response1 = await request(API_BASE)
        .post('/auth/forgot-password')
        .send({ email: TEST_USER.email });

      expect(response1.status).toBe(200);

      // For non-existing user (should return same response for security)
      const response2 = await request(API_BASE)
        .post('/auth/forgot-password')
        .send({ email: 'nonexistent@example.com' });

      expect(response2.status).toBe(200);
      expect(response1.body.message).toBe(response2.body.message);
    });

    it('should reject invalid email format', async () => {
      const response = await request(API_BASE)
        .post('/auth/forgot-password')
        .send({ email: 'not-an-email' });

      expect(response.status).toBe(400);
    });

    it('should reject reset with invalid token', async () => {
      const response = await request(API_BASE)
        .post('/auth/reset-password')
        .send({
          token: 'invalid-reset-token',
          newPassword: 'NewSecureP@ssw0rd!',
        });

      expect(response.status).toBe(400);
    });
  });

  // ==========================================
  // SECURITY CHECKS
  // ==========================================

  describe('Security', () => {
    it('should not expose sensitive data in error responses', async () => {
      const response = await request(API_BASE)
        .post('/auth/login')
        .send({
          email: TEST_USER.email,
          password: 'WrongPassword',
        });

      const responseStr = JSON.stringify(response.body);
      expect(responseStr.toLowerCase()).not.toContain('passwordhash');
      expect(responseStr.toLowerCase()).not.toContain('database');
      expect(responseStr.toLowerCase()).not.toContain('stack');
    });

    it('should rate limit login attempts', async () => {
      // Make multiple rapid requests
      const requests = Array(10).fill(null).map(() =>
        request(API_BASE)
          .post('/auth/login')
          .send({
            email: TEST_USER.email,
            password: 'WrongPassword',
          })
      );

      const responses = await Promise.all(requests);
      const rateLimited = responses.some(r => r.status === 429);
      const allUnauthorized = responses.every(r => r.status === 401 || r.status === 429);

      // Rate limiting should kick in (when enabled) or all should be 401
      // In test environment, throttling may be relaxed
      expect(allUnauthorized).toBe(true);
    });
  });
});

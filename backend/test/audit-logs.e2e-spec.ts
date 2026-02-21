/**
 * E2E Integration Tests: Audit Logs
 *
 * Tests:
 * 1. Admin can query audit logs
 * 2. Pagination works correctly
 * 3. Filters work (actorType, entityType, action, date range)
 * 4. Non-admin roles are forbidden
 * 5. No sensitive data is leaked
 */

import * as request from 'supertest';
import {
  createTestFixtures,
  cleanupTestData,
  prisma,
  TEST_PREFIX,
} from './test-helpers';
import { ActorType, AuditEntityType } from '@prisma/client';

const API_BASE = 'http://localhost:3000/api/v1';

describe('Audit Logs (E2E)', () => {
  let fixtures: Awaited<ReturnType<typeof createTestFixtures>>;
  let testAuditLogId: string;

  beforeAll(async () => {
    await cleanupTestData();
    fixtures = await createTestFixtures();

    // Create some test audit logs for querying
    const auditLog = await prisma.auditLog.create({
      data: {
        actorType: ActorType.STAFF,
        actorId: fixtures.adminUser.id,
        action: `${TEST_PREFIX}test_action`,
        entityType: AuditEntityType.AUTH,
        entityId: fixtures.adminUser.id,
        metadata: { test: true, message: 'E2E test audit log' },
      },
    });
    testAuditLogId = auditLog.id;

    // Create more logs for pagination testing
    for (let i = 0; i < 5; i++) {
      await prisma.auditLog.create({
        data: {
          actorType: ActorType.CLIENT,
          actorId: fixtures.client.id,
          action: `${TEST_PREFIX}client_action_${i}`,
          entityType: AuditEntityType.BOOKING,
          entityId: fixtures.booking.id,
          metadata: { index: i },
        },
      });
    }
  });

  afterAll(async () => {
    await cleanupTestData();
    await prisma.$disconnect();
  });

  // ==========================================
  // ADMIN ACCESS
  // ==========================================

  describe('Admin: Query Audit Logs', () => {
    it('should return paginated audit logs', async () => {
      const response = await request(API_BASE)
        .get('/audit-logs')
        .set('Authorization', `Bearer ${fixtures.tokens.admin}`)
        .query({ page: 1, limit: 10 });

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('logs');
      expect(response.body).toHaveProperty('page', 1);
      expect(response.body).toHaveProperty('limit', 10);
      expect(response.body).toHaveProperty('total');
      expect(response.body).toHaveProperty('totalPages');
      expect(Array.isArray(response.body.logs)).toBe(true);
    });

    it('should filter by actorType', async () => {
      const response = await request(API_BASE)
        .get('/audit-logs')
        .set('Authorization', `Bearer ${fixtures.tokens.admin}`)
        .query({ actorType: ActorType.CLIENT });

      expect(response.status).toBe(200);
      expect(response.body.logs.every((log: any) => log.actorType === ActorType.CLIENT)).toBe(true);
    });

    it('should filter by actorId', async () => {
      const response = await request(API_BASE)
        .get('/audit-logs')
        .set('Authorization', `Bearer ${fixtures.tokens.admin}`)
        .query({ actorId: fixtures.adminUser.id });

      expect(response.status).toBe(200);
      expect(response.body.logs.every((log: any) => log.actorId === fixtures.adminUser.id)).toBe(true);
    });

    it('should filter by entityType', async () => {
      const response = await request(API_BASE)
        .get('/audit-logs')
        .set('Authorization', `Bearer ${fixtures.tokens.admin}`)
        .query({ entityType: AuditEntityType.BOOKING });

      expect(response.status).toBe(200);
      expect(response.body.logs.every((log: any) => log.entityType === AuditEntityType.BOOKING)).toBe(true);
    });

    it('should filter by action (partial match)', async () => {
      const response = await request(API_BASE)
        .get('/audit-logs')
        .set('Authorization', `Bearer ${fixtures.tokens.admin}`)
        .query({ action: TEST_PREFIX });

      expect(response.status).toBe(200);
      expect(response.body.logs.length).toBeGreaterThan(0);
      expect(response.body.logs.every((log: any) => log.action.includes(TEST_PREFIX))).toBe(true);
    });

    it('should filter by date range', async () => {
      const now = new Date();
      const startDate = new Date(now.getTime() - 60 * 60 * 1000).toISOString(); // 1 hour ago
      const endDate = new Date(now.getTime() + 60 * 60 * 1000).toISOString(); // 1 hour from now

      const response = await request(API_BASE)
        .get('/audit-logs')
        .set('Authorization', `Bearer ${fixtures.tokens.admin}`)
        .query({ startDate, endDate });

      expect(response.status).toBe(200);
      // All logs should be within the date range
      response.body.logs.forEach((log: any) => {
        const logDate = new Date(log.createdAt);
        expect(logDate >= new Date(startDate)).toBe(true);
        expect(logDate <= new Date(endDate)).toBe(true);
      });
    });

    it('should respect pagination limit', async () => {
      const response = await request(API_BASE)
        .get('/audit-logs')
        .set('Authorization', `Bearer ${fixtures.tokens.admin}`)
        .query({ page: 1, limit: 2 });

      expect(response.status).toBe(200);
      expect(response.body.logs.length).toBeLessThanOrEqual(2);
      expect(response.body.limit).toBe(2);
    });

    it('should return logs sorted by createdAt desc', async () => {
      const response = await request(API_BASE)
        .get('/audit-logs')
        .set('Authorization', `Bearer ${fixtures.tokens.admin}`)
        .query({ limit: 10 });

      expect(response.status).toBe(200);
      const dates = response.body.logs.map((log: any) => new Date(log.createdAt).getTime());
      for (let i = 0; i < dates.length - 1; i++) {
        expect(dates[i]).toBeGreaterThanOrEqual(dates[i + 1]);
      }
    });

    it('should include expected fields in response', async () => {
      const response = await request(API_BASE)
        .get('/audit-logs')
        .set('Authorization', `Bearer ${fixtures.tokens.admin}`)
        .query({ limit: 1 });

      expect(response.status).toBe(200);
      if (response.body.logs.length > 0) {
        const log = response.body.logs[0];
        expect(log).toHaveProperty('id');
        expect(log).toHaveProperty('actorType');
        expect(log).toHaveProperty('action');
        expect(log).toHaveProperty('entityType');
        expect(log).toHaveProperty('createdAt');
      }
    });
  });

  // ==========================================
  // RBAC ENFORCEMENT
  // ==========================================

  describe('RBAC: Non-Admin Access', () => {
    it('should reject MANAGER role', async () => {
      const response = await request(API_BASE)
        .get('/audit-logs')
        .set('Authorization', `Bearer ${fixtures.tokens.manager}`);

      expect(response.status).toBe(403);
    });

    it('should reject SURVEYOR role', async () => {
      const response = await request(API_BASE)
        .get('/audit-logs')
        .set('Authorization', `Bearer ${fixtures.tokens.surveyor}`);

      expect(response.status).toBe(403);
    });

    it('should reject client token', async () => {
      const response = await request(API_BASE)
        .get('/audit-logs')
        .set('Authorization', `Bearer ${fixtures.tokens.client}`);

      expect(response.status).toBe(401);
    });

    it('should reject request without auth', async () => {
      const response = await request(API_BASE)
        .get('/audit-logs');

      expect(response.status).toBe(401);
    });
  });

  // ==========================================
  // SECURITY
  // ==========================================

  describe('Security: No Sensitive Data Leaks', () => {
    it('should not expose password hashes or tokens in metadata', async () => {
      const response = await request(API_BASE)
        .get('/audit-logs')
        .set('Authorization', `Bearer ${fixtures.tokens.admin}`)
        .query({ limit: 50 });

      expect(response.status).toBe(200);

      const responseStr = JSON.stringify(response.body);
      expect(responseStr.toLowerCase()).not.toContain('passwordhash');
      expect(responseStr.toLowerCase()).not.toContain('refreshtoken');
      expect(responseStr.toLowerCase()).not.toContain('accesstoken');
      expect(responseStr.toLowerCase()).not.toContain('secret');
    });
  });

  // ==========================================
  // INPUT VALIDATION
  // ==========================================

  describe('Input Validation', () => {
    it('should reject invalid actorType', async () => {
      const response = await request(API_BASE)
        .get('/audit-logs')
        .set('Authorization', `Bearer ${fixtures.tokens.admin}`)
        .query({ actorType: 'INVALID_TYPE' });

      expect(response.status).toBe(400);
    });

    it('should reject invalid entityType', async () => {
      const response = await request(API_BASE)
        .get('/audit-logs')
        .set('Authorization', `Bearer ${fixtures.tokens.admin}`)
        .query({ entityType: 'INVALID_TYPE' });

      expect(response.status).toBe(400);
    });

    it('should reject invalid UUID for actorId', async () => {
      const response = await request(API_BASE)
        .get('/audit-logs')
        .set('Authorization', `Bearer ${fixtures.tokens.admin}`)
        .query({ actorId: 'not-a-uuid' });

      expect(response.status).toBe(400);
    });

    it('should reject invalid date format', async () => {
      const response = await request(API_BASE)
        .get('/audit-logs')
        .set('Authorization', `Bearer ${fixtures.tokens.admin}`)
        .query({ startDate: 'invalid-date' });

      expect(response.status).toBe(400);
    });

    it('should cap limit at 100', async () => {
      const response = await request(API_BASE)
        .get('/audit-logs')
        .set('Authorization', `Bearer ${fixtures.tokens.admin}`)
        .query({ limit: 500 });

      // Should either return error or cap at 100
      if (response.status === 200) {
        expect(response.body.limit).toBeLessThanOrEqual(100);
      } else {
        expect(response.status).toBe(400);
      }
    });
  });
});

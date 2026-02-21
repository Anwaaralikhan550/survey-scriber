/**
 * E2E Integration Tests: Booking Change Requests
 *
 * Tests the complete workflow:
 * 1. Client creates a change request (reschedule/cancel)
 * 2. Client lists their change requests
 * 3. Client views a specific change request
 * 4. Staff lists all change requests
 * 5. Staff approves/rejects a change request
 * 6. Booking gets updated accordingly
 * 7. Audit logs are created
 * 8. RBAC enforcement
 */

import * as request from 'supertest';
import {
  createTestFixtures,
  cleanupTestData,
  prisma,
  TEST_PREFIX,
} from './test-helpers';
import { BookingChangeRequestStatus, BookingChangeRequestType, BookingStatus } from '@prisma/client';

const API_BASE = 'http://localhost:3000/api/v1';

describe('Booking Change Requests (E2E)', () => {
  let fixtures: Awaited<ReturnType<typeof createTestFixtures>>;
  let createdChangeRequestId: string;

  beforeAll(async () => {
    // Clean up any leftover test data
    await cleanupTestData();
    // Create fresh test fixtures
    fixtures = await createTestFixtures();
  });

  afterAll(async () => {
    // Clean up test data
    await cleanupTestData();
    await prisma.$disconnect();
  });

  // ==========================================
  // CLIENT ENDPOINTS
  // ==========================================

  describe('Client: Create Change Request', () => {
    it('should create a RESCHEDULE change request', async () => {
      const futureDate = new Date();
      futureDate.setDate(futureDate.getDate() + 21); // 3 weeks from now
      const proposedDate = futureDate.toISOString().split('T')[0];

      const response = await request(API_BASE)
        .post('/client/booking-changes')
        .set('Authorization', `Bearer ${fixtures.tokens.client}`)
        .send({
          bookingId: fixtures.booking.id,
          type: BookingChangeRequestType.RESCHEDULE,
          proposedDate,
          proposedStartTime: '14:00',
          proposedEndTime: '16:00',
          reason: `${TEST_PREFIX} Need to reschedule due to conflict`,
        });

      expect(response.status).toBe(201);
      expect(response.body).toHaveProperty('id');
      expect(response.body.type).toBe(BookingChangeRequestType.RESCHEDULE);
      expect(response.body.status).toBe(BookingChangeRequestStatus.REQUESTED);
      expect(response.body.clientId).toBe(fixtures.client.id);
      expect(response.body.bookingId).toBe(fixtures.booking.id);

      createdChangeRequestId = response.body.id;
    });

    it('should reject request without auth', async () => {
      const response = await request(API_BASE)
        .post('/client/booking-changes')
        .send({
          bookingId: fixtures.booking.id,
          type: BookingChangeRequestType.CANCEL,
          reason: 'Test',
        });

      expect(response.status).toBe(401);
    });

    it('should reject duplicate pending request for same booking', async () => {
      const futureDate = new Date();
      futureDate.setDate(futureDate.getDate() + 21);

      const response = await request(API_BASE)
        .post('/client/booking-changes')
        .set('Authorization', `Bearer ${fixtures.tokens.client}`)
        .send({
          bookingId: fixtures.booking.id,
          type: BookingChangeRequestType.CANCEL,
          reason: 'Test duplicate',
        });

      expect(response.status).toBe(400);
      expect(response.body.message).toContain('already a pending');
    });

    it('should reject staff token on client endpoint (RBAC)', async () => {
      const response = await request(API_BASE)
        .post('/client/booking-changes')
        .set('Authorization', `Bearer ${fixtures.tokens.admin}`)
        .send({
          bookingId: fixtures.booking.id,
          type: BookingChangeRequestType.CANCEL,
          reason: 'Test',
        });

      expect(response.status).toBe(401);
    });
  });

  describe('Client: List Change Requests', () => {
    it('should list client change requests with pagination', async () => {
      const response = await request(API_BASE)
        .get('/client/booking-changes')
        .set('Authorization', `Bearer ${fixtures.tokens.client}`)
        .query({ page: 1, limit: 10 });

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('data');
      expect(response.body).toHaveProperty('pagination');
      expect(Array.isArray(response.body.data)).toBe(true);
      expect(response.body.data.length).toBeGreaterThanOrEqual(1);
      expect(response.body.pagination).toHaveProperty('page', 1);
      expect(response.body.pagination).toHaveProperty('total');
    });

    it('should filter by status', async () => {
      const response = await request(API_BASE)
        .get('/client/booking-changes')
        .set('Authorization', `Bearer ${fixtures.tokens.client}`)
        .query({ status: BookingChangeRequestStatus.REQUESTED });

      expect(response.status).toBe(200);
      expect(response.body.data.every((r: any) => r.status === BookingChangeRequestStatus.REQUESTED)).toBe(true);
    });
  });

  describe('Client: Get Specific Change Request', () => {
    it('should get change request by ID', async () => {
      const response = await request(API_BASE)
        .get(`/client/booking-changes/${createdChangeRequestId}`)
        .set('Authorization', `Bearer ${fixtures.tokens.client}`);

      expect(response.status).toBe(200);
      expect(response.body.id).toBe(createdChangeRequestId);
      expect(response.body).toHaveProperty('booking');
      expect(response.body.booking.id).toBe(fixtures.booking.id);
    });

    it('should return 404 for non-existent request', async () => {
      const fakeId = '00000000-0000-0000-0000-000000000000';
      const response = await request(API_BASE)
        .get(`/client/booking-changes/${fakeId}`)
        .set('Authorization', `Bearer ${fixtures.tokens.client}`);

      expect(response.status).toBe(404);
    });
  });

  // ==========================================
  // STAFF ENDPOINTS
  // ==========================================

  describe('Staff: List Change Requests', () => {
    it('should list all change requests (ADMIN)', async () => {
      const response = await request(API_BASE)
        .get('/booking-changes')
        .set('Authorization', `Bearer ${fixtures.tokens.admin}`)
        .query({ page: 1, limit: 20 });

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('data');
      expect(response.body).toHaveProperty('pagination');
      expect(Array.isArray(response.body.data)).toBe(true);
    });

    it('should list all change requests (MANAGER)', async () => {
      const response = await request(API_BASE)
        .get('/booking-changes')
        .set('Authorization', `Bearer ${fixtures.tokens.manager}`)
        .query({ page: 1, limit: 20 });

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('data');
    });

    it('should reject SURVEYOR role (RBAC)', async () => {
      const response = await request(API_BASE)
        .get('/booking-changes')
        .set('Authorization', `Bearer ${fixtures.tokens.surveyor}`);

      expect(response.status).toBe(403);
    });

    it('should reject client token on staff endpoint (RBAC)', async () => {
      const response = await request(API_BASE)
        .get('/booking-changes')
        .set('Authorization', `Bearer ${fixtures.tokens.client}`);

      expect(response.status).toBe(401);
    });

    it('should filter by clientId', async () => {
      const response = await request(API_BASE)
        .get('/booking-changes')
        .set('Authorization', `Bearer ${fixtures.tokens.admin}`)
        .query({ clientId: fixtures.client.id });

      expect(response.status).toBe(200);
      expect(response.body.data.every((r: any) => r.clientId === fixtures.client.id)).toBe(true);
    });
  });

  describe('Staff: Get Specific Change Request', () => {
    it('should get change request details (ADMIN)', async () => {
      const response = await request(API_BASE)
        .get(`/booking-changes/${createdChangeRequestId}`)
        .set('Authorization', `Bearer ${fixtures.tokens.admin}`);

      expect(response.status).toBe(200);
      expect(response.body.id).toBe(createdChangeRequestId);
      expect(response.body).toHaveProperty('client');
      expect(response.body.client.id).toBe(fixtures.client.id);
    });
  });

  describe('Staff: Approve Change Request', () => {
    it('should approve a RESCHEDULE request and update booking', async () => {
      const response = await request(API_BASE)
        .patch(`/booking-changes/${createdChangeRequestId}/approve`)
        .set('Authorization', `Bearer ${fixtures.tokens.admin}`)
        .send({});

      expect(response.status).toBe(200);
      expect(response.body.status).toBe(BookingChangeRequestStatus.APPROVED);
      expect(response.body.reviewedById).toBe(fixtures.adminUser.id);
      expect(response.body.reviewedAt).toBeDefined();

      // Verify booking was updated
      const booking = await prisma.booking.findUnique({
        where: { id: fixtures.booking.id },
      });
      expect(booking).not.toBeNull();
      expect(booking!.startTime).toBe('14:00');
      expect(booking!.endTime).toBe('16:00');
    });

    it('should reject already-approved request', async () => {
      const response = await request(API_BASE)
        .patch(`/booking-changes/${createdChangeRequestId}/approve`)
        .set('Authorization', `Bearer ${fixtures.tokens.admin}`)
        .send({});

      expect(response.status).toBe(400);
      expect(response.body.message).toContain('Cannot approve');
    });
  });

  describe('Staff: Reject Change Request', () => {
    let cancelRequestId: string;

    beforeAll(async () => {
      // Create another booking for cancel test
      const futureDate = new Date();
      futureDate.setDate(futureDate.getDate() + 28);

      const newBooking = await prisma.booking.create({
        data: {
          surveyorId: fixtures.surveyorUser.id,
          createdById: fixtures.adminUser.id,
          clientId: fixtures.client.id,
          date: futureDate,
          startTime: '09:00',
          endTime: '11:00',
          clientEmail: fixtures.client.email,
          propertyAddress: `${TEST_PREFIX} 456 Another Street`,
          status: BookingStatus.CONFIRMED,
        },
      });

      // Create a cancel request
      const cancelRequest = await prisma.bookingChangeRequest.create({
        data: {
          bookingId: newBooking.id,
          clientId: fixtures.client.id,
          type: BookingChangeRequestType.CANCEL,
          reason: `${TEST_PREFIX} Want to cancel`,
          status: BookingChangeRequestStatus.REQUESTED,
        },
      });

      cancelRequestId = cancelRequest.id;
    });

    it('should reject a change request with reason', async () => {
      const response = await request(API_BASE)
        .patch(`/booking-changes/${cancelRequestId}/reject`)
        .set('Authorization', `Bearer ${fixtures.tokens.manager}`)
        .send({ reason: 'Cannot cancel within 48 hours of appointment' });

      expect(response.status).toBe(200);
      expect(response.body.status).toBe(BookingChangeRequestStatus.REJECTED);
      expect(response.body.reviewedById).toBe(fixtures.managerUser.id);
      expect(response.body.reason).toContain('Cannot cancel');
    });
  });

  // ==========================================
  // AUDIT LOG VERIFICATION
  // ==========================================

  describe('Audit Log Integration', () => {
    it('should have created audit logs for change request actions', async () => {
      const auditLogs = await prisma.auditLog.findMany({
        where: {
          entityId: createdChangeRequestId,
        },
        orderBy: { createdAt: 'asc' },
      });

      expect(auditLogs.length).toBeGreaterThanOrEqual(2);

      // Should have CREATED and APPROVED
      const actions = auditLogs.map(l => l.action);
      expect(actions).toContain('change_request.created');
      expect(actions).toContain('change_request.approved');
    });
  });
});

/**
 * E2E Integration Tests: Sync + PDF Upload Flow
 *
 * Tests the complete offline-to-online sync lifecycle:
 * 1. Create survey via individual CRUD endpoint
 * 2. Create sections under the survey
 * 3. Create answers under the sections
 * 4. Upload report PDF to the synced survey
 * 5. Verify ordering constraints (survey must exist before sections, etc.)
 * 6. Verify 429 rate-limit responses include Retry-After
 * 7. Verify AI status endpoint
 *
 * These tests run against a real database and API.
 */

import * as request from 'supertest';
import * as path from 'path';
import * as fs from 'fs';
import {
  prisma,
  TEST_PREFIX,
  TEST_EMAIL_DOMAIN,
  cleanupTestData,
  generateStaffToken,
} from './test-helpers';
import { UserRole, SurveyStatus } from '@prisma/client';

const API_BASE = 'http://localhost:3000/api/v1';

describe('Sync + PDF Upload Flow (E2E)', () => {
  let surveyorToken: string;
  let surveyorId: string;
  let surveyId: string;
  let sectionId: string;
  let answerId: string;

  beforeAll(async () => {
    await cleanupTestData();

    // Create a surveyor user for the test
    let user = await prisma.user.findUnique({
      where: { email: `${TEST_PREFIX}sync_surveyor${TEST_EMAIL_DOMAIN}` },
    });
    if (!user) {
      user = await prisma.user.create({
        data: {
          email: `${TEST_PREFIX}sync_surveyor${TEST_EMAIL_DOMAIN}`,
          passwordHash: 'not-used-in-tests',
          firstName: 'Sync',
          lastName: 'Surveyor',
          role: UserRole.SURVEYOR,
          isActive: true,
        },
      });
    }
    surveyorId = user.id;
    surveyorToken = generateStaffToken(user.id, user.email, user.role);
  });

  afterAll(async () => {
    // Clean up created test data in correct order
    if (answerId) {
      await prisma.answer.deleteMany({ where: { id: answerId } });
    }
    if (sectionId) {
      await prisma.section.deleteMany({ where: { id: sectionId } });
    }
    if (surveyId) {
      await prisma.survey.deleteMany({ where: { id: surveyId } });
    }
    await cleanupTestData();
  });

  // ============================================================
  // STEP 1: Create survey (simulating offline-first sync)
  // ============================================================
  describe('Step 1: Create survey with client-provided UUID', () => {
    it('should create a survey with a client-provided ID', async () => {
      // Simulate the client sending a UUID it generated offline
      const clientUuid = '00000000-e2e1-4000-8000-000000000001';
      surveyId = clientUuid;

      const res = await request(API_BASE)
        .post('/surveys')
        .set('Authorization', `Bearer ${surveyorToken}`)
        .send({
          id: clientUuid,
          title: `${TEST_PREFIX} Sync Test Survey`,
          propertyAddress: '42 Test Lane, London',
          status: 'DRAFT',
          type: 'INSPECTION',
          jobRef: 'E2E-SYNC-001',
          clientName: 'E2E Test Client',
        });

      expect(res.status).toBe(201);
      expect(res.body.id).toBe(clientUuid);
      expect(res.body.title).toContain('Sync Test Survey');
    });

    it('should reject creating the same survey again (idempotent check)', async () => {
      const res = await request(API_BASE)
        .post('/surveys')
        .set('Authorization', `Bearer ${surveyorToken}`)
        .send({
          id: surveyId,
          title: `${TEST_PREFIX} Sync Test Survey`,
          propertyAddress: '42 Test Lane, London',
        });

      // Should get 409 Conflict for duplicate ID
      expect(res.status).toBe(409);
    });
  });

  // ============================================================
  // STEP 2: Create section under the survey
  // ============================================================
  describe('Step 2: Create section under survey', () => {
    it('should reject section creation for non-existent survey', async () => {
      const res = await request(API_BASE)
        .post('/surveys/00000000-0000-4000-8000-000000000099/sections')
        .set('Authorization', `Bearer ${surveyorToken}`)
        .send({
          title: 'Should Fail',
          order: 0,
        });

      expect(res.status).toBe(404);
      expect(res.body.success).toBe(false);
    });

    it('should create a section under the synced survey', async () => {
      const res = await request(API_BASE)
        .post(`/surveys/${surveyId}/sections`)
        .set('Authorization', `Bearer ${surveyorToken}`)
        .send({
          title: `${TEST_PREFIX} Roof Inspection`,
          order: 0,
        });

      expect(res.status).toBe(201);
      expect(res.body.id).toBeDefined();
      sectionId = res.body.id;
    });
  });

  // ============================================================
  // STEP 3: Create answer under the section
  // ============================================================
  describe('Step 3: Create answer under section', () => {
    it('should reject answer creation for non-existent section', async () => {
      const res = await request(API_BASE)
        .post('/sections/00000000-0000-4000-8000-000000000099/answers')
        .set('Authorization', `Bearer ${surveyorToken}`)
        .send({
          questionKey: 'should_fail',
          value: 'This should not work',
        });

      expect(res.status).toBe(404);
    });

    it('should create an answer under the synced section', async () => {
      const res = await request(API_BASE)
        .post(`/sections/${sectionId}/answers`)
        .set('Authorization', `Bearer ${surveyorToken}`)
        .send({
          questionKey: 'roof_condition',
          value: 'Good condition with minor wear',
        });

      expect(res.status).toBe(201);
      expect(res.body.id).toBeDefined();
      answerId = res.body.id;
    });
  });

  // ============================================================
  // STEP 4: Upload report PDF (requires survey to be in valid state)
  // ============================================================
  describe('Step 4: Upload report PDF', () => {
    it('should accept PDF upload for DRAFT survey', async () => {
      // DRAFT is in ALLOWED_PDF_UPLOAD_STATES (surveyors need interim reports during fieldwork)
      const pdfBuffer = Buffer.from(
        '%PDF-1.4\n1 0 obj\n<< /Type /Catalog >>\nendobj\ntrailer\n<< /Root 1 0 R >>\n%%EOF',
      );

      const res = await request(API_BASE)
        .post(`/surveys/${surveyId}/report-pdf`)
        .set('Authorization', `Bearer ${surveyorToken}`)
        .attach('file', pdfBuffer, {
          filename: 'test-report.pdf',
          contentType: 'application/pdf',
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
    });

    it('should reject PDF upload for REJECTED survey (400)', async () => {
      // Temporarily set survey status to REJECTED
      await prisma.survey.update({
        where: { id: surveyId },
        data: { status: 'REJECTED' },
      });

      const pdfBuffer = Buffer.from(
        '%PDF-1.4\n1 0 obj\n<< /Type /Catalog >>\nendobj\ntrailer\n<< /Root 1 0 R >>\n%%EOF',
      );

      const res = await request(API_BASE)
        .post(`/surveys/${surveyId}/report-pdf`)
        .set('Authorization', `Bearer ${surveyorToken}`)
        .attach('file', pdfBuffer, {
          filename: 'test-report.pdf',
          contentType: 'application/pdf',
        });

      expect(res.status).toBe(400);
      expect(res.body.message).toContain('REJECTED');

      // Restore survey status to DRAFT for subsequent tests
      await prisma.survey.update({
        where: { id: surveyId },
        data: { status: 'DRAFT' },
      });
    });

    it('should reject PDF upload for non-existent survey (404)', async () => {
      const pdfBuffer = Buffer.from(
        '%PDF-1.4\n1 0 obj\n<< /Type /Catalog >>\nendobj\ntrailer\n<< /Root 1 0 R >>\n%%EOF',
      );

      const res = await request(API_BASE)
        .post('/surveys/00000000-0000-4000-8000-000000000099/report-pdf')
        .set('Authorization', `Bearer ${surveyorToken}`)
        .attach('file', pdfBuffer, {
          filename: 'test-report.pdf',
          contentType: 'application/pdf',
        });

      expect(res.status).toBe(404);
      expect(res.body.message).toContain('not found');
    });
  });

  // ============================================================
  // STEP 5: Verify structured error responses
  // ============================================================
  describe('Step 5: Structured error responses', () => {
    it('should return structured validation error with field details', async () => {
      const res = await request(API_BASE)
        .post('/surveys')
        .set('Authorization', `Bearer ${surveyorToken}`)
        .send({
          // Missing required 'title' and 'propertyAddress'
          jobRef: 'MISSING-REQUIRED',
        });

      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('success', false);
      expect(res.body).toHaveProperty('statusCode', 400);
      expect(res.body).toHaveProperty('message');
      expect(res.body).toHaveProperty('timestamp');
      expect(res.body).toHaveProperty('path');
      expect(res.body).toHaveProperty('requestId');
      // Validation errors should have details array
      if (res.body.details) {
        expect(Array.isArray(res.body.details)).toBe(true);
      }
    });

    it('should reject unknown fields (forbidNonWhitelisted)', async () => {
      const res = await request(API_BASE)
        .post('/surveys')
        .set('Authorization', `Bearer ${surveyorToken}`)
        .send({
          title: 'Test Survey',
          propertyAddress: '123 Main St',
          unknownField: 'should be rejected',
          anotherBadField: 42,
        });

      expect(res.status).toBe(400);
      expect(res.body.message).toBeDefined();
    });
  });

  // ============================================================
  // STEP 6: Verify sync ordering constraints
  // ============================================================
  describe('Step 6: Sync ordering constraints', () => {
    it('should enforce survey exists before section creation', async () => {
      // Try to create a section for a non-existent survey
      const res = await request(API_BASE)
        .post('/surveys/00000000-0000-4000-8000-000000000098/sections')
        .set('Authorization', `Bearer ${surveyorToken}`)
        .send({ title: 'Orphan Section', order: 0 });

      expect(res.status).toBe(404);
    });

    it('should enforce section exists before answer creation', async () => {
      // Try to create an answer for a non-existent section
      const res = await request(API_BASE)
        .post('/sections/00000000-0000-4000-8000-000000000098/answers')
        .set('Authorization', `Bearer ${surveyorToken}`)
        .send({ questionKey: 'orphan_q', value: 'orphan answer' });

      expect(res.status).toBe(404);
    });
  });

  // ============================================================
  // STEP 7: AI status endpoint
  // ============================================================
  describe('Step 7: AI status endpoint', () => {
    it('should return AI service status', async () => {
      const res = await request(API_BASE)
        .get('/ai/status')
        .set('Authorization', `Bearer ${surveyorToken}`);

      // AI status should be accessible (may be 200 or 503 depending on config)
      expect([200, 503]).toContain(res.status);
      if (res.status === 200) {
        expect(res.body).toHaveProperty('available');
      }
    });
  });
});

describe('Rate Limiting (E2E)', () => {
  let surveyorToken: string;

  beforeAll(async () => {
    let user = await prisma.user.findUnique({
      where: { email: `${TEST_PREFIX}ratelimit_user${TEST_EMAIL_DOMAIN}` },
    });
    if (!user) {
      user = await prisma.user.create({
        data: {
          email: `${TEST_PREFIX}ratelimit_user${TEST_EMAIL_DOMAIN}`,
          passwordHash: 'not-used-in-tests',
          firstName: 'Rate',
          lastName: 'Limiter',
          role: UserRole.SURVEYOR,
          isActive: true,
        },
      });
    }
    surveyorToken = generateStaffToken(user.id, user.email, user.role);
  });

  afterAll(async () => {
    await cleanupTestData();
  });

  it('should return 429 with Retry-After header when rate limit exceeded', async () => {
    // Send rapid requests to trigger the 3 req/sec global limit
    const promises: Promise<request.Response>[] = [];
    for (let i = 0; i < 10; i++) {
      promises.push(
        request(API_BASE)
          .get('/surveys')
          .set('Authorization', `Bearer ${surveyorToken}`),
      );
    }

    const responses = await Promise.all(promises);
    const rateLimited = responses.filter((r) => r.status === 429);

    // At least some should be rate-limited with 10 concurrent requests
    // (The exact count depends on server timing, so we just verify the format)
    if (rateLimited.length > 0) {
      const rl = rateLimited[0];
      expect(rl.status).toBe(429);
      // ThrottlerGuard should include Retry-After header
      // Header name may be suffixed with throttler name (e.g., Retry-After-short)
      const hasRetryAfter = Object.keys(rl.headers).some((h) =>
        h.toLowerCase().startsWith('retry-after'),
      );
      expect(hasRetryAfter).toBe(true);
    }
  });
});

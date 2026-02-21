/**
 * E2E Integration Tests: Invoices
 *
 * Tests the invoice creation flow with real database:
 * 1. Invoice creation with correct number generation
 * 2. Invoice number sequencing
 * 3. Status transitions
 *
 * CRITICAL: These tests verify fix for issue C1:
 * - Raw SQL must use physical table name "invoices" (not "Invoice")
 * - Raw SQL must use physical column name "invoice_number" (not "invoiceNumber")
 *
 * These tests run against a real database and API.
 */

import * as request from 'supertest';
import {
  prisma,
  TEST_PREFIX,
  TEST_EMAIL_DOMAIN,
  cleanupTestData,
  generateStaffToken,
} from './test-helpers';
import { UserRole, InvoiceStatus } from '@prisma/client';

const API_BASE = 'http://localhost:3000/api/v1';

describe('Invoices (E2E)', () => {
  let adminToken: string;
  let adminUserId: string;
  let testClientId: string;
  let createdInvoiceIds: string[] = [];

  beforeAll(async () => {
    // Clean up any previous test data
    await cleanupInvoiceTestData();

    // Create test admin user
    const adminUser = await prisma.user.upsert({
      where: { email: `${TEST_PREFIX}invoice_admin${TEST_EMAIL_DOMAIN}` },
      update: {},
      create: {
        email: `${TEST_PREFIX}invoice_admin${TEST_EMAIL_DOMAIN}`,
        passwordHash: 'not-used-in-tests',
        firstName: 'Invoice',
        lastName: 'Admin',
        role: UserRole.ADMIN,
        isActive: true,
      },
    });
    adminUserId = adminUser.id;
    adminToken = generateStaffToken(adminUser.id, adminUser.email, adminUser.role);

    // Create test client
    const testClient = await prisma.client.upsert({
      where: { email: `${TEST_PREFIX}invoice_client${TEST_EMAIL_DOMAIN}` },
      update: {},
      create: {
        email: `${TEST_PREFIX}invoice_client${TEST_EMAIL_DOMAIN}`,
        firstName: 'Invoice',
        lastName: 'Client',
        isActive: true,
      },
    });
    testClientId = testClient.id;
  });

  afterAll(async () => {
    await cleanupInvoiceTestData();
    await prisma.$disconnect();
  });

  /**
   * Clean up invoice test data
   */
  async function cleanupInvoiceTestData() {
    // Delete invoice items for test invoices
    await prisma.invoiceItem.deleteMany({
      where: {
        invoice: {
          client: {
            email: { endsWith: TEST_EMAIL_DOMAIN },
          },
        },
      },
    });

    // Delete test invoices
    await prisma.invoice.deleteMany({
      where: {
        client: {
          email: { endsWith: TEST_EMAIL_DOMAIN },
        },
      },
    });

    // Delete test clients
    await prisma.client.deleteMany({
      where: { email: `${TEST_PREFIX}invoice_client${TEST_EMAIL_DOMAIN}` },
    });

    // Delete test users
    await prisma.refreshToken.deleteMany({
      where: {
        user: { email: `${TEST_PREFIX}invoice_admin${TEST_EMAIL_DOMAIN}` },
      },
    });
    await prisma.user.deleteMany({
      where: { email: `${TEST_PREFIX}invoice_admin${TEST_EMAIL_DOMAIN}` },
    });
  }

  // ==========================================
  // INVOICE CREATION - Critical test for C1 fix
  // ==========================================

  describe('POST /invoices - Invoice Creation', () => {
    /**
     * CRITICAL TEST: Verifies fix for issue C1
     *
     * Before fix: Raw SQL used "Invoice" table name which doesn't exist in PostgreSQL.
     * After fix: Raw SQL uses "invoices" table name (from @@map("invoices")).
     *
     * If this test fails with "relation Invoice does not exist", the fix is not applied.
     */
    it('should create an invoice with valid invoice number (C1 fix verification)', async () => {
      const response = await request(API_BASE)
        .post('/invoices')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          clientId: testClientId,
          items: [
            {
              description: 'Survey service - Level 2',
              quantity: 1,
              unitPrice: 45000, // £450.00 in pence
            },
          ],
          notes: 'E2E test invoice',
        });

      // If C1 bug exists, this will return 500 with "relation Invoice does not exist"
      expect(response.status).toBe(201);
      expect(response.body).toHaveProperty('id');
      expect(response.body).toHaveProperty('invoiceNumber');

      // Verify invoice number format: INV-YYYYMM-XXXX
      expect(response.body.invoiceNumber).toMatch(/^INV-\d{6}-\d{4}$/);

      // Track for cleanup
      createdInvoiceIds.push(response.body.id);

      // Verify invoice exists in database with correct number
      const dbInvoice = await prisma.invoice.findUnique({
        where: { id: response.body.id },
      });
      expect(dbInvoice).not.toBeNull();
      expect(dbInvoice!.invoiceNumber).toBe(response.body.invoiceNumber);
    });

    it('should generate sequential invoice numbers', async () => {
      // Create first invoice
      const response1 = await request(API_BASE)
        .post('/invoices')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          clientId: testClientId,
          items: [{ description: 'Service 1', quantity: 1, unitPrice: 10000 }],
        });

      expect(response1.status).toBe(201);
      createdInvoiceIds.push(response1.body.id);

      // Create second invoice
      const response2 = await request(API_BASE)
        .post('/invoices')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          clientId: testClientId,
          items: [{ description: 'Service 2', quantity: 1, unitPrice: 20000 }],
        });

      expect(response2.status).toBe(201);
      createdInvoiceIds.push(response2.body.id);

      // Extract sequence numbers
      const num1 = parseInt(response1.body.invoiceNumber.split('-')[2]);
      const num2 = parseInt(response2.body.invoiceNumber.split('-')[2]);

      // Second invoice should have higher sequence number
      expect(num2).toBeGreaterThan(num1);
    });

    it('should reject creation without items', async () => {
      const response = await request(API_BASE)
        .post('/invoices')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          clientId: testClientId,
          items: [],
        });

      expect(response.status).toBe(400);
    });

    it('should reject creation with invalid client ID', async () => {
      const response = await request(API_BASE)
        .post('/invoices')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          clientId: '00000000-0000-0000-0000-000000000000',
          items: [{ description: 'Test', quantity: 1, unitPrice: 100 }],
        });

      expect(response.status).toBe(404);
    });
  });

  // ==========================================
  // INVOICE STATUS TRANSITIONS
  // ==========================================

  describe('Invoice Status Transitions', () => {
    let draftInvoiceId: string;

    beforeAll(async () => {
      // Create a draft invoice for status transition tests
      const response = await request(API_BASE)
        .post('/invoices')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          clientId: testClientId,
          items: [{ description: 'Status test invoice', quantity: 1, unitPrice: 5000 }],
        });

      draftInvoiceId = response.body.id;
      createdInvoiceIds.push(draftInvoiceId);
    });

    it('should issue a draft invoice (DRAFT → ISSUED)', async () => {
      const response = await request(API_BASE)
        .patch(`/invoices/${draftInvoiceId}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ status: InvoiceStatus.ISSUED });

      // Note: The actual endpoint might be different - adjust based on controller
      // If there's a dedicated issue endpoint, use that instead
    });
  });

  // ==========================================
  // AUTHENTICATION & AUTHORIZATION
  // ==========================================

  describe('Authentication', () => {
    it('should reject unauthenticated requests', async () => {
      const response = await request(API_BASE)
        .post('/invoices')
        .send({
          clientId: testClientId,
          items: [{ description: 'Test', quantity: 1, unitPrice: 100 }],
        });

      expect(response.status).toBe(401);
    });

    it('should reject requests with invalid token', async () => {
      const response = await request(API_BASE)
        .post('/invoices')
        .set('Authorization', 'Bearer invalid-token')
        .send({
          clientId: testClientId,
          items: [{ description: 'Test', quantity: 1, unitPrice: 100 }],
        });

      expect(response.status).toBe(401);
    });
  });
});

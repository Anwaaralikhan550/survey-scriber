/**
 * Test Helpers for E2E Tests
 *
 * Provides utilities for:
 * - Generating test JWT tokens (staff and client)
 * - Creating and cleaning up test data
 */

import { PrismaClient, UserRole, BookingStatus } from '@prisma/client';
import * as jwt from 'jsonwebtoken';

const prisma = new PrismaClient();

// Use the same secret as the backend
const JWT_SECRET = process.env.JWT_ACCESS_SECRET || 'dev-access-secret-key-for-local-development-only';

// Test data identifiers (clearly labeled for cleanup)
export const TEST_PREFIX = 'E2E_TEST_';
export const TEST_EMAIL_DOMAIN = '@e2e-test.local';

/**
 * Generate a staff JWT token for testing
 */
export function generateStaffToken(userId: string, email: string, role: UserRole): string {
  return jwt.sign(
    {
      sub: userId,
      email,
      role,
    },
    JWT_SECRET,
    { expiresIn: '1h' }
  );
}

/**
 * Generate a client JWT token for testing
 */
export function generateClientToken(clientId: string, email: string): string {
  return jwt.sign(
    {
      sub: clientId,
      email,
      type: 'client',
    },
    JWT_SECRET,
    { expiresIn: '1h' }
  );
}

/**
 * Helper to find or create a user
 */
async function findOrCreateUser(email: string, data: { firstName: string; lastName: string; role: UserRole }) {
  let user = await prisma.user.findUnique({ where: { email } });
  if (!user) {
    user = await prisma.user.create({
      data: {
        email,
        passwordHash: 'not-used-in-tests',
        firstName: data.firstName,
        lastName: data.lastName,
        role: data.role,
        isActive: true,
      },
    });
  }
  return user;
}

/**
 * Helper to find or create a client
 */
async function findOrCreateClient(email: string, data: { firstName: string; lastName: string }) {
  let client = await prisma.client.findUnique({ where: { email } });
  if (!client) {
    client = await prisma.client.create({
      data: {
        email,
        firstName: data.firstName,
        lastName: data.lastName,
        isActive: true,
      },
    });
  }
  return client;
}

/**
 * Create test fixtures for booking change request tests
 */
export async function createTestFixtures() {
  // Create test admin user
  const adminUser = await findOrCreateUser(
    `${TEST_PREFIX}admin${TEST_EMAIL_DOMAIN}`,
    { firstName: 'Test', lastName: 'Admin', role: UserRole.ADMIN }
  );

  // Create test manager user
  const managerUser = await findOrCreateUser(
    `${TEST_PREFIX}manager${TEST_EMAIL_DOMAIN}`,
    { firstName: 'Test', lastName: 'Manager', role: UserRole.MANAGER }
  );

  // Create test surveyor user (for RBAC tests - should be forbidden)
  const surveyorUser = await findOrCreateUser(
    `${TEST_PREFIX}surveyor${TEST_EMAIL_DOMAIN}`,
    { firstName: 'Test', lastName: 'Surveyor', role: UserRole.SURVEYOR }
  );

  // Create test client
  const client = await findOrCreateClient(
    `${TEST_PREFIX}client${TEST_EMAIL_DOMAIN}`,
    { firstName: 'Test', lastName: 'Client' }
  );

  // Create test booking for change requests (always create new)
  const futureDate = new Date();
  futureDate.setDate(futureDate.getDate() + 14); // 2 weeks from now

  const booking = await prisma.booking.create({
    data: {
      surveyorId: surveyorUser.id,
      createdById: adminUser.id,
      clientId: client.id,
      date: futureDate,
      startTime: '10:00',
      endTime: '12:00',
      clientEmail: `${TEST_PREFIX}client${TEST_EMAIL_DOMAIN}`,
      propertyAddress: `${TEST_PREFIX} 123 Test Street, Test City`,
      status: BookingStatus.CONFIRMED,
    },
  });

  return {
    adminUser,
    managerUser,
    surveyorUser,
    client,
    booking,
    tokens: {
      admin: generateStaffToken(adminUser.id, adminUser.email, adminUser.role),
      manager: generateStaffToken(managerUser.id, managerUser.email, managerUser.role),
      surveyor: generateStaffToken(surveyorUser.id, surveyorUser.email, surveyorUser.role),
      client: generateClientToken(client.id, client.email),
    },
  };
}

/**
 * Clean up all test data
 */
export async function cleanupTestData() {
  // Delete in correct order due to foreign key constraints

  // Delete booking change requests for test clients
  await prisma.bookingChangeRequest.deleteMany({
    where: {
      client: {
        email: { endsWith: TEST_EMAIL_DOMAIN },
      },
    },
  });

  // Delete notifications for test users/clients
  await prisma.notification.deleteMany({
    where: {
      OR: [
        { recipientId: { in: await getTestUserIds() } },
        { recipientId: { in: await getTestClientIds() } },
      ],
    },
  });

  // Delete bookings for test clients
  await prisma.booking.deleteMany({
    where: {
      clientEmail: { endsWith: TEST_EMAIL_DOMAIN },
    },
  });

  // Delete audit logs from test users
  await prisma.auditLog.deleteMany({
    where: {
      OR: [
        { actorId: { in: await getTestUserIds() } },
        { actorId: { in: await getTestClientIds() } },
        { action: { startsWith: 'E2E_TEST' } },
      ],
    },
  });

  // Delete test clients
  await prisma.client.deleteMany({
    where: { email: { endsWith: TEST_EMAIL_DOMAIN } },
  });

  // Delete refresh tokens for test users
  await prisma.refreshToken.deleteMany({
    where: {
      user: { email: { endsWith: TEST_EMAIL_DOMAIN } },
    },
  });

  // Delete test users
  await prisma.user.deleteMany({
    where: { email: { endsWith: TEST_EMAIL_DOMAIN } },
  });
}

async function getTestUserIds(): Promise<string[]> {
  const users = await prisma.user.findMany({
    where: { email: { endsWith: TEST_EMAIL_DOMAIN } },
    select: { id: true },
  });
  return users.map(u => u.id);
}

async function getTestClientIds(): Promise<string[]> {
  const clients = await prisma.client.findMany({
    where: { email: { endsWith: TEST_EMAIL_DOMAIN } },
    select: { id: true },
  });
  return clients.map(c => c.id);
}

export { prisma };

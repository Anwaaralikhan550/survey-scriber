/**
 * Manual Test Setup Script
 * Run: npx ts-node test/manual-setup.ts
 */

import { PrismaClient, UserRole, BookingStatus } from '@prisma/client';
import * as jwt from 'jsonwebtoken';

const prisma = new PrismaClient();
const JWT_SECRET = 'dev-access-secret-key-for-local-development-only';

async function setup() {
  console.log('Setting up manual test data...\n');

  // Create test admin user
  const adminUser = await prisma.user.upsert({
    where: { email: 'manual-test-admin@test.local' },
    update: {},
    create: {
      email: 'manual-test-admin@test.local',
      passwordHash: 'test',
      firstName: 'Manual',
      lastName: 'Admin',
      role: UserRole.ADMIN,
      isActive: true,
    },
  });
  console.log('Admin user ID:', adminUser.id);

  // Create test client
  const client = await prisma.client.upsert({
    where: { email: 'manual-test-client@test.local' },
    update: {},
    create: {
      email: 'manual-test-client@test.local',
      firstName: 'Manual',
      lastName: 'Client',
      isActive: true,
    },
  });
  console.log('Client ID:', client.id);

  // Create test booking
  const futureDate = new Date();
  futureDate.setDate(futureDate.getDate() + 14);

  const booking = await prisma.booking.create({
    data: {
      surveyorId: adminUser.id,
      createdById: adminUser.id,
      clientId: client.id,
      date: futureDate,
      startTime: '09:00',
      endTime: '11:00',
      clientEmail: 'manual-test-client@test.local',
      propertyAddress: 'MANUAL_TEST 123 Test Street',
      status: BookingStatus.CONFIRMED,
    },
  });
  console.log('Booking ID:', booking.id);

  // Generate tokens
  const adminToken = jwt.sign(
    { sub: adminUser.id, email: adminUser.email, role: UserRole.ADMIN },
    JWT_SECRET,
    { expiresIn: '1h' }
  );

  const clientToken = jwt.sign(
    { sub: client.id, email: client.email, type: 'client' },
    JWT_SECRET,
    { expiresIn: '1h' }
  );

  console.log('\n=== TOKENS FOR MANUAL TESTING ===\n');
  console.log('ADMIN_TOKEN=' + adminToken);
  console.log('\nCLIENT_TOKEN=' + clientToken);
  console.log('\nBOOKING_ID=' + booking.id);

  await prisma.$disconnect();
}

setup().catch((e) => {
  console.error(e);
  process.exit(1);
});

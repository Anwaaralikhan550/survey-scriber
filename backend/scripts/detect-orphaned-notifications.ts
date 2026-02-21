/**
 * One-time script to detect and clean up orphaned notifications
 *
 * This script identifies notifications that reference non-existent bookings
 * and nulls out the bookingId to prevent downstream errors.
 *
 * Usage:
 *   npx ts-node scripts/detect-orphaned-notifications.ts [--dry-run]
 *
 * Options:
 *   --dry-run  Show what would be updated without making changes
 *
 * This script is idempotent and safe to run multiple times.
 */

import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function detectOrphanedNotifications(dryRun: boolean): Promise<void> {
  console.log('='.repeat(60));
  console.log('Orphaned Notification Detection Script');
  console.log('='.repeat(60));
  console.log(`Mode: ${dryRun ? 'DRY RUN (no changes will be made)' : 'LIVE'}`);
  console.log();

  try {
    // Find notifications with bookingId that don't have a matching booking
    const orphanedNotifications = await prisma.$queryRaw<
      { id: string; booking_id: string; title: string; created_at: Date }[]
    >`
      SELECT n.id, n.booking_id, n.title, n.created_at
      FROM notifications n
      LEFT JOIN bookings b ON n.booking_id = b.id
      WHERE n.booking_id IS NOT NULL
        AND b.id IS NULL
      ORDER BY n.created_at DESC
    `;

    console.log(`Found ${orphanedNotifications.length} orphaned notification(s)`);
    console.log();

    if (orphanedNotifications.length === 0) {
      console.log('No orphaned notifications found. Database is clean.');
      return;
    }

    // Display sample of orphaned notifications
    console.log('Sample of orphaned notifications:');
    console.log('-'.repeat(60));
    const sample = orphanedNotifications.slice(0, 10);
    for (const n of sample) {
      console.log(`  ID: ${n.id}`);
      console.log(`  Booking ID: ${n.booking_id} (MISSING)`);
      console.log(`  Title: ${n.title}`);
      console.log(`  Created: ${n.created_at}`);
      console.log();
    }
    if (orphanedNotifications.length > 10) {
      console.log(`  ... and ${orphanedNotifications.length - 10} more`);
      console.log();
    }

    if (dryRun) {
      console.log('DRY RUN: No changes made. Run without --dry-run to apply changes.');
      return;
    }

    // Clean up orphaned notifications by nulling the dangling bookingId
    console.log('Cleaning up orphaned notifications...');
    const orphanIds = orphanedNotifications.map((n) => n.id);

    const result = await prisma.notification.updateMany({
      where: {
        id: { in: orphanIds },
      },
      data: {
        bookingId: null,
      },
    });

    console.log(`Successfully cleaned ${result.count} orphaned notification(s).`);
    console.log();
    console.log('Summary:');
    console.log(`  - Notifications processed: ${result.count}`);
    console.log(`  - bookingId: set to null (dangling reference removed)`);

  } catch (error) {
    console.error('Error detecting orphaned notifications:', error);
    throw error;
  }
}

async function main(): Promise<void> {
  const args = process.argv.slice(2);
  const dryRun = args.includes('--dry-run');

  try {
    await detectOrphanedNotifications(dryRun);
  } finally {
    await prisma.$disconnect();
  }
}

main()
  .then(() => {
    console.log();
    console.log('Script completed successfully.');
    process.exit(0);
  })
  .catch((error) => {
    console.error('Script failed:', error);
    process.exit(1);
  });

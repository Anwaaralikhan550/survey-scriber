import { Prisma, ReportStatus, ReviewDecision } from '@prisma/client';

/** Statuses in which an approval of the current content stands. */
const APPROVED: ReportStatus[] = [ReportStatus.REVIEWER_APPROVED, ReportStatus.OWNER_FINAL_APPROVAL];

/**
 * Spec section 14: "Any change after reviewer approval invalidates that approval."
 * Called inside every write transaction that changes the report's content (text save, photo change, snapshot
 * upload, version restore) after the version was raised. A reviewer's or the owner's approval belongs to the
 * exact version they approved, so it is marked invalid and the report goes back to waiting for review.
 * Returns the new status when it changed, otherwise null.
 */
export async function invalidateApprovalsAfterChange(
  tx: Prisma.TransactionClient,
  reportId: string,
  statusBefore: ReportStatus,
): Promise<ReportStatus | null> {
  if (!APPROVED.includes(statusBefore)) return null;
  await tx.review.updateMany({
    where: { reportId, invalidatedAt: null, decision: { in: [ReviewDecision.APPROVED, ReviewDecision.OWNER_APPROVED] } },
    data: { invalidatedAt: new Date() },
  });
  await tx.report.update({ where: { id: reportId }, data: { status: ReportStatus.SUBMITTED_FOR_REVIEW } });
  return ReportStatus.SUBMITTED_FOR_REVIEW;
}

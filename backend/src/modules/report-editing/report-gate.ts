import { ReportStatus } from '@prisma/client';

/** Anything with the Prisma delegates the rule reads: the client itself or a transaction. */
export interface GateDb {
  report: { findUnique(args: { where: { id: string }; select: { status: true; version: true } }): Promise<{ status: ReportStatus; version: number } | null> };
  reportVersion: { findFirst(args: { where: { reportId: string; reason: string }; select: { id: true } }): Promise<{ id: string } | null> };
}

export type GateRefusal = { code: 'REPORT_FINALISED' } | { code: 'REPORT_VERSION_CONFLICT'; currentVersion: number };

/**
 * Remote Editor (spec v1.4 sections 10, 11 and 15): may the phone change data of this survey?
 * - Not once the report is finalised.
 * - Not when the report was edited on a computer and the phone has not taken those edits: [knownVersion] is the cloud report
 *   version the phone has; a missing or older one is a stale write and is refused, never applied and never silently dropped.
 * Returns null when the change may go on (also when the survey has no cloud report).
 */
export async function reportGate(db: GateDb, surveyId: string, knownVersion: number | undefined): Promise<GateRefusal | null> {
  const report = await db.report.findUnique({ where: { id: surveyId }, select: { status: true, version: true } });
  if (!report) return null;
  if (report.status === ReportStatus.FINALISING || report.status === ReportStatus.FINALISED) return { code: 'REPORT_FINALISED' };
  const editedRemotely = (await db.reportVersion.findFirst({ where: { reportId: surveyId, reason: 'SAVE' }, select: { id: true } })) !== null;
  if (!editedRemotely) return null;
  if (typeof knownVersion === 'number' && Number.isInteger(knownVersion) && knownVersion >= report.version) return null;
  return { code: 'REPORT_VERSION_CONFLICT', currentVersion: report.version };
}

export const CONFLICT_MESSAGE = (currentVersion: number) =>
  `This report was edited on a computer (cloud version ${currentVersion}). Synchronise it on the phone first; your change is kept and will be sent afterwards.`;
export const FINALISED_MESSAGE = 'This report has been finalised and can no longer be changed';

import { ReportStatus } from '@prisma/client';

/**
 * The retention rules of Remote Editor spec v1.4 section 15 as pure functions of a report's own dates, so every day of the table can be
 * tested with a fixed clock.
 *  - FINALISED: 60 days from finalisation. Warnings on day 30, 45, 55. Eligible on day 60.
 *  - DRAFT: 30 days from the last meaningful activity. Warnings on day 20, 25, 28. Eligible on day 30.
 *  - Reviews and finalisation in progress, and a live edit link, are active work: never purged.
 */
export const DAY_MS = 24 * 60 * 60 * 1000;

export interface RetentionPolicy {
  finalisedDays: number;
  draftDays: number;
  finalisedWarnings: number[];
  draftWarnings: number[];
  /** retries of a failed file deletion before the queue item is marked FAILED for an operator */
  maxAttempts: number;
  /** a released hold gives the owner this many days before the report can be purged */
  holdReleaseGraceDays: number;
  /**
   * The policy never counts from a moment before this. Reports that already exist when retention is switched on get the full period
   * (and their warnings) from this moment, so nothing is deleted without notice on the first run.
   */
  startsAt?: Date | null;
}

export const DEFAULT_POLICY: RetentionPolicy = {
  finalisedDays: 60,
  draftDays: 30,
  finalisedWarnings: [30, 45, 55],
  draftWarnings: [20, 25, 28],
  maxAttempts: 8,
  holdReleaseGraceDays: 7,
};

export type RetentionKind = 'FINALISED' | 'DRAFT';

export interface RetentionInput {
  status: ReportStatus;
  /** the report's last change (a save, an upload, a workflow action): opening it does not change this */
  updatedAt: Date;
  finalisedAt: Date | null;
  restoredAt: Date | null;
  /** an edit link is live right now */
  linkLive: boolean;
}

export interface RetentionState {
  kind: RetentionKind;
  anchorAt: Date;
  deleteAt: Date;
}

/** Null when the report is active work that the retention policy leaves alone. */
export function retentionOf(r: RetentionInput, policy: RetentionPolicy = DEFAULT_POLICY): RetentionState | null {
  if (r.status === ReportStatus.FINALISED) {
    const dates = [r.finalisedAt ?? r.updatedAt, ...(r.restoredAt ? [r.restoredAt] : [])];
    const anchorAt = new Date(Math.max(...dates.map((d) => d.getTime())));
    const clamped = policy.startsAt && policy.startsAt > anchorAt ? policy.startsAt : anchorAt;
    return { kind: 'FINALISED', anchorAt: clamped, deleteAt: new Date(clamped.getTime() + policy.finalisedDays * DAY_MS) };
  }
  if (r.status === ReportStatus.DRAFT) {
    const anchorAt = policy.startsAt && policy.startsAt > r.updatedAt ? policy.startsAt : r.updatedAt;
    // A live edit link is active editing: the clock does not run out under it.
    return { kind: 'DRAFT', anchorAt, deleteAt: new Date(anchorAt.getTime() + policy.draftDays * DAY_MS) };
  }
  return null; // submitted, under review, amendments, approved, finalising: a workflow in progress
}

/** Whole days elapsed since the anchor (day 0 is the day of finalisation or of the last activity). */
export function dayNumber(anchorAt: Date, now: Date): number {
  return Math.floor((now.getTime() - anchorAt.getTime()) / DAY_MS);
}

export function warningDays(kind: RetentionKind, policy: RetentionPolicy = DEFAULT_POLICY): number[] {
  return kind === 'FINALISED' ? policy.finalisedWarnings : policy.draftWarnings;
}

/** The warning that is due now and was not sent yet: the latest warning day reached. Null before the first, or when all reached were sent. */
export function dueWarning(kind: RetentionKind, anchorAt: Date, now: Date, alreadySent: number[], policy: RetentionPolicy = DEFAULT_POLICY): number | null {
  const day = dayNumber(anchorAt, now);
  const reached = warningDays(kind, policy).filter((d) => d <= day);
  if (reached.length === 0) return null;
  const latest = Math.max(...reached);
  return alreadySent.includes(latest) ? null : latest;
}

export function daysLeft(deleteAt: Date, now: Date): number {
  return Math.max(0, Math.ceil((deleteAt.getTime() - now.getTime()) / DAY_MS));
}

/** Eligible for deletion: the deadline has passed and no hold or grace stands in the way. */
export function eligible(state: RetentionState, now: Date, opts: { held: boolean; graceUntil: Date | null; linkLive: boolean }): boolean {
  if (opts.held) return false;
  if (opts.linkLive) return false;
  if (opts.graceUntil && opts.graceUntil.getTime() > now.getTime()) return false;
  return now.getTime() >= state.deleteAt.getTime();
}

/** The numbers in a policy come from configuration as text (CSV). Bad values fall back to the default. */
export function parseDays(value: string | undefined, fallback: number[]): number[] {
  if (!value) return fallback;
  const days = value
    .split(',')
    .map((s) => Number(s.trim()))
    .filter((n) => Number.isInteger(n) && n > 0);
  return days.length > 0 ? [...new Set(days)].sort((a, b) => a - b) : fallback;
}

export function backoffMinutes(attempts: number): number {
  return Math.min(24 * 60, 5 * 2 ** Math.max(0, attempts - 1));
}

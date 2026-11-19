import { HttpStatus, Inject, Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Cron, CronExpression } from '@nestjs/schedule';
import { ActorType, AuditEntityType, NotificationType, RecipientType, ReportStatus, UserRole } from '@prisma/client';
import { Request } from 'express';
import { PrismaService } from '../prisma/prisma.service';
import { AuditService } from '../audit/audit.service';
import { EmailService } from '../auth/email.service';
import { STORAGE_SERVICE, StorageService } from '../media/storage/storage.interface';
import { Errors, editingError } from './editing.errors';
import { holdPlacedText, holdReleasedText, purgedText, warningText } from './retention-messages';
import {
  DAY_MS,
  DEFAULT_POLICY,
  RetentionKind,
  RetentionPolicy,
  RetentionState,
  backoffMinutes,
  daysLeft,
  dueWarning,
  eligible,
  parseDays,
  retentionOf,
  warningDays,
} from './retention';
import type { Owner } from './report-editing.service';

export interface RunSummary {
  asOf: Date;
  evaluated: number;
  warned: number;
  queued: number;
  cancelled: number;
  purged: number;
  retrying: number;
  failed: number;
}

const BATCH = 200;

/** A report row the job checks. */
interface EvalReport {
  id: string;
  ownerUserId: string;
  status: ReportStatus;
  updatedAt: Date;
  finalisedAt: Date | null;
  restoredAt: Date | null;
  survey: { title: string };
  retention: { policy: string; anchorAt: Date; deleteAt: Date; warnedDays: number[]; graceUntil: Date | null } | null;
}

/** The report (or its survey) was deleted while the job was working on it: a foreign-key or not-found error from the database. */
function isGone(error: unknown): boolean {
  const code = (error as { code?: string }).code;
  return code === 'P2003' || code === 'P2025' || code === 'P2018';
}
const staff = (u: Owner) => u.role === UserRole.ADMIN || u.role === UserRole.MANAGER;

/**
 * Retention of cloud reports (Remote Editor spec v1.4 section 15): 60 days after finalisation, 30 days after the last meaningful activity
 * for drafts; warnings by notification and e-mail; an idempotent deletion queue that deletes files first, then the report, and leaves only
 * a tombstone; a legal hold by Admin or Manager that blocks it all. Everything is a function of the report's own dates and an injectable
 * clock, so the job can run any number of times and always reaches the same state.
 */
@Injectable()
export class ReportRetentionService {
  private readonly logger = new Logger(ReportRetentionService.name);
  private running = false;

  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly config: ConfigService,
    private readonly email: EmailService,
    @Inject(STORAGE_SERVICE) private readonly storage: StorageService,
  ) {}

  /** The configured policy plus the moment it started counting. Without REPORT_RETENTION_STARTS_AT it is the first moment the job ever ran. */
  async policyNow(now: Date): Promise<RetentionPolicy> {
    const policy = this.policy;
    const fromEnv = this.config.get<string>('REPORT_RETENTION_STARTS_AT');
    if (fromEnv && !Number.isNaN(new Date(fromEnv).getTime())) return { ...policy, startsAt: new Date(fromEnv) };
    const key = 'report_retention_starts_at';
    let row = await this.prisma.appSetting.findUnique({ where: { key } });
    if (!row) {
      row = await this.prisma.appSetting.upsert({ where: { key }, create: { key, value: now.toISOString(), updatedBy: 'system' }, update: {} });
    }
    return { ...policy, startsAt: new Date(row.value) };
  }

  get policy(): RetentionPolicy {
    const n = (key: string, fallback: number) => {
      const v = Number(this.config.get(key));
      return Number.isInteger(v) && v > 0 ? v : fallback;
    };
    return {
      finalisedDays: n('REPORT_RETENTION_DAYS', DEFAULT_POLICY.finalisedDays),
      draftDays: n('REPORT_DRAFT_RETENTION_DAYS', DEFAULT_POLICY.draftDays),
      finalisedWarnings: parseDays(this.config.get('REPORT_RETENTION_WARNING_DAYS'), DEFAULT_POLICY.finalisedWarnings),
      draftWarnings: parseDays(this.config.get('REPORT_DRAFT_WARNING_DAYS'), DEFAULT_POLICY.draftWarnings),
      maxAttempts: n('REPORT_PURGE_MAX_ATTEMPTS', DEFAULT_POLICY.maxAttempts),
      holdReleaseGraceDays: n('REPORT_HOLD_RELEASE_GRACE_DAYS', DEFAULT_POLICY.holdReleaseGraceDays),
    };
  }

  /** Hourly. Safe to run twice: every step re-reads the state and only moves it forward. */
  @Cron(CronExpression.EVERY_HOUR)
  async scheduled(): Promise<void> {
    if (this.config.get('REPORT_RETENTION_ENABLED') === 'false') return;
    try {
      const s = await this.run();
      if (s.warned + s.queued + s.purged + s.cancelled + s.failed > 0) this.logger.log(`Retention run: ${JSON.stringify(s)}`);
    } catch (error) {
      this.logger.error(`Retention run failed: ${(error as Error).message}`);
    }
  }

  // ------------------------------------------------------------------------------------------------ the job

  async run(now: Date = new Date(), opts: { retryFailed?: boolean } = {}): Promise<RunSummary> {
    const summary: RunSummary = { asOf: now, evaluated: 0, warned: 0, queued: 0, cancelled: 0, purged: 0, retrying: 0, failed: 0 };
    if (this.running) return summary; // one run at a time in this process
    this.running = true;
    try {
      if (opts.retryFailed) await this.prisma.reportDeletion.updateMany({ where: { status: 'FAILED' }, data: { status: 'PENDING', attempts: 0, nextAttemptAt: now } });
      await this.evaluateAll(now, summary);
      await this.processQueue(now, summary);
      return summary;
    } finally {
      this.running = false;
    }
  }

  private async evaluateAll(now: Date, summary: RunSummary): Promise<void> {
    const policy = await this.policyNow(now);
    const held = new Set((await this.prisma.reportLegalHold.findMany({ where: { releasedAt: null }, select: { reportId: true } })).map((h) => h.reportId));
    const live = new Set((await this.prisma.editLink.findMany({ where: { status: 'ACTIVE', expiresAt: { gt: now } }, select: { reportId: true } })).map((l) => l.reportId));
    let cursor: string | undefined;
    for (;;) {
      const reports = await this.prisma.report.findMany({
        take: BATCH,
        ...(cursor ? { skip: 1, cursor: { id: cursor } } : {}),
        orderBy: { id: 'asc' },
        select: { id: true, ownerUserId: true, status: true, updatedAt: true, finalisedAt: true, restoredAt: true, survey: { select: { title: true } }, retention: true },
      });
      if (reports.length === 0) break;
      cursor = reports[reports.length - 1].id;
      for (const r of reports) {
        summary.evaluated++;
        try {
          await this.evaluateOne(r, now, policy, held, live, summary);
        } catch (error) {
          if (isGone(error)) continue; // the report was deleted while the job was looking at it
          this.logger.warn(`Retention check of ${r.id} failed: ${(error as Error).message}`);
        }
      }
      if (reports.length < BATCH) break;
    }
  }

  private async evaluateOne(
    r: EvalReport,
    now: Date,
    policy: RetentionPolicy,
    held: Set<string>,
    live: Set<string>,
    summary: RunSummary,
  ): Promise<void> {
    const linkLive = live.has(r.id);
    const state = retentionOf({ status: r.status, updatedAt: r.updatedAt, finalisedAt: r.finalisedAt, restoredAt: r.restoredAt, linkLive }, policy);
    if (!state) {
      // active work (a review, finalising): nothing to track, nothing queued
      if (r.retention) await this.prisma.reportRetention.delete({ where: { reportId: r.id } }).catch(() => undefined);
      summary.cancelled += (await this.prisma.reportDeletion.deleteMany({ where: { reportId: r.id, status: { in: ['PENDING', 'FAILED'] } } })).count;
      return;
    }
    const sameAnchor = r.retention && r.retention.policy === state.kind && r.retention.anchorAt.getTime() === state.anchorAt.getTime();
    const warnedDays = sameAnchor ? r.retention!.warnedDays : []; // new anchor: pending warnings are cleared
    if (!r.retention || !sameAnchor || r.retention.deleteAt.getTime() !== state.deleteAt.getTime()) {
      await this.prisma.reportRetention.upsert({
        where: { reportId: r.id },
        create: { reportId: r.id, policy: state.kind, anchorAt: state.anchorAt, deleteAt: state.deleteAt, warnedDays: [] },
        update: { policy: state.kind, anchorAt: state.anchorAt, deleteAt: state.deleteAt, warnedDays: [] },
      });
    }
    const graceUntil = r.retention?.graceUntil ?? null;
    const isHeld = held.has(r.id);
    if (eligible(state, now, { held: isHeld, graceUntil, linkLive })) {
      const queuedAlready = await this.prisma.reportDeletion.findUnique({ where: { reportId: r.id }, select: { id: true } });
      if (!queuedAlready) {
        await this.prisma.reportDeletion.create({
          data: { reportId: r.id, ownerUserId: r.ownerUserId, policy: state.kind, anchorAt: state.anchorAt, deleteAt: state.deleteAt, status: 'PENDING', nextAttemptAt: now },
        });
        summary.queued++;
      }
      return;
    }
    // not eligible (activity resumed, a hold, a live link): nothing may stay queued for it
    summary.cancelled += (await this.prisma.reportDeletion.deleteMany({ where: { reportId: r.id, status: { in: ['PENDING', 'FAILED'] } } })).count;
    if (isHeld || now.getTime() >= state.deleteAt.getTime()) return;
    const day = dueWarning(state.kind, state.anchorAt, now, warnedDays, policy);
    if (day === null) return;
    const reached = warningDays(state.kind, policy).filter((d) => d <= day);
    const isFinal = day === Math.max(...warningDays(state.kind, policy));
    const text = warningText({ kind: state.kind, title: r.survey.title, day, isFinal, anchorAt: state.anchorAt, deleteAt: state.deleteAt, now });
    await this.prisma.reportRetention.update({ where: { reportId: r.id }, data: { warnedDays: reached } });
    await this.notify(r.ownerUserId, NotificationType.REPORT_RETENTION_WARNING, text);
    summary.warned++;
  }

  private async processQueue(now: Date, summary: RunSummary): Promise<void> {
    const policy = await this.policyNow(now);
    const items = await this.prisma.reportDeletion.findMany({ where: { status: 'PENDING', nextAttemptAt: { lte: now } }, orderBy: { nextAttemptAt: 'asc' }, take: 50 });
    for (const item of items) {
      try {
        await this.processItem(item, now, policy, summary);
      } catch (error) {
        if (isGone(error)) continue;
        this.logger.warn(`Retention queue item ${item.reportId} failed: ${(error as Error).message}`);
      }
    }
  }

  private async processItem(item: { id: string; reportId: string; attempts: number }, now: Date, policy: RetentionPolicy, summary: RunSummary): Promise<void> {
    const report = await this.prisma.report.findUnique({
      where: { id: item.reportId },
      select: { id: true, surveyId: true, status: true, updatedAt: true, finalisedAt: true, restoredAt: true, survey: { select: { title: true, reportPdfPath: true } }, retention: { select: { graceUntil: true } } },
    });
    if (!report) {
      await this.prisma.reportDeletion.update({ where: { id: item.id }, data: { status: 'DONE', purgedAt: now } });
      return;
    }
    // Re-check at the moment of deleting: a hold, a live link or new activity since the job queued it stops it.
    const hold = await this.prisma.reportLegalHold.count({ where: { reportId: report.id, releasedAt: null } });
    const linkLive = (await this.prisma.editLink.count({ where: { reportId: report.id, status: 'ACTIVE', expiresAt: { gt: now } } })) > 0;
    const state = retentionOf({ status: report.status, updatedAt: report.updatedAt, finalisedAt: report.finalisedAt, restoredAt: report.restoredAt, linkLive }, policy);
    if (!state || !eligible(state, now, { held: hold > 0, graceUntil: report.retention?.graceUntil ?? null, linkLive })) {
      await this.prisma.reportDeletion.delete({ where: { id: item.id } });
      summary.cancelled++;
      return;
    }
    try {
      const files = await this.deleteFiles(report.surveyId, report.survey.reportPdfPath);
      const owner = (await this.prisma.report.findUniqueOrThrow({ where: { id: report.id }, select: { ownerUserId: true } })).ownerUserId;
      await this.prisma.$transaction([
        this.prisma.survey.delete({ where: { id: report.surveyId } }), // the report and everything under it go with it
        this.prisma.reportDeletion.update({ where: { id: item.id }, data: { status: 'DONE', purgedAt: now, filesDeleted: files, attempts: item.attempts + 1, lastError: null } }),
      ]);
      summary.purged++;
      await this.audit.log({
        actorType: ActorType.SYSTEM,
        action: 'REPORT_PURGED',
        entityType: AuditEntityType.REPORT,
        entityId: report.id,
        metadata: { policy: state.kind, anchorAt: state.anchorAt, deleteAt: state.deleteAt, filesDeleted: files },
      });
      await this.notify(owner, NotificationType.REPORT_PURGED, purgedText(report.survey.title, state.kind), false);
    } catch (error) {
      const attempts = item.attempts + 1;
      const giveUp = attempts >= policy.maxAttempts;
      await this.prisma.reportDeletion.update({
        where: { id: item.id },
        data: { attempts, status: giveUp ? 'FAILED' : 'PENDING', nextAttemptAt: new Date(now.getTime() + backoffMinutes(attempts) * 60_000), lastError: String((error as Error).message ?? error).slice(0, 300) },
      });
      if (giveUp) summary.failed++;
      else summary.retrying++;
      this.logger.warn(`Purge of ${item.reportId} failed (attempt ${attempts}): ${(error as Error).message}`);
    }
  }

  /** Files first (spec 15.3 and the job order): each tracked file, then the report's directories, so nothing stray stays behind. */
  private async deleteFiles(surveyId: string, reportPdfPath: string | null): Promise<number> {
    const media = await this.prisma.media.findMany({ where: { surveyId }, select: { storagePath: true } });
    const documents = await this.prisma.reportFile.findMany({ where: { reportId: surveyId }, select: { storagePath: true } });
    let deleted = 0;
    for (const p of [...media.map((m) => m.storagePath), ...documents.map((d) => d.storagePath), ...(reportPdfPath ? [reportPdfPath] : [])]) {
      if (await this.storage.delete(p)) deleted++;
    }
    deleted += await this.storage.deleteDirectory(surveyId);
    deleted += await this.storage.deleteDirectory(`report-files/${surveyId}`);
    return deleted;
  }

  // ------------------------------------------------------------------------------------------------ notices

  /** In the app and, where the user has an address, by e-mail. Neither failing stops the job. */
  private async notify(userId: string, type: NotificationType, text: { title: string; body: string }, email = true): Promise<void> {
    try {
      await this.prisma.notification.create({ data: { type, recipientType: RecipientType.USER, recipientId: userId, title: text.title.slice(0, 255), body: text.body } });
    } catch (error) {
      this.logger.warn(`Could not store the notification: ${(error as Error).message}`);
    }
    if (!email) return;
    try {
      const user = await this.prisma.user.findUnique({ where: { id: userId }, select: { email: true } });
      if (user?.email) await this.email.sendNotice(user.email, text.title, text.body);
    } catch (error) {
      this.logger.warn(`Could not send the e-mail: ${(error as Error).message}`);
    }
  }

  // ------------------------------------------------------------------------------------------------ the owner's view

  private async accessible(user: Owner, reportId: string) {
    const report = await this.prisma.report.findUnique({ where: { id: reportId }, include: { survey: { select: { title: true } }, retention: true } });
    if (!report) throw Errors.notFound();
    if (report.ownerUserId !== user.id && !staff(user)) throw Errors.forbidden();
    return report;
  }

  async view(user: Owner, reportId: string, now: Date = new Date()) {
    const report = await this.accessible(user, reportId);
    const policy = await this.policyNow(now);
    const linkLive = (await this.prisma.editLink.count({ where: { reportId, status: 'ACTIVE', expiresAt: { gt: now } } })) > 0;
    const state = retentionOf({ status: report.status, updatedAt: report.updatedAt, finalisedAt: report.finalisedAt, restoredAt: report.restoredAt, linkLive }, policy);
    const hold = await this.prisma.reportLegalHold.findFirst({ where: { reportId, releasedAt: null } });
    const deletion = await this.prisma.reportDeletion.findUnique({ where: { reportId } });
    const sent = state && report.retention && report.retention.anchorAt.getTime() === state.anchorAt.getTime() ? report.retention.warnedDays : [];
    return {
      reportId,
      status: report.status,
      policy: state?.kind ?? null,
      protectedReason: state ? null : report.status === ReportStatus.FINALISING ? 'FINALISING' : 'REVIEW_IN_PROGRESS',
      anchorAt: state?.anchorAt ?? null,
      deleteAt: hold ? null : state ? this.effectiveDeleteAt(state, report.retention?.graceUntil ?? null) : null,
      daysLeft: hold || !state ? null : daysLeft(this.effectiveDeleteAt(state, report.retention?.graceUntil ?? null), now),
      linkLive,
      warnings: state ? warningDays(state.kind, policy).map((day) => ({ day, sent: sent.includes(day), dueAt: new Date(state.anchorAt.getTime() + day * DAY_MS) })) : [],
      legalHold: hold ? { active: true, reason: hold.reason, placedAt: hold.placedAt, placedByRole: hold.placedByRole } : { active: false },
      graceUntil: report.retention?.graceUntil && report.retention.graceUntil > now ? report.retention.graceUntil : null,
      deletion: deletion ? { status: deletion.status, attempts: deletion.attempts, nextAttemptAt: deletion.nextAttemptAt } : null,
      restoredFromArchive: report.restoredAt !== null,
      policyText: {
        finalisedDays: policy.finalisedDays,
        draftDays: policy.draftDays,
        archive: 'Downloading an archive does not extend or pause the timer. You are responsible for keeping your own long-term record.',
      },
    };
  }

  private effectiveDeleteAt(state: RetentionState, graceUntil: Date | null): Date {
    return graceUntil && graceUntil > state.deleteAt ? graceUntil : state.deleteAt;
  }

  // ------------------------------------------------------------------------------------------------ legal hold

  async placeHold(user: Owner, reportId: string, reason: string, req?: Request) {
    if (!staff(user)) throw Errors.forbidden();
    const report = await this.accessible(user, reportId);
    const existing = await this.prisma.reportLegalHold.findFirst({ where: { reportId, releasedAt: null } });
    if (existing) throw editingError(HttpStatus.CONFLICT, 'INVALID_STATE', 'This report is already under a legal hold');
    let hold;
    try {
      hold = await this.prisma.reportLegalHold.create({ data: { reportId, reason, placedBy: user.id, placedByRole: user.role } });
    } catch (error) {
      if ((error as { code?: string }).code === 'P2002') throw editingError(HttpStatus.CONFLICT, 'INVALID_STATE', 'This report is already under a legal hold');
      throw error;
    }
    // a hold stops anything already queued for deletion
    await this.prisma.reportDeletion.deleteMany({ where: { reportId, status: { in: ['PENDING', 'FAILED'] } } });
    await this.audit.log({
      actorType: ActorType.STAFF,
      actorId: user.id,
      action: 'REPORT_LEGAL_HOLD_PLACED',
      entityType: AuditEntityType.REPORT,
      entityId: reportId,
      metadata: { holdId: hold.id, reason, role: user.role },
      request: req,
    });
    await this.notify(report.ownerUserId, NotificationType.REPORT_LEGAL_HOLD, holdPlacedText(report.survey.title, reason, user.role));
    return { reportId, legalHold: { active: true, reason, placedAt: hold.placedAt, placedByRole: user.role } };
  }

  async releaseHold(user: Owner, reportId: string, reason: string, req?: Request, now: Date = new Date()) {
    if (!staff(user)) throw Errors.forbidden();
    const report = await this.accessible(user, reportId);
    const hold = await this.prisma.reportLegalHold.findFirst({ where: { reportId, releasedAt: null } });
    if (!hold) throw editingError(HttpStatus.CONFLICT, 'INVALID_STATE', 'This report is not under a legal hold');
    const policy = await this.policyNow(now);
    const graceUntil = new Date(now.getTime() + policy.holdReleaseGraceDays * DAY_MS);
    const state = retentionOf({ status: report.status, updatedAt: report.updatedAt, finalisedAt: report.finalisedAt, restoredAt: report.restoredAt, linkLive: false }, policy);
    await this.prisma.$transaction([
      this.prisma.reportLegalHold.update({ where: { id: hold.id }, data: { releasedAt: now, releasedBy: user.id, releaseReason: reason } }),
      // the job may not have tracked this report yet (a hold can be placed before its first run): create its row with the grace
      ...(state
        ? [
            this.prisma.reportRetention.upsert({
              where: { reportId },
              create: { reportId, policy: state.kind, anchorAt: state.anchorAt, deleteAt: state.deleteAt, warnedDays: [], graceUntil },
              update: { graceUntil },
            }),
          ]
        : []),
    ]);
    await this.audit.log({
      actorType: ActorType.STAFF,
      actorId: user.id,
      action: 'REPORT_LEGAL_HOLD_RELEASED',
      entityType: AuditEntityType.REPORT,
      entityId: reportId,
      metadata: { holdId: hold.id, reason, role: user.role, graceUntil },
      request: req,
    });
    const deleteOn = state ? this.effectiveDeleteAt(state, graceUntil) : graceUntil;
    await this.notify(report.ownerUserId, NotificationType.REPORT_LEGAL_HOLD, holdReleasedText(report.survey.title, deleteOn, reason));
    return { reportId, legalHold: { active: false }, notBefore: deleteOn };
  }

  // ------------------------------------------------------------------------------------------------ monitoring

  /** For Admin and Manager (spec 17: monitor purge outcomes): what is coming, what is held, what the queue did. No report content. */
  async overview(user: Owner, now: Date = new Date()) {
    if (!staff(user)) throw Errors.forbidden();
    const since = new Date(now.getTime() - 30 * DAY_MS);
    const [upcoming, holds, pending, failed, done, recent] = await Promise.all([
      this.prisma.reportRetention.findMany({ orderBy: { deleteAt: 'asc' }, take: 20, select: { reportId: true, policy: true, anchorAt: true, deleteAt: true, warnedDays: true } }),
      this.prisma.reportLegalHold.findMany({ where: { releasedAt: null }, orderBy: { placedAt: 'desc' }, select: { reportId: true, reason: true, placedAt: true, placedByRole: true } }),
      this.prisma.reportDeletion.count({ where: { status: 'PENDING' } }),
      this.prisma.reportDeletion.count({ where: { status: 'FAILED' } }),
      this.prisma.reportDeletion.count({ where: { status: 'DONE', purgedAt: { gte: since } } }),
      this.prisma.reportDeletion.findMany({ where: { status: 'DONE' }, orderBy: { purgedAt: 'desc' }, take: 20, select: { reportId: true, policy: true, deleteAt: true, purgedAt: true, filesDeleted: true } }),
    ]);
    return { asOf: now, policy: this.policy, upcoming, holds, queue: { pending, failed, purgedLast30Days: done }, recent };
  }
}

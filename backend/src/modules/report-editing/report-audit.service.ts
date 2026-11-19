import { Injectable } from '@nestjs/common';
import { Prisma, UserRole } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { Errors } from './editing.errors';
import { FieldChange, diffContent } from './report-audit';
import type { ReportContent } from './report-content';
import type { Owner } from './report-editing.service';

type Tx = Prisma.TransactionClient;

export type AuditSource = 'BROWSER' | 'PHONE' | 'RESTORE' | 'AI';

export interface AuditContext {
  reportId: string;
  version: number;
  actor: string; // 'owner:<userId>' | 'session:<sessionId>'
  sessionId?: string;
  /** The unverified display name of a link session. */
  actorName?: string | null;
  source: AuditSource;
}

const LIFECYCLE_ACTIONS = [
  'EDIT_LINK_CREATED', 'EDIT_LINK_CANCELLED', 'EDIT_LINK_REVOKED', 'EDIT_LINK_EXPIRED', 'REPORT_OPENED', 'REPORT_SAVED', 'EDITOR_SESSION_CLOSED',
  'REPORT_SNAPSHOT_UPLOADED', 'REPORT_SYNCHRONISED', 'REPORT_VERSION_RESTORED', 'REPORT_CONFLICT_DETECTED',
  'REVIEW_SUBMITTED', 'REVIEW_STARTED', 'REVIEW_APPROVED', 'REVIEW_AMENDMENTS_REQUIRED', 'REVIEW_RESET', 'REVIEW_INVALIDATED', 'OWNER_APPROVED',
  'REPORT_FINALISED', 'REPORT_REOPENED', 'REPORT_ORIGINAL_FILE_STORED', 'REPORT_FINAL_FILE_STORED',
  'PHOTO_UPLOADED', 'PHOTO_UPDATED', 'PHOTO_REPLACED', 'PHOTO_DELETED', 'PHOTOS_ASSIGNED',
  'AI_SUGGESTION_ACCEPTED', 'AI_SUGGESTION_ACCEPTED_MODIFIED', 'AI_SUGGESTION_REJECTED',
];

/**
 * The amendment history of a report (Remote Editor spec v1.4 sections 10 and 18): who changed which field, from what to what,
 * in which report version. Written inside the save transaction, so an event exists exactly when the change was committed.
 * Rows are append-only (a database trigger refuses UPDATE; DELETE only together with the report).
 */
@Injectable()
export class ReportAuditService {
  constructor(private readonly prisma: PrismaService) {}

  /** Records the difference between two contents as events of [ctx.version]. Returns how many were written. */
  async recordChanges(tx: Tx, ctx: AuditContext, before: ReportContent, after: ReportContent): Promise<number> {
    const changes = diffContent(before, after);
    if (changes.length === 0) return 0;
    await tx.reportAuditEvent.createMany({ data: changes.map((c) => this.row(ctx, c)) });
    return changes.length;
  }

  /** One event that is not a field change (the first upload of the report, an AI suggestion that was accepted or rejected). */
  async recordNote(tx: Tx | PrismaService, ctx: AuditContext, note: { entityType: string; entityId?: string; field: string; op: string; after?: unknown }): Promise<void> {
    await tx.reportAuditEvent.create({
      data: {
        reportId: ctx.reportId,
        reportVersion: ctx.version,
        entityType: note.entityType,
        entityId: note.entityId ?? null,
        field: note.field,
        op: note.op,
        afterValue: (note.after ?? Prisma.JsonNull) as Prisma.InputJsonValue,
        actor: ctx.actor,
        actorName: ctx.actorName ?? null,
        sessionId: ctx.sessionId ?? null,
        source: ctx.source,
      },
    });
  }

  private row(ctx: AuditContext, c: FieldChange): Prisma.ReportAuditEventCreateManyInput {
    return {
      reportId: ctx.reportId,
      reportVersion: ctx.version,
      entityType: c.entityType,
      entityId: c.entityId,
      sectionId: c.sectionId,
      sectionKey: c.sectionKey,
      field: c.field,
      op: c.op,
      beforeValue: (c.before ?? Prisma.JsonNull) as Prisma.InputJsonValue,
      afterValue: (c.after ?? Prisma.JsonNull) as Prisma.InputJsonValue,
      actor: ctx.actor,
      actorName: ctx.actorName ?? null,
      sessionId: ctx.sessionId ?? null,
      source: ctx.source,
    };
  }

  /**
   * What changed in the report after [sinceVersion] (spec v1.4 sections 10 and 17): the version and status now, and the sections
   * and blocks that were amended, from the amendment history. A phone or a browser asks this to know whether it is behind and
   * where, without downloading the report.
   */
  async changesSince(reportId: string, sinceVersion: number) {
    const report = await this.prisma.report.findUnique({ where: { id: reportId }, select: { version: true, status: true, content: true } });
    if (!report) throw Errors.notFound();
    const events = await this.prisma.reportAuditEvent.findMany({
      where: { reportId, reportVersion: { gt: sinceVersion } },
      orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
      select: { reportVersion: true, entityType: true, entityId: true, sectionId: true, sectionKey: true, field: true, op: true, source: true },
    });
    const titles = new Map<string, string>((report.content as unknown as ReportContent).map((s) => [s.id, s.title]));
    const sections = new Map<string, { sectionId: string; sectionKey: string | null; title: string | null; blockIds: Set<string>; fields: Set<string> }>();
    for (const e of events) {
      if (!e.sectionId || e.entityType === 'REPORT' || e.entityType === 'AI') continue;
      const s = sections.get(e.sectionId) ?? { sectionId: e.sectionId, sectionKey: e.sectionKey, title: titles.get(e.sectionId) ?? null, blockIds: new Set<string>(), fields: new Set<string>() };
      if (e.entityType === 'BLOCK' && e.entityId) s.blockIds.add(e.entityId);
      s.fields.add(e.field);
      sections.set(e.sectionId, s);
    }
    return {
      reportId,
      version: report.version,
      status: report.status,
      sinceVersion,
      changed: report.version > sinceVersion,
      fromPhone: events.some((e) => e.source === 'PHONE'),
      fromBrowser: events.some((e) => e.source === 'BROWSER'),
      restored: events.some((e) => e.source === 'RESTORE'),
      sections: [...sections.values()].map((s) => ({ sectionId: s.sectionId, sectionKey: s.sectionKey, title: s.title, blockIds: [...s.blockIds], fields: [...s.fields] })),
    };
  }

  /** The owner (or an admin) reads the history: field amendments, oldest first, and the lifecycle events of the report. */
  async read(user: Owner, reportId: string, q: { sinceVersion?: number; limit?: number }) {
    const report = await this.prisma.report.findUnique({ where: { id: reportId } });
    if (!report) throw Errors.notFound();
    if (report.ownerUserId !== user.id && user.role !== UserRole.ADMIN) throw Errors.forbidden();
    const limit = Math.min(Math.max(q.limit ?? 200, 1), 500);
    const events = await this.prisma.reportAuditEvent.findMany({
      where: { reportId, ...(q.sinceVersion !== undefined ? { reportVersion: { gt: q.sinceVersion } } : {}) },
      orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
      take: limit,
    });
    const lifecycle = await this.prisma.auditLog.findMany({
      where: { entityId: reportId, action: { in: LIFECYCLE_ACTIONS } },
      orderBy: { createdAt: 'asc' },
      take: limit,
      select: { action: true, actorType: true, actorId: true, createdAt: true, metadata: true },
    });
    return {
      reportId,
      events: events.map((e) => ({
        id: e.id,
        version: e.reportVersion,
        entityType: e.entityType,
        entityId: e.entityId,
        sectionKey: e.sectionKey,
        field: e.field,
        op: e.op,
        before: e.beforeValue,
        after: e.afterValue,
        actor: e.actor,
        actorName: e.actorName,
        actorNameVerified: false,
        source: e.source,
        at: e.createdAt,
      })),
      lifecycle,
    };
  }
}

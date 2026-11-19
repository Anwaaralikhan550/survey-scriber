import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ActorType, AuditEntityType, EditLinkStatus, Prisma, ReportStatus, UserRole } from '@prisma/client';
import { Request } from 'express';
import { PrismaService } from '../prisma/prisma.service';
import { AuditService } from '../audit/audit.service';
import { OriginalSnapshotService } from './original-snapshot.service';
import { ReportAuditService } from './report-audit.service';
import { ContentValidationError, ReportContent, cleanContent } from './report-content';
import { Errors } from './editing.errors';
import { newToken } from './token.util';
import { invalidateApprovalsAfterChange } from './review-effects';

export interface Owner {
  id: string;
  role: UserRole;
}

type Tx = Prisma.TransactionClient;

const LOCKED: ReportStatus[] = [ReportStatus.FINALISING, ReportStatus.FINALISED];

/**
 * Owner side of desktop editing: the cloud report, its edit link and its version history.
 * One report per survey (the report id is the survey id). Every committed write raises report.version.
 */
@Injectable()
export class ReportEditingService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
    private readonly audit: AuditService,
    private readonly originals: OriginalSnapshotService,
    private readonly fieldAudit: ReportAuditService,
  ) {}

  private get linkTtlHours(): number {
    return Number(this.config.get('EDITOR_LINK_TTL_HOURS', 72));
  }

  private get editorBaseUrl(): string {
    return String(this.config.get('EDITOR_BASE_URL', 'http://localhost:5174')).replace(/\/+$/, '');
  }

  /** The owner (or an admin) of the survey. Anyone else gets FORBIDDEN, a missing survey NOT_FOUND. */
  private async assertSurveyOwner(surveyId: string, user: Owner) {
    const survey = await this.prisma.survey.findUnique({ where: { id: surveyId } });
    if (!survey || survey.deletedAt) throw Errors.notFound();
    if (survey.userId !== user.id && user.role !== UserRole.ADMIN) throw Errors.forbidden();
    return survey;
  }

  private async assertReportOwner(reportId: string, user: Owner) {
    const report = await this.prisma.report.findUnique({ where: { id: reportId } });
    if (!report) throw Errors.notFound();
    if (report.ownerUserId !== user.id && user.role !== UserRole.ADMIN) throw Errors.forbidden();
    return report;
  }

  private async lockReport(tx: Tx, reportId: string): Promise<{ version: number; status: ReportStatus }> {
    const rows = await tx.$queryRaw<{ version: number; status: ReportStatus }[]>`
      SELECT version, status FROM reports WHERE id = ${reportId}::uuid FOR UPDATE`;
    if (rows.length === 0) throw Errors.notFound();
    return rows[0];
  }

  private log(action: string, user: Owner, reportId: string, req: Request | undefined, metadata: Record<string, unknown>) {
    return this.audit.log({
      actorType: ActorType.STAFF,
      actorId: user.id,
      action,
      entityType: AuditEntityType.REPORT,
      entityId: reportId,
      metadata,
      request: req,
    });
  }

  /**
   * The phone uploads the structured report. First upload creates the report (version 1).
   * Later uploads must name the cloud version they were based on, so stale phone data never overwrites newer cloud edits.
   */
  async uploadSnapshot(
    user: Owner,
    surveyId: string,
    dto: { baseVersion?: number; reportType: string; content: unknown; treeVersionId?: string; phraseBankVersionId?: string; generatedAt?: string; appVersion?: string },
    req?: Request,
  ) {
    const survey = await this.assertSurveyOwner(surveyId, user);
    let content: ReportContent;
    try {
      content = cleanContent(dto.content);
    } catch (e) {
      if (e instanceof ContentValidationError) throw Errors.validation(e.message, e.path);
      throw e;
    }
    const result = await this.prisma.$transaction(async (tx) => {
      const existing = await tx.report.findUnique({ where: { id: surveyId } });
      if (!existing) {
        if (dto.baseVersion !== undefined && dto.baseVersion !== 0) throw Errors.conflict(0);
        const created = await tx.report.create({
          data: {
            id: surveyId,
            surveyId,
            ownerUserId: survey.userId,
            reportType: dto.reportType,
            content: content as unknown as Prisma.InputJsonValue,
          },
        });
        await tx.reportVersion.create({
          data: { reportId: surveyId, version: 1, content: content as unknown as Prisma.InputJsonValue, savedBy: `owner:${user.id}`, reason: 'SNAPSHOT' },
        });
        // The first upload is the original report: kept apart and never changed (spec v1.4 section 5.1).
        await this.originals.capture(tx, {
          reportId: surveyId,
          userId: user.id,
          reportType: dto.reportType,
          content,
          meta: { treeVersionId: dto.treeVersionId, phraseBankVersionId: dto.phraseBankVersionId, generatedAt: dto.generatedAt, appVersion: dto.appVersion },
        });
        await this.fieldAudit.recordNote(tx, { reportId: surveyId, version: created.version, actor: `owner:${user.id}`, source: 'PHONE' }, {
          entityType: 'REPORT',
          field: 'original',
          op: 'ORIGINAL',
          after: { sections: content.length, blocks: content.reduce((n, s) => n + s.blocks.length, 0) },
        });
        return { version: created.version, updatedAt: created.updatedAt, created: true, invalidated: false };
      }
      const locked = await this.lockReport(tx, surveyId);
      if (LOCKED.includes(locked.status)) throw Errors.finalised();
      if (dto.baseVersion !== locked.version) throw Errors.conflict(locked.version);
      const next = locked.version + 1;
      await this.fieldAudit.recordChanges(tx, { reportId: surveyId, version: next, actor: `owner:${user.id}`, source: 'PHONE' }, existing.content as unknown as ReportContent, content);
      const updated = await tx.report.update({
        where: { id: surveyId },
        data: { content: content as unknown as Prisma.InputJsonValue, version: next, reportType: dto.reportType },
      });
      await tx.reportVersion.create({
        data: { reportId: surveyId, version: next, content: content as unknown as Prisma.InputJsonValue, savedBy: `owner:${user.id}`, reason: 'SNAPSHOT' },
      });
      const invalidated = (await invalidateApprovalsAfterChange(tx, surveyId, locked.status)) !== null;
      return { version: next, updatedAt: updated.updatedAt, created: false, invalidated };
    });
    await this.log('REPORT_SNAPSHOT_UPLOADED', user, surveyId, req, { version: result.version, created: result.created });
    if (result.invalidated) await this.log('REVIEW_INVALIDATED', user, surveyId, req, { version: result.version, cause: 'new upload from the phone' });
    return { reportId: surveyId, version: result.version, updatedAt: result.updatedAt };
  }

  /** Spec section 5.2. One live link per report, decided inside a transaction on the locked report row. */
  async createLink(user: Owner, reportId: string, req?: Request) {
    await this.assertReportOwner(reportId, user);
    const raw = newToken();
    const expiresAt = new Date(Date.now() + this.linkTtlHours * 3600 * 1000);
    const link = await this.prisma.$transaction(async (tx) => {
      const locked = await this.lockReport(tx, reportId);
      if (LOCKED.includes(locked.status)) throw Errors.finalised();
      const active = await tx.editLink.findFirst({ where: { reportId, status: EditLinkStatus.ACTIVE } });
      if (active && active.expiresAt > new Date()) throw Errors.activeLinkExists();
      if (active) {
        await tx.editLink.update({ where: { id: active.id }, data: { status: EditLinkStatus.EXPIRED, endedAt: new Date() } });
      }
      await tx.editorSession.updateMany({ where: { reportId, revokedAt: null }, data: { revokedAt: new Date() } });
      const created = await tx.editLink.create({
        data: { reportId, tokenHash: raw.hash, createdBy: user.id, expiresAt },
      });
      await tx.report.update({ where: { id: reportId }, data: { activeEditLinkId: created.id } });
      return created;
    });
    await this.log('EDIT_LINK_CREATED', user, reportId, req, { linkId: link.id, expiresAt });
    return {
      linkId: link.id,
      url: `${this.editorBaseUrl}/open/${raw.raw}`,
      expiresAt: link.expiresAt,
      policy: 'single-live-link',
    };
  }

  /** Owner cancels; an admin who is not the owner revokes. Either way the link and its sessions stop at once. */
  async cancelLink(user: Owner, reportId: string, linkId: string, req?: Request) {
    const report = await this.assertReportOwner(reportId, user);
    const status = report.ownerUserId === user.id ? EditLinkStatus.CANCELLED : EditLinkStatus.REVOKED;
    await this.prisma.$transaction(async (tx) => {
      await this.lockReport(tx, reportId);
      const link = await tx.editLink.findFirst({ where: { id: linkId, reportId } });
      if (!link) throw Errors.notFound();
      if (link.status !== EditLinkStatus.ACTIVE) throw Errors.linkRevoked();
      await tx.editLink.update({ where: { id: linkId }, data: { status, endedAt: new Date() } });
      await tx.editorSession.updateMany({ where: { linkId, revokedAt: null }, data: { revokedAt: new Date() } });
      await tx.report.update({ where: { id: reportId }, data: { activeEditLinkId: null } });
    });
    await this.log(status === EditLinkStatus.CANCELLED ? 'EDIT_LINK_CANCELLED' : 'EDIT_LINK_REVOKED', user, reportId, req, { linkId });
    return { linkId, status };
  }

  /** The link that is live right now (for the app's Copy / Share / Cancel buttons). Never returns the token. */
  async currentLink(user: Owner, reportId: string) {
    await this.assertReportOwner(reportId, user);
    const link = await this.prisma.editLink.findFirst({ where: { reportId, status: EditLinkStatus.ACTIVE }, orderBy: { createdAt: 'desc' } });
    if (!link) return { active: false };
    if (link.expiresAt <= new Date()) {
      await this.prisma.editLink.update({ where: { id: link.id }, data: { status: EditLinkStatus.EXPIRED, endedAt: new Date() } });
      return { active: false };
    }
    return { active: true, linkId: link.id, createdAt: link.createdAt, expiresAt: link.expiresAt };
  }

  async latest(user: Owner, reportId: string) {
    const r = await this.assertReportOwner(reportId, user);
    return { reportId, version: r.version, status: r.status, updatedAt: r.updatedAt };
  }

  /** Spec section 12: the owner fetches the canonical report and version to replace the phone's working copy. */
  async sync(user: Owner, reportId: string, req?: Request) {
    const r = await this.assertReportOwner(reportId, user);
    await this.log('REPORT_SYNCHRONISED', user, reportId, req, { version: r.version });
    return { reportId, version: r.version, status: r.status, updatedAt: r.updatedAt, reportType: r.reportType, content: r.content };
  }

  async listVersions(user: Owner, reportId: string) {
    await this.assertReportOwner(reportId, user);
    const rows = await this.prisma.reportVersion.findMany({
      where: { reportId },
      orderBy: { version: 'desc' },
      select: { version: true, savedBy: true, savedByName: true, reason: true, createdAt: true },
    });
    return { reportId, versions: rows };
  }

  /** Recover an earlier version. It is written as a NEW version on top, so nothing in the history is lost. */
  async restoreVersion(user: Owner, reportId: string, version: number, baseVersion: number, req?: Request) {
    await this.assertReportOwner(reportId, user);
    const old = await this.prisma.reportVersion.findUnique({ where: { reportId_version: { reportId, version } } });
    if (!old) throw Errors.notFound();
    const out = await this.prisma.$transaction(async (tx) => {
      const locked = await this.lockReport(tx, reportId);
      if (LOCKED.includes(locked.status)) throw Errors.finalised();
      if (baseVersion !== locked.version) throw Errors.conflict(locked.version);
      const next = locked.version + 1;
      const current = await tx.report.findUniqueOrThrow({ where: { id: reportId }, select: { content: true } });
      await this.fieldAudit.recordChanges(tx, { reportId, version: next, actor: `owner:${user.id}`, source: 'RESTORE' }, current.content as unknown as ReportContent, old.content as unknown as ReportContent);
      await tx.report.update({ where: { id: reportId }, data: { content: old.content as Prisma.InputJsonValue, version: next } });
      await tx.reportVersion.create({
        data: { reportId, version: next, content: old.content as Prisma.InputJsonValue, savedBy: `owner:${user.id}`, reason: 'RESTORE' },
      });
      const invalidated = (await invalidateApprovalsAfterChange(tx, reportId, locked.status)) !== null;
      return { next, invalidated };
    });
    await this.log('REPORT_VERSION_RESTORED', user, reportId, req, { restoredFrom: version, version: out.next });
    if (out.invalidated) await this.log('REVIEW_INVALIDATED', user, reportId, req, { version: out.next, cause: 'restore' });
    return { reportId, version: out.next, restoredFrom: version };
  }
}

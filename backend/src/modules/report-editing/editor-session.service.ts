import { HttpException, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ActorType, AuditEntityType, EditLink, EditLinkStatus, EditorSession, Prisma, Report, ReportStatus } from '@prisma/client';
import { Request } from 'express';
import { PrismaService } from '../prisma/prisma.service';
import { AuditService } from '../audit/audit.service';
import { ReportAuditService } from './report-audit.service';
import { ContentValidationError, ReportContent, applyChanges } from './report-content';
import { Errors } from './editing.errors';
import { newToken, safeEqualHex, sha256 } from './token.util';
import { invalidateApprovalsAfterChange } from './review-effects';

const LOCKED: ReportStatus[] = [ReportStatus.FINALISING, ReportStatus.FINALISED];

export interface EditorContext {
  session: EditorSession;
  link: EditLink;
  report: Report;
  /** true when the link has expired or the report is finalised: the browser may read but not write. */
  readOnly: boolean;
  readOnlyReason?: 'LINK_EXPIRED' | 'REPORT_FINALISED';
}

/**
 * Browser side: a link token is exchanged for a short-lived session, and every read/write
 * is checked against the live link, the session and the report version on the server.
 */
@Injectable()
export class EditorSessionService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
    private readonly audit: AuditService,
    private readonly fieldAudit: ReportAuditService,
  ) {}

  private get sessionMinutes(): number {
    return Number(this.config.get('EDITOR_SESSION_MINUTES', 120));
  }

  private log(action: string, reportId: string, req: Request | undefined, metadata: Record<string, unknown>) {
    return this.audit.log({
      actorType: ActorType.SYSTEM,
      action,
      entityType: AuditEntityType.REPORT,
      entityId: reportId,
      metadata,
      request: req,
    });
  }

  /**
   * Spec 5.3: token -> session. Wrong, expired, cancelled or revoked tokens return a safe message
   * and no report content. The raw token is never logged or stored.
   */
  async open(rawToken: string, req?: Request) {
    const link = await this.prisma.editLink.findUnique({ where: { tokenHash: sha256(rawToken) }, include: { report: true } });
    if (!link) throw Errors.linkInvalid();
    // A finalised report is closed for good: say so, whatever happened to the link.
    if (LOCKED.includes(link.report.status)) throw Errors.finalised();
    if (link.status === EditLinkStatus.ACTIVE && link.expiresAt <= new Date()) {
      await this.prisma.editLink.update({ where: { id: link.id }, data: { status: EditLinkStatus.EXPIRED, endedAt: new Date() } });
      await this.log('EDIT_LINK_EXPIRED', link.reportId, req, { linkId: link.id });
      throw Errors.linkExpired();
    }
    if (link.status === EditLinkStatus.EXPIRED) throw Errors.linkExpired();
    if (link.status !== EditLinkStatus.ACTIVE) throw Errors.linkRevoked();

    const cookie = newToken();
    const csrf = newToken();
    const expiresAt = new Date(Math.min(Date.now() + this.sessionMinutes * 60000, link.expiresAt.getTime()));
    const session = await this.prisma.editorSession.create({
      data: { reportId: link.reportId, linkId: link.id, sessionHash: cookie.hash, csrfHash: csrf.hash, expiresAt },
    });
    await this.log('REPORT_OPENED', link.reportId, req, { linkId: link.id, sessionId: session.id });
    return {
      cookieValue: cookie.raw,
      csrfToken: csrf.raw,
      sessionExpiresAt: session.expiresAt,
      linkExpiresAt: link.expiresAt,
      reportId: link.reportId,
    };
  }

  /**
   * Resolve the cookie to a live context. Cancelled/revoked/invalidated links cut the session at once.
   * An expired link or a finalised report leaves a read-only session until the session itself ends.
   */
  async authenticate(cookieValue: string | undefined): Promise<EditorContext> {
    if (!cookieValue) throw Errors.linkInvalid();
    const session = await this.prisma.editorSession.findUnique({
      where: { sessionHash: sha256(cookieValue) },
      include: { link: true, report: true },
    });
    if (!session) throw Errors.linkInvalid();
    if (session.revokedAt && (session.link.status === EditLinkStatus.CANCELLED || session.link.status === EditLinkStatus.REVOKED || session.link.status === EditLinkStatus.INVALIDATED)) {
      // Finalising ends every link on purpose: say that, not that the link was cancelled.
      throw LOCKED.includes(session.report.status) ? Errors.finalised() : Errors.linkRevoked();
    }
    if (session.revokedAt || session.expiresAt <= new Date()) throw Errors.linkInvalid();
    const { link, report } = session;
    if (link.status !== EditLinkStatus.ACTIVE && link.status !== EditLinkStatus.EXPIRED) throw Errors.linkRevoked();

    let readOnlyReason: EditorContext['readOnlyReason'];
    if (LOCKED.includes(report.status)) readOnlyReason = 'REPORT_FINALISED';
    else if (link.status === EditLinkStatus.EXPIRED || link.expiresAt <= new Date()) readOnlyReason = 'LINK_EXPIRED';
    if (readOnlyReason === 'LINK_EXPIRED' && link.status === EditLinkStatus.ACTIVE) {
      await this.prisma.editLink.update({ where: { id: link.id }, data: { status: EditLinkStatus.EXPIRED, endedAt: new Date() } });
    }
    await this.prisma.editorSession.update({ where: { id: session.id }, data: { lastSeenAt: new Date() } });
    return { session, link, report, readOnly: readOnlyReason !== undefined, readOnlyReason };
  }

  verifyCsrf(ctx: EditorContext, header: string | undefined): void {
    if (!header || !safeEqualHex(sha256(header), ctx.session.csrfHash)) throw Errors.csrf();
  }

  async read(ctx: EditorContext, reportId: string) {
    if (ctx.report.id !== reportId) throw Errors.forbidden();
    const r = await this.prisma.report.findUniqueOrThrow({ where: { id: reportId }, include: { survey: { select: { title: true, propertyAddress: true, jobRef: true } } } });
    return {
      reportId,
      reportType: r.reportType,
      property: { title: r.survey.title, address: r.survey.propertyAddress, jobRef: r.survey.jobRef },
      status: r.status,
      version: r.version,
      updatedAt: r.updatedAt,
      linkExpiresAt: ctx.link.expiresAt,
      readOnly: ctx.readOnly,
      readOnlyReason: ctx.readOnlyReason ?? null,
      content: r.content,
    };
  }

  /** Inside a write transaction: the link must still be live and the session not ended. */
  async assertWritable(tx: Prisma.TransactionClient, ctx: EditorContext): Promise<void> {
    const link = await tx.editLink.findUnique({ where: { id: ctx.link.id } });
    if (!link || link.status !== EditLinkStatus.ACTIVE || link.expiresAt <= new Date()) throw Errors.linkExpired();
    const live = await tx.editorSession.findUnique({ where: { id: ctx.session.id } });
    if (!live || live.revokedAt) throw Errors.linkRevoked();
  }

  /** Screen G exit: end this browser session now. The link itself stays usable for the next colleague. */
  async close(ctx: EditorContext, req?: Request) {
    await this.prisma.editorSession.update({ where: { id: ctx.session.id }, data: { revokedAt: new Date() } });
    await this.log('EDITOR_SESSION_CLOSED', ctx.report.id, req, { sessionId: ctx.session.id, linkId: ctx.link.id });
    return { closed: true };
  }

  /** Spec 10 and 11: version-checked, idempotent, all-or-nothing save. */
  async save(ctx: EditorContext, reportId: string, dto: { baseVersion: number; changes: unknown; idempotencyKey?: string }, req?: Request) {
    if (ctx.report.id !== reportId) throw Errors.forbidden();
    if (ctx.readOnly) throw ctx.readOnlyReason === 'REPORT_FINALISED' ? Errors.finalised() : Errors.linkExpired();

    if (dto.idempotencyKey) {
      const done = await this.prisma.reportVersion.findUnique({
        where: { reportId_idempotencyKey: { reportId, idempotencyKey: dto.idempotencyKey } },
      });
      if (done) return { reportId, version: done.version, savedAt: done.createdAt, replayed: true };
    }

    let result: { version: number; savedAt: Date; invalidated: boolean };
    try {
      result = await this.prisma.$transaction(async (tx) => {
        const rows = await tx.$queryRaw<{ version: number; status: ReportStatus; content: unknown }[]>`
          SELECT version, status, content FROM reports WHERE id = ${reportId}::uuid FOR UPDATE`;
        if (rows.length === 0) throw Errors.notFound();
        const cur = rows[0];
        if (LOCKED.includes(cur.status)) throw Errors.finalised();
        await this.assertWritable(tx, ctx);
        if (dto.baseVersion !== cur.version) throw Errors.conflict(cur.version);
        const next = applyChanges(cur.content as ReportContent, dto.changes);
        const version = cur.version + 1;
        await this.fieldAudit.recordChanges(tx, { reportId, version, actor: `session:${ctx.session.id}`, sessionId: ctx.session.id, source: 'BROWSER' }, cur.content as ReportContent, next);
        await tx.report.update({ where: { id: reportId }, data: { content: next as unknown as Prisma.InputJsonValue, version } });
        const row = await tx.reportVersion.create({
          data: {
            reportId,
            version,
            content: next as unknown as Prisma.InputJsonValue,
            savedBy: `session:${ctx.session.id}`,
            reason: 'SAVE',
            idempotencyKey: dto.idempotencyKey,
          },
        });
        const invalidated = (await invalidateApprovalsAfterChange(tx, reportId, cur.status)) !== null;
        return { version, savedAt: row.createdAt, invalidated };
      });
    } catch (e) {
      if (e instanceof ContentValidationError) throw Errors.validation(e.message, e.path);
      if (e instanceof HttpException && (e.getResponse() as { error?: string }).error === 'VERSION_CONFLICT') {
        await this.log('REPORT_CONFLICT_DETECTED', reportId, req, { sessionId: ctx.session.id, baseVersion: dto.baseVersion });
      }
      throw e;
    }
    await this.log('REPORT_SAVED', reportId, req, { sessionId: ctx.session.id, linkId: ctx.link.id, version: result.version });
    if (result.invalidated) await this.log('REVIEW_INVALIDATED', reportId, req, { sessionId: ctx.session.id, version: result.version });
    return { reportId, version: result.version, savedAt: result.savedAt, replayed: false };
  }
}

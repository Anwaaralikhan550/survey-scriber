import { HttpStatus, Injectable } from '@nestjs/common';
import { ActorType, AuditEntityType, EditLinkStatus, Prisma, ReportStatus, ReviewDecision, UserRole } from '@prisma/client';
import { Request } from 'express';
import { PrismaService } from '../prisma/prisma.service';
import { AuditService } from '../audit/audit.service';
import { Errors, editingError } from './editing.errors';
import { sanitizeText } from './report-content';
import type { Owner } from './report-editing.service';

/**
 * Finalise and reopen (client spec v1.3 sections 15 and 22, D0 decision d). Only the owner does either.
 * Finalising locks the exact version the owner approved and ends every link and browser session.
 * Reopening is explicit: it starts a new edit cycle and keeps the earlier final version on record with who reopened it and why.
 */
@Injectable()
export class FinalisationService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
  ) {}

  private async assertOwner(reportId: string, user: Owner) {
    const report = await this.prisma.report.findUnique({ where: { id: reportId } });
    if (!report) throw Errors.notFound();
    if (report.ownerUserId !== user.id && user.role !== UserRole.ADMIN) throw Errors.forbidden();
    return report;
  }

  private invalid(message: string, status: ReportStatus) {
    return editingError(HttpStatus.CONFLICT, 'INVALID_STATE', message, { status });
  }

  async finalise(user: Owner, reportId: string, expectedVersion: number, req?: Request) {
    await this.assertOwner(reportId, user);
    const out = await this.prisma.$transaction(async (tx) => {
      const rows = await tx.$queryRaw<{ version: number; status: ReportStatus; edit_cycle: number }[]>`
        SELECT version, status, edit_cycle FROM reports WHERE id = ${reportId}::uuid FOR UPDATE`;
      if (rows.length === 0) throw Errors.notFound();
      const cur = rows[0];
      if (cur.status === ReportStatus.FINALISED || cur.status === ReportStatus.FINALISING) throw this.invalid('This report is already finalised.', cur.status);
      if (cur.version !== expectedVersion) throw Errors.conflict(cur.version);
      if (cur.status !== ReportStatus.OWNER_FINAL_APPROVAL) throw this.invalid('Give final approval to this version first. Only an approved version can be finalised.', cur.status);
      const approval = await tx.review.findFirst({ where: { reportId, decision: ReviewDecision.OWNER_APPROVED, invalidatedAt: null, version: cur.version } });
      if (!approval) throw this.invalid('The final approval no longer stands for this version. Approve it again.', cur.status);

      const now = new Date();
      await tx.report.update({ where: { id: reportId }, data: { status: ReportStatus.FINALISED, finalisedAt: now, finalVersion: cur.version, activeEditLinkId: null } });
      await tx.reportFinalisation.create({ data: { reportId, cycle: cur.edit_cycle, version: cur.version, finalisedBy: user.id, finalisedAt: now } });
      const links = await tx.editLink.updateMany({ where: { reportId, status: EditLinkStatus.ACTIVE }, data: { status: EditLinkStatus.INVALIDATED, endedAt: now } });
      const sessions = await tx.editorSession.updateMany({ where: { reportId, revokedAt: null }, data: { revokedAt: now } });
      return { version: cur.version, cycle: cur.edit_cycle, finalisedAt: now, links: links.count, sessions: sessions.count };
    });
    await this.log('REPORT_FINALISED', user, reportId, req, { version: out.version, cycle: out.cycle, linksEnded: out.links, sessionsEnded: out.sessions });
    return { status: ReportStatus.FINALISED, version: out.version, cycle: out.cycle, finalVersion: out.version, finalisedAt: out.finalisedAt };
  }

  async reopen(user: Owner, reportId: string, expectedVersion: number, reasonRaw: string, req?: Request) {
    await this.assertOwner(reportId, user);
    const reason = sanitizeText(reasonRaw ?? '').trim();
    if (reason.length < 3) throw Errors.validation('Please say why you are reopening the report', 'reason');
    if (reason.length > 500) throw Errors.validation('The reason is longer than 500 characters', 'reason');

    const out = await this.prisma.$transaction(async (tx) => {
      const rows = await tx.$queryRaw<{ version: number; status: ReportStatus; edit_cycle: number }[]>`
        SELECT version, status, edit_cycle FROM reports WHERE id = ${reportId}::uuid FOR UPDATE`;
      if (rows.length === 0) throw Errors.notFound();
      const cur = rows[0];
      if (cur.status !== ReportStatus.FINALISED) throw this.invalid('Only a finalised report can be reopened.', cur.status);
      if (cur.version !== expectedVersion) throw Errors.conflict(cur.version);

      const now = new Date();
      await tx.reportFinalisation.update({
        where: { reportId_cycle: { reportId, cycle: cur.edit_cycle } },
        data: { reopenedAt: now, reopenedBy: user.id, reopenReason: reason },
      });
      // The new cycle starts from the final text, as a draft, with no approval carried over.
      // finalVersion keeps pointing at the last final version until the next one is made.
      await tx.review.updateMany({
        where: { reportId, invalidatedAt: null, decision: { in: [ReviewDecision.APPROVED, ReviewDecision.OWNER_APPROVED] } },
        data: { invalidatedAt: now },
      });
      await tx.report.update({ where: { id: reportId }, data: { status: ReportStatus.DRAFT, editCycle: cur.edit_cycle + 1, finalisedAt: null } });
      return { version: cur.version, from: cur.edit_cycle, to: cur.edit_cycle + 1 };
    });
    await this.log('REPORT_REOPENED', user, reportId, req, { version: out.version, fromCycle: out.from, toCycle: out.to, reasonLength: reason.length });
    return { status: ReportStatus.DRAFT, version: out.version, cycle: out.to, previousFinalVersion: out.version };
  }

  /** Every edit cycle that reached a final version, newest first, and where the report stands now. */
  async history(user: Owner, reportId: string) {
    const r = await this.assertOwner(reportId, user);
    const rows = await this.prisma.reportFinalisation.findMany({ where: { reportId }, orderBy: { cycle: 'desc' } });
    return {
      status: r.status,
      version: r.version,
      cycle: r.editCycle,
      finalVersion: r.finalVersion,
      finalisedAt: r.finalisedAt,
      finalisations: rows.map((f) => ({
        cycle: f.cycle,
        version: f.version,
        finalisedAt: f.finalisedAt,
        reopenedAt: f.reopenedAt,
        reopenReason: f.reopenReason,
      })),
    };
  }

  private log(action: string, user: Owner, reportId: string, req: Request | undefined, metadata: Prisma.InputJsonObject) {
    return this.audit.log({ actorType: ActorType.STAFF, actorId: user.id, action, entityType: AuditEntityType.REPORT, entityId: reportId, metadata, request: req });
  }
}

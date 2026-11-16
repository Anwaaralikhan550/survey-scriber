import { HttpStatus, Injectable } from '@nestjs/common';
import { ActorType, AuditEntityType, Prisma, ReportStatus, ReviewDecision } from '@prisma/client';
import { Request } from 'express';
import { PrismaService } from '../prisma/prisma.service';
import { AuditService } from '../audit/audit.service';
import { EditorContext, EditorSessionService } from './editor-session.service';
import { Errors, editingError } from './editing.errors';
import { sanitizeText } from './report-content';

const FINAL: ReportStatus[] = [ReportStatus.FINALISING, ReportStatus.FINALISED];

export type ReviewActor = { kind: 'owner'; userId: string } | { kind: 'session'; ctx: EditorContext };
export type ReviewAction = 'submit' | 'start' | 'approve' | 'amend' | 'ownerApprove' | 'reset';

export interface ReviewDto {
  expectedVersion: number;
  comment?: string | null;
}

const COMMENT_MAX = 2000;

/**
 * Review workflow of the editable report (client spec section 14, Screen F). Status changes happen only here,
 * on the locked report row, by role: a link holder may submit, start a review and decide as reviewer; only the owner
 * may give the final approval or reset. Every decision names the exact report version it was made on, and any
 * later content change invalidates approvals (see review-effects.ts), so an approval always belongs to what was read.
 */
@Injectable()
export class ReviewService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly sessions: EditorSessionService,
  ) {}

  /** Status, who decided what on which version, and whether each approval still stands. */
  async view(reportId: string, forOwner = false) {
    const report = await this.prisma.report.findUnique({ where: { id: reportId }, select: { status: true, version: true, editCycle: true, finalVersion: true, finalisedAt: true } });
    if (!report) throw Errors.notFound();
    const rows = await this.prisma.review.findMany({ where: { reportId }, orderBy: { createdAt: 'desc' }, take: 50 });
    const reviews = rows.map((r) => ({
      id: r.id,
      decision: r.decision,
      comment: r.comment,
      version: r.version,
      by: r.reviewerUserId ? 'owner' : 'reviewer',
      createdAt: r.createdAt,
      invalidated: r.invalidatedAt !== null,
    }));
    const live = (d: ReviewDecision) => reviews.find((r) => r.decision === d && !r.invalidated) ?? null;
    const submitted = rows.find((r) => r.decision === ReviewDecision.SUBMITTED);
    // The owner also sees which edit round this is and every earlier final version with the reason it was reopened. Link holders do not.
    const finalisation = forOwner
      ? {
          cycle: report.editCycle,
          finalVersion: report.finalVersion,
          finalisedAt: report.finalisedAt,
          history: (await this.prisma.reportFinalisation.findMany({ where: { reportId }, orderBy: { cycle: 'desc' } })).map((f) => ({
            cycle: f.cycle,
            version: f.version,
            finalisedAt: f.finalisedAt,
            reopenedAt: f.reopenedAt,
            reopenReason: f.reopenReason,
          })),
        }
      : undefined;
    return {
      ...(finalisation ? { finalisation } : {}),
      reportId,
      status: report.status,
      version: report.version,
      submittedVersion: submitted?.version ?? null,
      reviewerApproval: live(ReviewDecision.APPROVED),
      ownerApproval: live(ReviewDecision.OWNER_APPROVED),
      lastAmendmentRequest: reviews.find((r) => r.decision === ReviewDecision.AMENDMENTS_REQUIRED) ?? null,
      reviews,
    };
  }

  private cleanComment(value: unknown, required: boolean): string | null {
    const text = typeof value === 'string' ? sanitizeText(value).trim() : '';
    if (text.length > COMMENT_MAX) throw Errors.validation(`The comment is longer than ${COMMENT_MAX} characters`, 'comment');
    if (required && text.length === 0) throw Errors.validation('Please say what needs to change', 'comment');
    return text === '' ? null : text;
  }

  private invalidState(status: ReportStatus, action: ReviewAction) {
    return editingError(HttpStatus.CONFLICT, 'INVALID_STATE', `That is not possible while the report is ${status.toLowerCase().replaceAll('_', ' ')}.`, { status, action });
  }

  /** The transition table. Returns the new status, or throws INVALID_STATE / FORBIDDEN. */
  private next(status: ReportStatus, action: ReviewAction, actor: ReviewActor): ReportStatus {
    const S = ReportStatus;
    const owner = actor.kind === 'owner';
    switch (action) {
      case 'submit':
        if (status === S.DRAFT || status === S.AMENDMENTS_REQUIRED) return S.SUBMITTED_FOR_REVIEW;
        break;
      case 'start':
        if (status === S.SUBMITTED_FOR_REVIEW) return S.UNDER_REVIEW;
        break;
      case 'approve':
        if (owner) throw Errors.forbidden(); // the owner gives the final approval instead
        if (status === S.SUBMITTED_FOR_REVIEW || status === S.UNDER_REVIEW) return S.REVIEWER_APPROVED;
        break;
      case 'amend':
        if (status === S.SUBMITTED_FOR_REVIEW || status === S.UNDER_REVIEW || status === S.REVIEWER_APPROVED) return S.AMENDMENTS_REQUIRED;
        break;
      case 'ownerApprove':
        if (!owner) throw Errors.forbidden();
        if (!FINAL.includes(status) && status !== S.OWNER_FINAL_APPROVAL) return S.OWNER_FINAL_APPROVAL;
        break;
      case 'reset':
        if (!owner) throw Errors.forbidden();
        if (status !== S.DRAFT && !FINAL.includes(status)) return S.DRAFT;
        break;
    }
    throw this.invalidState(status, action);
  }

  async act(reportId: string, actor: ReviewActor, action: ReviewAction, dto: ReviewDto, req?: Request) {
    if (actor.kind === 'session') {
      if (actor.ctx.report.id !== reportId) throw Errors.forbidden();
      if (actor.ctx.readOnly) throw actor.ctx.readOnlyReason === 'REPORT_FINALISED' ? Errors.finalised() : Errors.linkExpired();
    }
    const comment = this.cleanComment(dto.comment, action === 'amend');
    const out = await this.prisma.$transaction(async (tx) => {
      const rows = await tx.$queryRaw<{ version: number; status: ReportStatus }[]>`
        SELECT version, status FROM reports WHERE id = ${reportId}::uuid FOR UPDATE`;
      if (rows.length === 0) throw Errors.notFound();
      const cur = rows[0];
      if (FINAL.includes(cur.status)) throw Errors.finalised();
      if (actor.kind === 'session') await this.sessions.assertWritable(tx, actor.ctx);
      if (dto.expectedVersion !== cur.version) throw Errors.conflict(cur.version);
      const to = this.next(cur.status, action, actor);
      await tx.report.update({ where: { id: reportId }, data: { status: to } });
      const who: Prisma.ReviewUncheckedCreateInput = {
        reportId,
        version: cur.version,
        decision: ReviewDecision.SUBMITTED,
        comment,
        ...(actor.kind === 'session' ? { sessionId: actor.ctx.session.id } : { reviewerUserId: actor.userId }),
      };
      const stale: ReviewDecision[] = [];
      switch (action) {
        case 'submit':
          await tx.review.create({ data: { ...who, decision: ReviewDecision.SUBMITTED } });
          break;
        case 'approve':
          await tx.review.create({ data: { ...who, decision: ReviewDecision.APPROVED } });
          break;
        case 'amend':
          await tx.review.create({ data: { ...who, decision: ReviewDecision.AMENDMENTS_REQUIRED } });
          stale.push(ReviewDecision.APPROVED); // sending it back withdraws an earlier approval
          break;
        case 'ownerApprove':
          await tx.review.create({ data: { ...who, decision: ReviewDecision.OWNER_APPROVED } });
          break;
        case 'reset':
          stale.push(ReviewDecision.APPROVED, ReviewDecision.OWNER_APPROVED);
          break;
        default:
          break; // start: status only
      }
      if (stale.length) await tx.review.updateMany({ where: { reportId, invalidatedAt: null, decision: { in: stale } }, data: { invalidatedAt: new Date() } });
      return { from: cur.status, to, version: cur.version };
    });
    const names: Record<ReviewAction, string> = {
      submit: 'REVIEW_SUBMITTED',
      start: 'REVIEW_STARTED',
      approve: 'REVIEW_APPROVED',
      amend: 'REVIEW_AMENDMENTS_REQUIRED',
      ownerApprove: 'OWNER_APPROVED',
      reset: 'REVIEW_RESET',
    };
    await this.audit.log({
      actorType: actor.kind === 'owner' ? ActorType.STAFF : ActorType.SYSTEM,
      actorId: actor.kind === 'owner' ? actor.userId : undefined,
      action: names[action],
      entityType: AuditEntityType.REPORT,
      entityId: reportId,
      metadata: { from: out.from, to: out.to, version: out.version, ...(actor.kind === 'session' ? { sessionId: actor.ctx.session.id, linkId: actor.ctx.link.id } : {}), hasComment: comment !== null },
      request: req,
    });
    return this.view(reportId, actor.kind === 'owner');
  }
}

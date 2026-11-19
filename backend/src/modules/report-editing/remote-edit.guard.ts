import { CanActivate, ExecutionContext, HttpException, HttpStatus, Injectable, SetMetadata } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { PrismaService } from '../prisma/prisma.service';
import { CONFLICT_MESSAGE, FINALISED_MESSAGE, reportGate } from './report-gate';

export type RemoteEditKind = 'survey' | 'section' | 'answer' | 'media';
const KIND = 'remote-edit-kind';

/** Marks a route that changes survey data from the phone: which kind of id the route carries. */
export const RemoteEditChange = (kind: RemoteEditKind) => SetMetadata(KIND, kind);

/**
 * Applies the report rule (finalised, or edited on a computer and not yet synchronised) to the phone's single-record updates and
 * deletes. The phone names the report version it has in the X-Report-Version header. A refusal is a 409 (stale) or 403 (finalised)
 * with a machine-readable code; the phone keeps its change and shows it (Remote Editor spec v1.4 sections 10 and 11).
 */
@Injectable()
export class RemoteEditGuard implements CanActivate {
  constructor(
    private readonly prisma: PrismaService,
    private readonly reflector: Reflector,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const kind = this.reflector.get<RemoteEditKind | undefined>(KIND, context.getHandler());
    if (!kind) return true;
    const req = context.switchToHttp().getRequest<{ params: Record<string, string>; headers: Record<string, string | string[] | undefined>; user?: { id: string; role: string } }>();
    const id = req.params.id;
    if (!id || !/^[0-9a-f-]{36}$/i.test(id)) return true; // the route's own validation answers
    const surveyId = await this.surveyOf(kind, id);
    if (!surveyId) return true; // unknown record: the route answers 404 itself
    // Only the owner (or an admin) is told anything about the report; anyone else gets the route's own 403/404.
    const survey = await this.prisma.survey.findUnique({ where: { id: surveyId }, select: { userId: true } });
    if (!survey || !req.user || (survey.userId !== req.user.id && req.user.role !== 'ADMIN')) return true;
    const raw = req.headers['x-report-version'];
    const header = Array.isArray(raw) ? raw[0] : raw;
    const known = header !== undefined && /^\d{1,9}$/.test(header) ? Number(header) : undefined;
    const refusal = await reportGate(this.prisma as never, surveyId, known);
    if (!refusal) return true;
    if (refusal.code === 'REPORT_FINALISED') {
      throw new HttpException({ error: 'REPORT_FINALISED', message: FINALISED_MESSAGE }, HttpStatus.FORBIDDEN);
    }
    throw new HttpException(
      { error: 'REPORT_VERSION_CONFLICT', message: CONFLICT_MESSAGE(refusal.currentVersion), details: { currentReportVersion: refusal.currentVersion } },
      HttpStatus.CONFLICT,
    );
  }

  private async surveyOf(kind: RemoteEditKind, id: string): Promise<string | null> {
    if (kind === 'survey') return id;
    if (kind === 'section') return (await this.prisma.section.findUnique({ where: { id }, select: { surveyId: true } }))?.surveyId ?? null;
    if (kind === 'media') return (await this.prisma.media.findUnique({ where: { id }, select: { surveyId: true } }))?.surveyId ?? null;
    return (await this.prisma.answer.findUnique({ where: { id }, select: { section: { select: { surveyId: true } } } }))?.section.surveyId ?? null;
  }
}

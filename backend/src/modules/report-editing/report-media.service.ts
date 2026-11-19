import { Inject, Injectable } from '@nestjs/common';
import { ActorType, AuditEntityType, MediaType, Prisma, ReportStatus, UserRole } from '@prisma/client';
import { Request } from 'express';
import { PrismaService } from '../prisma/prisma.service';
import { AuditService } from '../audit/audit.service';
import { STORAGE_SERVICE, StorageService } from '../media/storage/storage.interface';
import { Errors } from './editing.errors';
import { sanitizeText } from './report-content';
import type { Owner } from './report-editing.service';

const MAX_ANNOTATION_BYTES = 64 * 1024;
const MAX_ANNOTATION_ITEMS = 200;
const MAX_DEPTH = 5;

/** A drawing on a photo is plain data: numbers, booleans, short text, nested lists and objects. Text has its tags removed. */
export function cleanAnnotations(value: unknown): Prisma.InputJsonValue[] {
  if (!Array.isArray(value)) throw Errors.validation('annotations must be a list', 'annotations');
  if (value.length > MAX_ANNOTATION_ITEMS) throw Errors.validation(`at most ${MAX_ANNOTATION_ITEMS} annotations`, 'annotations');
  const walk = (v: unknown, depth: number, path: string): Prisma.InputJsonValue => {
    if (depth > MAX_DEPTH) throw Errors.validation('annotation is nested too deeply', path);
    if (v === null || typeof v === 'boolean') return v as Prisma.InputJsonValue;
    if (typeof v === 'number') {
      if (!Number.isFinite(v)) throw Errors.validation('numbers must be finite', path);
      return v;
    }
    if (typeof v === 'string') return sanitizeText(v).slice(0, 2000);
    if (Array.isArray(v)) return v.map((x, i) => walk(x, depth + 1, `${path}[${i}]`));
    if (typeof v === 'object') {
      const out: Record<string, Prisma.InputJsonValue> = {};
      for (const [k, x] of Object.entries(v as Record<string, unknown>)) {
        if (!/^[A-Za-z0-9_]{1,40}$/.test(k)) throw Errors.validation('annotation keys are letters, digits and _', `${path}.${k}`);
        out[k] = walk(x, depth + 1, `${path}.${k}`);
      }
      return out;
    }
    throw Errors.validation('unsupported value in an annotation', path);
  };
  const cleaned = value.map((x, i) => walk(x, 1, `annotations[${i}]`));
  if (Buffer.byteLength(JSON.stringify(cleaned), 'utf8') > MAX_ANNOTATION_BYTES) throw Errors.validation('annotations are too large', 'annotations');
  return cleaned;
}

/**
 * The owner's view of every picture and signature of a report, including the ones replaced or deleted in the browser or on the
 * phone (Remote Editor spec v1.4 section 9): nothing is destroyed, so the original evidence stays available and the archive can
 * include it. Also where a photo's drawing is kept.
 */
@Injectable()
export class ReportMediaService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    @Inject(STORAGE_SERVICE) private readonly storage: StorageService,
  ) {}

  private async assertOwner(reportId: string, user: Owner) {
    const report = await this.prisma.report.findUnique({ where: { id: reportId } });
    if (!report) throw Errors.notFound();
    if (report.ownerUserId !== user.id && user.role !== UserRole.ADMIN) throw Errors.forbidden();
    return report;
  }

  async list(user: Owner, reportId: string) {
    await this.assertOwner(reportId, user);
    const rows = await this.prisma.media.findMany({ where: { surveyId: reportId }, orderBy: [{ createdAt: 'asc' }, { id: 'asc' }] });
    return {
      reportId,
      media: rows.map((m) => ({
        id: m.id,
        type: m.type,
        fileName: m.fileName,
        mimeType: m.mimeType,
        size: m.size,
        caption: m.caption,
        sectionKey: m.sectionKey,
        sortOrder: m.sortOrder,
        source: m.source,
        original: m.source === 'PHONE',
        replacedBy: m.replacedById,
        deleted: m.deletedAt !== null,
        hasAnnotations: m.annotations !== null,
        createdAt: m.createdAt,
      })),
    };
  }

  /** The stored bytes of any picture of the report, also a replaced or deleted one. Owner or admin only. */
  async file(user: Owner, reportId: string, mediaId: string) {
    await this.assertOwner(reportId, user);
    const m = await this.prisma.media.findFirst({ where: { id: mediaId, surveyId: reportId } });
    if (!m || !(await this.storage.exists(m.storagePath))) throw Errors.notFound();
    return { path: this.storage.getAbsolutePath(m.storagePath), mimeType: m.mimeType, fileName: m.fileName, size: m.size, etag: `"${m.id}-${m.size}"` };
  }

  async getAnnotations(user: Owner, reportId: string, mediaId: string) {
    await this.assertOwner(reportId, user);
    const m = await this.prisma.media.findFirst({ where: { id: mediaId, surveyId: reportId, type: MediaType.PHOTO }, select: { annotations: true } });
    if (!m) throw Errors.notFound();
    return { mediaId, annotations: m.annotations ?? [] };
  }

  /** The phone sends the drawing it made on a photo. Replaces the earlier drawing of that photo; an empty list removes it. */
  async putAnnotations(user: Owner, reportId: string, mediaId: string, raw: unknown, req?: Request) {
    const report = await this.assertOwner(reportId, user);
    if (report.status === ReportStatus.FINALISING || report.status === ReportStatus.FINALISED) throw Errors.finalised();
    const annotations = cleanAnnotations(raw);
    const m = await this.prisma.media.findFirst({ where: { id: mediaId, surveyId: reportId, type: MediaType.PHOTO } });
    if (!m) throw Errors.notFound();
    await this.prisma.media.update({ where: { id: mediaId }, data: { annotations: annotations.length === 0 ? Prisma.DbNull : annotations } });
    await this.audit.log({
      actorType: ActorType.STAFF,
      actorId: user.id,
      action: 'PHOTO_ANNOTATED',
      entityType: AuditEntityType.REPORT,
      entityId: reportId,
      metadata: { mediaId, items: annotations.length },
      request: req,
    });
    return { mediaId, items: annotations.length };
  }

}

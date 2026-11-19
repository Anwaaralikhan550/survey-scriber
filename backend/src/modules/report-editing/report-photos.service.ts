import { Inject, Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ActorType, AuditEntityType, Media, MediaType, Prisma, ReportStatus } from '@prisma/client';
import { randomUUID } from 'crypto';
import { Request } from 'express';
import { PrismaService } from '../prisma/prisma.service';
import { AuditService } from '../audit/audit.service';
import { STORAGE_SERVICE, StorageService } from '../media/storage/storage.interface';
import { processPhoto } from '../media/image-processor';
import { Errors } from './editing.errors';
import { sanitizeText } from './report-content';
import { invalidateApprovalsAfterChange } from './review-effects';

const LOCKED: ReportStatus[] = [ReportStatus.FINALISING, ReportStatus.FINALISED];
const CAPTION_MAX = 1000;

/** Who is changing the photos: the owner's phone/app, or a browser editor session. */
export type PhotoActor = { kind: 'owner'; userId: string } | { kind: 'session'; sessionId: string; linkId: string };

export interface UploadedPhoto {
  originalname: string;
  mimetype: string;
  size: number;
  buffer: Buffer;
}

export interface PhotoView {
  id: string;
  fileName: string;
  mimeType: string;
  size: number;
  caption: string | null;
  sectionKey: string | null;
  sortOrder: number;
  createdAt: Date;
  updatedAt: Date;
  deleted: boolean;
  /** PHONE = an original of the inspection, EDITOR = added in the browser. */
  source: string;
  /** The picture that replaced this one (the old file and record are kept). */
  replacedBy: string | null;
  hasAnnotations: boolean;
}

/**
 * Photo manager of desktop editing (spec section 9). Photos are the survey's Media rows, so the phone and the
 * browser see the same ones. Every change is one transaction on the locked report row that also raises the
 * report version, so a photo change takes part in version checks, history and audit like a text change.
 */
@Injectable()
export class ReportPhotosService {
  private readonly logger = new Logger(ReportPhotosService.name);
  private readonly maxBytes: number;
  private readonly allowedMime: string[];

  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    config: ConfigService,
    @Inject(STORAGE_SERVICE) private readonly storage: StorageService,
  ) {
    this.maxBytes = Number(config.get('MAX_UPLOAD_MB_PHOTO', 10)) * 1024 * 1024;
    this.allowedMime = String(config.get('ALLOWED_MIME_PHOTO', 'image/jpeg,image/png')).split(',');
  }

  private view(m: Media): PhotoView {
    return {
      id: m.id,
      fileName: m.fileName,
      mimeType: m.mimeType,
      size: m.size,
      caption: m.caption,
      sectionKey: m.sectionKey,
      sortOrder: m.sortOrder,
      createdAt: m.createdAt,
      updatedAt: m.updatedAt,
      deleted: m.deletedAt !== null,
      source: m.source,
      replacedBy: m.replacedById,
      hasAnnotations: m.annotations !== null,
    };
  }

  private who(actor: PhotoActor): string {
    return actor.kind === 'owner' ? `owner:${actor.userId}` : `session:${actor.sessionId}`;
  }

  private log(action: string, reportId: string, actor: PhotoActor, req: Request | undefined, metadata: Record<string, unknown>) {
    return this.audit.log({
      actorType: actor.kind === 'owner' ? ActorType.STAFF : ActorType.SYSTEM,
      actorId: actor.kind === 'owner' ? actor.userId : undefined,
      action,
      entityType: AuditEntityType.REPORT,
      entityId: reportId,
      metadata: { ...metadata, ...(actor.kind === 'session' ? { sessionId: actor.sessionId, linkId: actor.linkId } : {}) },
      request: req,
    });
  }

  /** Live photos in the order the report shows them (section, then position). Deleted ones only when asked for. */
  async list(reportId: string, opts: { includeDeleted?: boolean } = {}) {
    const report = await this.prisma.report.findUnique({ where: { id: reportId }, select: { version: true } });
    if (!report) throw Errors.notFound();
    const rows = await this.prisma.media.findMany({
      where: { surveyId: reportId, type: MediaType.PHOTO, ...(opts.includeDeleted ? {} : { deletedAt: null }) },
      orderBy: [{ sectionKey: 'asc' }, { sortOrder: 'asc' }, { createdAt: 'asc' }],
    });
    return { reportId, version: report.version, photos: rows.map((m) => this.view(m)) };
  }

  async getFile(reportId: string, photoId: string) {
    const m = await this.prisma.media.findFirst({ where: { id: photoId, surveyId: reportId, type: MediaType.PHOTO, deletedAt: null } });
    if (!m) throw Errors.notFound();
    return { path: this.storage.getAbsolutePath(m.storagePath), mimeType: m.mimeType, fileName: m.fileName, tag: `"${m.id}-${m.size}"` };
  }

  /** Size, type and the real picture inside (spec 9). Returns the processed bytes: upright, without EXIF/GPS. */
  private async prepare(file: UploadedPhoto) {
    if (!file) throw Errors.validation('No file was sent', 'file');
    if (file.size > this.maxBytes) throw Errors.validation(`The photo is larger than ${this.maxBytes / 1024 / 1024} MB`, 'file');
    if (!this.allowedMime.includes(file.mimetype)) throw Errors.validation(`Photos must be ${this.allowedMime.join(' or ')}`, 'file');
    try {
      return await processPhoto(file.buffer, file.mimetype);
    } catch (e) {
      const message = e instanceof Error ? e.message : 'The photo is not valid';
      const body = (e as { getResponse?: () => { message?: string } }).getResponse?.();
      throw Errors.validation(body?.message ?? message, 'file');
    }
  }

  private cleanCaption(value: unknown): string | null {
    if (value === undefined || value === null) return null;
    if (typeof value !== 'string') throw Errors.validation('Caption must be text', 'caption');
    const text = sanitizeText(value).trim();
    if (text.length > CAPTION_MAX) throw Errors.validation(`Caption is longer than ${CAPTION_MAX} characters`, 'caption');
    return text === '' ? null : text;
  }

  /** `null` means "no section". Anything else must be a section of this report. */
  private async cleanSection(tx: Prisma.TransactionClient, reportId: string, value: unknown): Promise<string | null> {
    if (value === undefined || value === null || value === '') return null;
    if (typeof value !== 'string') throw Errors.validation('sectionKey must be text', 'sectionKey');
    const rep = await tx.report.findUniqueOrThrow({ where: { id: reportId }, select: { content: true } });
    const keys = new Set((rep.content as { key: string }[]).map((s) => s.key));
    if (!keys.has(value)) throw Errors.validation('That section is not part of this report', 'sectionKey');
    return value;
  }

  /**
   * The one write path. Locks the report, checks it is open and the caller's version is current, runs `fn`,
   * raises the version and keeps a history row. Throws VERSION_CONFLICT or REPORT_FINALISED before anything is changed.
   */
  private async commit<T>(
    reportId: string,
    expectedVersion: number,
    actor: PhotoActor,
    guard: (tx: Prisma.TransactionClient) => Promise<void>,
    fn: (tx: Prisma.TransactionClient) => Promise<T>,
  ): Promise<{ version: number; result: T }> {
    const out = await this.prisma.$transaction(async (tx) => {
      const rows = await tx.$queryRaw<{ version: number; status: ReportStatus; content: unknown }[]>`
        SELECT version, status, content FROM reports WHERE id = ${reportId}::uuid FOR UPDATE`;
      if (rows.length === 0) throw Errors.notFound();
      const cur = rows[0];
      if (LOCKED.includes(cur.status)) throw Errors.finalised();
      await guard(tx);
      if (expectedVersion !== cur.version) throw Errors.conflict(cur.version);
      const result = await fn(tx);
      const version = cur.version + 1;
      await tx.report.update({ where: { id: reportId }, data: { version } });
      await tx.reportVersion.create({
        data: { reportId, version, content: cur.content as Prisma.InputJsonValue, savedBy: this.who(actor), reason: 'PHOTO' },
      });
      const invalidated = (await invalidateApprovalsAfterChange(tx, reportId, cur.status)) !== null;
      return { version, result, invalidated };
    });
    if (out.invalidated) {
      await this.audit.log({ actorType: actor.kind === 'owner' ? ActorType.STAFF : ActorType.SYSTEM, actorId: actor.kind === 'owner' ? actor.userId : undefined, action: 'REVIEW_INVALIDATED', entityType: AuditEntityType.REPORT, entityId: reportId, metadata: { version: out.version, cause: 'photo change' } });
    }
    return { version: out.version, result: out.result };
  }

  private async nextOrder(tx: Prisma.TransactionClient, surveyId: string, sectionKey: string | null): Promise<number> {
    const last = await tx.media.aggregate({
      where: { surveyId, type: MediaType.PHOTO, deletedAt: null, sectionKey },
      _max: { sortOrder: true },
    });
    return (last._max.sortOrder ?? -1) + 1;
  }

  async upload(
    reportId: string,
    actor: PhotoActor,
    file: UploadedPhoto,
    opts: { expectedVersion: number; sectionKey?: unknown; caption?: unknown; guard?: (tx: Prisma.TransactionClient) => Promise<void> },
    req?: Request,
  ) {
    const photo = await this.prepare(file);
    const caption = this.cleanCaption(opts.caption);
    const id = randomUUID();
    const storagePath = await this.storage.store(reportId, id, photo.buffer, photo.extension);
    try {
      const { version, result } = await this.commit(reportId, opts.expectedVersion, actor, opts.guard ?? (async () => undefined), async (tx) => {
        const sectionKey = await this.cleanSection(tx, reportId, opts.sectionKey);
        return tx.media.create({
          data: {
            id,
            surveyId: reportId,
            type: MediaType.PHOTO,
            fileName: file.originalname.slice(0, 255),
            mimeType: photo.mimeType,
            size: photo.buffer.length,
            storagePath,
            caption,
            sectionKey,
            sortOrder: await this.nextOrder(tx, reportId, sectionKey),
            source: 'EDITOR',
          },
        });
      });
      await this.log('PHOTO_UPLOADED', reportId, actor, req, { photoId: id, version });
      return { version, photo: this.view(result) };
    } catch (e) {
      await this.storage.delete(storagePath).catch(() => undefined); // a refused upload leaves no file behind
      throw e;
    }
  }

  /** Caption, section and position. `order` is the 0-based place within the target section. */
  async update(
    reportId: string,
    photoId: string,
    actor: PhotoActor,
    dto: { expectedVersion: number; caption?: unknown; sectionKey?: unknown; order?: unknown },
    guard?: (tx: Prisma.TransactionClient) => Promise<void>,
    req?: Request,
  ) {
    if (dto.order !== undefined && (!Number.isInteger(dto.order) || (dto.order as number) < 0 || (dto.order as number) > 100000)) {
      throw Errors.validation('order must be a whole number from 0', 'order');
    }
    const { version, result } = await this.commit(reportId, dto.expectedVersion, actor, guard ?? (async () => undefined), async (tx) => {
      const photo = await tx.media.findFirst({ where: { id: photoId, surveyId: reportId, type: MediaType.PHOTO, deletedAt: null } });
      if (!photo) throw Errors.notFound();
      const data: Prisma.MediaUpdateInput = {};
      if (dto.caption !== undefined) data.caption = this.cleanCaption(dto.caption);
      const targetSection = dto.sectionKey !== undefined ? await this.cleanSection(tx, reportId, dto.sectionKey) : photo.sectionKey;
      const moved = targetSection !== photo.sectionKey;
      if (moved) data.sectionKey = targetSection;
      if (Object.keys(data).length) await tx.media.update({ where: { id: photoId }, data });
      if (moved || dto.order !== undefined) {
        // Renumber the target section with this photo at the asked place, and close the gap it left behind.
        const inTarget = await tx.media.findMany({
          where: { surveyId: reportId, type: MediaType.PHOTO, deletedAt: null, sectionKey: targetSection, id: { not: photoId } },
          orderBy: [{ sortOrder: 'asc' }, { createdAt: 'asc' }],
        });
        const at = Math.min(dto.order === undefined ? inTarget.length : (dto.order as number), inTarget.length);
        const ordered = [...inTarget.slice(0, at).map((m) => m.id), photoId, ...inTarget.slice(at).map((m) => m.id)];
        const current = new Map([...inTarget, photo].map((m) => [m.id, m.sortOrder]));
        for (let i = 0; i < ordered.length; i++) {
          if (current.get(ordered[i]) !== i || ordered[i] === photoId) await tx.media.update({ where: { id: ordered[i] }, data: { sortOrder: i } });
        }
        if (moved) {
          const left = await tx.media.findMany({
            where: { surveyId: reportId, type: MediaType.PHOTO, deletedAt: null, sectionKey: photo.sectionKey },
            orderBy: [{ sortOrder: 'asc' }, { createdAt: 'asc' }],
          });
          for (let i = 0; i < left.length; i++) if (left[i].sortOrder !== i) await tx.media.update({ where: { id: left[i].id }, data: { sortOrder: i } });
        }
      }
      return tx.media.findUniqueOrThrow({ where: { id: photoId } });
    });
    await this.log('PHOTO_UPDATED', reportId, actor, req, { photoId, version, fields: Object.keys(dto).filter((k) => k !== 'expectedVersion') });
    return { version, photo: this.view(result) };
  }

  /**
   * New picture for an existing photo, keeping its caption, section and place. The new picture becomes a new
   * photo (new id, so no cache can show the old one) and the old one is marked deleted in the same step.
   * If anything fails first, the old photo is untouched (spec: failed replacement must not remove the asset).
   */
  async replace(
    reportId: string,
    photoId: string,
    actor: PhotoActor,
    file: UploadedPhoto,
    opts: { expectedVersion: number; guard?: (tx: Prisma.TransactionClient) => Promise<void> },
    req?: Request,
  ) {
    const photo = await this.prepare(file);
    const id = randomUUID();
    const storagePath = await this.storage.store(reportId, id, photo.buffer, photo.extension);
    try {
      const { version, result } = await this.commit(reportId, opts.expectedVersion, actor, opts.guard ?? (async () => undefined), async (tx) => {
        const old = await tx.media.findFirst({ where: { id: photoId, surveyId: reportId, type: MediaType.PHOTO, deletedAt: null } });
        if (!old) throw Errors.notFound();
        // The old picture stays on the volume with its record: it points to the picture that replaced it.
        await tx.media.update({ where: { id: photoId }, data: { deletedAt: new Date(), replacedById: id } });
        return tx.media.create({
          data: {
            id,
            surveyId: reportId,
            type: MediaType.PHOTO,
            fileName: file.originalname.slice(0, 255),
            mimeType: photo.mimeType,
            size: photo.buffer.length,
            storagePath,
            caption: old.caption,
            sectionKey: old.sectionKey,
            sortOrder: old.sortOrder,
            source: 'EDITOR',
          },
        });
      });
      await this.log('PHOTO_REPLACED', reportId, actor, req, { oldPhotoId: photoId, photoId: id, version });
      return { version, photo: this.view(result), replaced: photoId };
    } catch (e) {
      await this.storage.delete(storagePath).catch(() => undefined);
      throw e;
    }
  }

  /**
   * The phone tells the cloud which report section each of its photos belongs to, with caption and place.
   * Only photos nobody has organised yet are filled in (no section and no caption): what a colleague set in the
   * browser is never overwritten by the phone.
   */
  async assign(
    reportId: string,
    actor: PhotoActor,
    dto: { expectedVersion: number; items: { id: string; sectionKey?: string | null; caption?: string | null; sortOrder?: number }[] },
    req?: Request,
  ) {
    const ids = dto.items.map((i) => i.id);
    const fresh = () =>
      this.prisma.media.findMany({ where: { id: { in: ids }, surveyId: reportId, type: MediaType.PHOTO, deletedAt: null, sectionKey: null, caption: null } });
    const report = await this.prisma.report.findUnique({ where: { id: reportId }, select: { version: true } });
    if (!report) throw Errors.notFound();
    if ((await fresh()).length === 0) return { version: report.version, changed: 0 };
    const { version, result } = await this.commit(reportId, dto.expectedVersion, actor, async () => undefined, async (tx) => {
      const eligible = new Map((await tx.media.findMany({ where: { id: { in: ids }, surveyId: reportId, type: MediaType.PHOTO, deletedAt: null, sectionKey: null, caption: null } })).map((m) => [m.id, m]));
      let changed = 0;
      for (const item of dto.items) {
        if (!eligible.has(item.id)) continue;
        let sectionKey: string | null = null;
        try {
          sectionKey = await this.cleanSection(tx, reportId, item.sectionKey);
        } catch {
          sectionKey = null; // a key that is not in this report just stays unassigned
        }
        const caption = this.cleanCaption(item.caption);
        const data: Prisma.MediaUpdateInput = { sectionKey, caption };
        if (item.sortOrder !== undefined) data.sortOrder = item.sortOrder;
        await tx.media.update({ where: { id: item.id }, data });
        changed++;
      }
      return changed;
    });
    await this.log('PHOTOS_ASSIGNED', reportId, actor, req, { changed: result, version });
    return { version, changed: result };
  }

  /** Marks the photo deleted (the file stays, so the phone can be told and nothing is lost by accident). */
  async remove(
    reportId: string,
    photoId: string,
    actor: PhotoActor,
    opts: { expectedVersion: number; guard?: (tx: Prisma.TransactionClient) => Promise<void> },
    req?: Request,
  ) {
    const { version } = await this.commit(reportId, opts.expectedVersion, actor, opts.guard ?? (async () => undefined), async (tx) => {
      const photo = await tx.media.findFirst({ where: { id: photoId, surveyId: reportId, type: MediaType.PHOTO, deletedAt: null } });
      if (!photo) throw Errors.notFound();
      await tx.media.update({ where: { id: photoId }, data: { deletedAt: new Date() } });
      const rest = await tx.media.findMany({
        where: { surveyId: reportId, type: MediaType.PHOTO, deletedAt: null, sectionKey: photo.sectionKey },
        orderBy: [{ sortOrder: 'asc' }, { createdAt: 'asc' }],
      });
      for (let i = 0; i < rest.length; i++) if (rest[i].sortOrder !== i) await tx.media.update({ where: { id: rest[i].id }, data: { sortOrder: i } });
    });
    await this.log('PHOTO_DELETED', reportId, actor, req, { photoId, version });
    return { version, id: photoId };
  }
}

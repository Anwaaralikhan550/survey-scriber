import { HttpException, HttpStatus, Inject, Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ActorType, AuditEntityType, MediaType, Prisma, ReportStatus, ReviewDecision, SurveyStatus, SurveyType, UserRole } from '@prisma/client';
import { createHash, randomUUID } from 'crypto';
import { Request } from 'express';
import { PrismaService } from '../prisma/prisma.service';
import { AuditService } from '../audit/audit.service';
import { STORAGE_SERVICE, StorageService } from '../media/storage/storage.interface';
import { Errors, editingError } from './editing.errors';
import { cleanContent, ContentValidationError, ReportContent } from './report-content';
import { detectFileKind, EXTENSION, safeFileName } from './report-file-content';
import { cleanAnnotations } from './report-media.service';
import { OriginalSnapshotService } from './original-snapshot.service';
import {
  ArchiveEntry,
  ArchiveError,
  ArchiveLimits,
  buildArchive,
  DEFAULT_LIMITS,
  Manifest,
  readArchive,
  readmeText,
  ReadArchive,
  sha256Hex,
} from './report-archive';
import type { Owner } from './report-editing.service';

type Tx = Prisma.TransactionClient;

const MIME_EXT: Record<string, string> = { 'image/jpeg': 'jpg', 'image/png': 'png' };
const EXT_MIME: Record<string, string> = { jpg: 'image/jpeg', png: 'image/png' };

export interface UploadedArchive {
  buffer: Buffer;
  originalname?: string;
}

// ---- small, strict readers for the JSON files of an archive. Anything unexpected is ARCHIVE_INVALID. ----
const bad = (path: string, what: string): never => {
  throw new ArchiveError(`${path}: ${what}`);
};
const isObj = (v: unknown): v is Record<string, unknown> => typeof v === 'object' && v !== null && !Array.isArray(v);
const obj = (v: unknown, path: string) => (isObj(v) ? v : bad(path, 'must be an object'));
const arr = (v: unknown, path: string, max: number): unknown[] => (Array.isArray(v) && v.length <= max ? v : bad(path, `must be a list of at most ${max}`));
const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;
const uuid = (v: unknown, path: string): string => (typeof v === 'string' && UUID_RE.test(v.toLowerCase()) ? v.toLowerCase() : bad(path, 'must be an id'));
const uuidOrNull = (v: unknown, path: string): string | null => (v === null || v === undefined ? null : uuid(v, path));
const str = (v: unknown, path: string, max: number): string => (typeof v === 'string' && v.length <= max ? v : bad(path, `must be text of at most ${max} characters`));
const strOrNull = (v: unknown, path: string, max: number): string | null => (v === null || v === undefined ? null : str(v, path, max));
const int = (v: unknown, path: string, min = 0): number => (typeof v === 'number' && Number.isInteger(v) && v >= min && v <= 2_000_000_000 ? v : bad(path, 'must be a whole number'));
const intOrNull = (v: unknown, path: string): number | null => (v === null || v === undefined ? null : int(v, path));
const date = (v: unknown, path: string): Date => {
  const d = typeof v === 'string' ? new Date(v) : null;
  return d && !Number.isNaN(d.getTime()) ? d : bad(path, 'must be a date');
};
const dateOrNull = (v: unknown, path: string): Date | null => (v === null || v === undefined ? null : date(v, path));
const oneOf = <T extends string>(v: unknown, allowed: readonly T[], path: string): T => (typeof v === 'string' && (allowed as readonly string[]).includes(v) ? (v as T) : bad(path, 'is not a known value'));
const json = (v: unknown): Prisma.InputJsonValue | typeof Prisma.JsonNull => (v === null || v === undefined ? Prisma.JsonNull : (v as Prisma.InputJsonValue));

function parseJson(files: Map<string, Buffer>, path: string): unknown {
  const data = files.get(path);
  if (!data) throw new ArchiveError(`${path} is missing`);
  try {
    return JSON.parse(data.toString('utf8'));
  } catch {
    throw new ArchiveError(`${path} is not valid JSON`);
  }
}

function content(v: unknown, path: string): ReportContent {
  try {
    return cleanContent(v);
  } catch (e) {
    if (e instanceof ContentValidationError) throw new ArchiveError(`${path}: ${e.message}`);
    throw e;
  }
}

/**
 * Complete archive export and restore (Remote Editor spec v1.4 section 14). Export is the owner's: one ZIP with the manifest, original and
 * final documents and data, the pictures themselves, the audit history and a README. Restore validates the whole ZIP first and only then
 * writes, all in one transaction: the original snapshot comes back immutable, the final data becomes the current state, history is marked
 * as imported, and an existing report is never overwritten.
 */
@Injectable()
export class ReportArchiveService {
  private readonly logger = new Logger(ReportArchiveService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly config: ConfigService,
    private readonly originals: OriginalSnapshotService,
    @Inject(STORAGE_SERVICE) private readonly storage: StorageService,
  ) {}

  get limits(): ArchiveLimits {
    const mb = Number(this.config.get('REPORT_ARCHIVE_MAX_MB', 256));
    return { ...DEFAULT_LIMITS, maxArchiveBytes: mb * 1024 * 1024, maxTotalBytes: Math.max(DEFAULT_LIMITS.maxTotalBytes, mb * 3 * 1024 * 1024) };
  }

  private get key(): string {
    const key = this.config.get<string>('ARCHIVE_SIGNING_KEY') || this.config.get<string>('JWT_ACCESS_SECRET');
    if (!key) throw new Error('ARCHIVE_SIGNING_KEY (or JWT_ACCESS_SECRET) is not set');
    return key;
  }

  // ------------------------------------------------------------------------------------------------ export

  async export(user: Owner, reportId: string, req?: Request): Promise<{ zip: Buffer; sha256: string; fileName: string; files: number }> {
    const report = await this.prisma.report.findUnique({ where: { id: reportId }, include: { survey: { include: { sections: { include: { answers: true }, orderBy: { order: 'asc' } } } } } });
    if (!report) throw Errors.notFound();
    if (report.ownerUserId !== user.id && user.role !== UserRole.ADMIN) throw Errors.forbidden();

    const snapshots = await this.prisma.$queryRaw<
      { schema_version: number; survey_type: string; tree_version_id: string | null; phrase_bank_version_id: string | null; generated_at: Date; app_version: string | null; snapshot: unknown; checksum: string; created_by: string; created_at: Date }[]
    >`SELECT schema_version, survey_type, tree_version_id, phrase_bank_version_id, generated_at, app_version, snapshot, checksum, created_by, created_at
      FROM report_original_snapshots WHERE report_id = ${reportId}::uuid`;
    if (snapshots.length === 0) throw editingError(HttpStatus.CONFLICT, 'INVALID_STATE', 'This report has no original snapshot to archive');
    const snap = snapshots[0];

    const [media, files, events, versions, reviews, finalisations] = await Promise.all([
      this.prisma.media.findMany({ where: { surveyId: reportId, type: { not: MediaType.AUDIO } }, orderBy: [{ createdAt: 'asc' }, { id: 'asc' }] }),
      this.prisma.reportFile.findMany({ where: { reportId, state: { in: ['ORIGINAL', 'FINAL'] } }, orderBy: [{ createdAt: 'asc' }] }),
      this.prisma.reportAuditEvent.findMany({ where: { reportId }, orderBy: [{ createdAt: 'asc' }, { id: 'asc' }] }),
      this.prisma.reportVersion.findMany({ where: { reportId }, orderBy: { version: 'asc' } }),
      this.prisma.review.findMany({ where: { reportId }, orderBy: { createdAt: 'asc' } }),
      this.prisma.reportFinalisation.findMany({ where: { reportId }, orderBy: { cycle: 'asc' } }),
    ]);

    const entries: ArchiveEntry[] = [];
    let bytes = 0;
    const add = (path: string, data: Buffer) => {
      bytes += data.length;
      if (bytes > this.limits.maxTotalBytes) throw editingError(HttpStatus.PAYLOAD_TOO_LARGE, 'FILE_TOO_LARGE', 'This report is too large to archive in one file');
      entries.push({ path, data });
    };
    const addJson = (path: string, value: unknown) => add(path, Buffer.from(JSON.stringify(value), 'utf8'));
    const missing = (what: string) => editingError(HttpStatus.INTERNAL_SERVER_ERROR, 'FILE_INVALID', `A stored ${what} is missing or damaged, so the archive cannot be made`);

    const documents: Manifest['documents'] = [];
    for (const f of files) {
      const data = await this.storage.retrieve(f.storagePath).catch(() => null);
      if (!data || sha256Hex(data) !== f.sha256) throw missing('report document');
      const kind = f.kind as 'PDF' | 'DOCX';
      if (kind !== 'PDF' && kind !== 'DOCX') continue;
      const path = `${f.state === 'ORIGINAL' ? 'original' : 'final'}/documents/${f.id}.${EXTENSION[kind]}`;
      add(path, data);
      documents.push({ path, state: f.state as 'ORIGINAL' | 'FINAL', kind, fileName: f.fileName, cycle: f.cycle, version: f.version });
    }

    const mediaRows: unknown[] = [];
    for (const m of media) {
      const ext = MIME_EXT[m.mimeType];
      if (!ext) throw editingError(HttpStatus.UNPROCESSABLE_ENTITY, 'FILE_INVALID', `A picture has a type that cannot be archived (${m.mimeType})`);
      const data = await this.storage.retrieve(m.storagePath).catch(() => null);
      if (!data) throw missing('picture');
      const path = `${m.source === 'PHONE' ? 'original' : 'final'}/media/${m.id}.${ext}`;
      add(path, data);
      mediaRows.push({
        id: m.id,
        type: m.type,
        fileName: m.fileName,
        mimeType: m.mimeType,
        size: m.size,
        caption: m.caption,
        sortOrder: m.sortOrder,
        sectionKey: m.sectionKey,
        source: m.source,
        replacedById: m.replacedById,
        annotations: m.annotations,
        deletedAt: m.deletedAt,
        createdAt: m.createdAt,
        path,
        sha256: sha256Hex(data),
      });
    }

    const exportedAt = new Date().toISOString();
    addJson('original/snapshot.json', {
      schemaVersion: snap.schema_version,
      surveyType: snap.survey_type,
      treeVersionId: snap.tree_version_id,
      phraseBankVersionId: snap.phrase_bank_version_id,
      generatedAt: snap.generated_at,
      appVersion: snap.app_version,
      checksum: snap.checksum,
      createdBy: snap.created_by,
      createdAt: snap.created_at,
      snapshot: snap.snapshot,
    });
    addJson('final/report.json', {
      reportType: report.reportType,
      status: report.status,
      version: report.version,
      editCycle: report.editCycle,
      finalVersion: report.finalVersion,
      finalisedAt: report.finalisedAt,
      createdAt: report.createdAt,
      content: report.content,
    });
    const s = report.survey;
    addJson('final/survey.json', {
      survey: { title: s.title, propertyAddress: s.propertyAddress, status: s.status, type: s.type, jobRef: s.jobRef, clientName: s.clientName, inspectionDate: s.inspectionDate, createdAt: s.createdAt },
      sections: s.sections.map((sec) => ({
        id: sec.id,
        title: sec.title,
        sectionTypeKey: sec.sectionTypeKey,
        order: sec.order,
        phraseOutput: sec.phraseOutput,
        userNotes: sec.userNotes,
        createdAt: sec.createdAt,
        answers: sec.answers.map((a) => ({ id: a.id, questionKey: a.questionKey, value: a.value, createdAt: a.createdAt })),
      })),
    });
    addJson('final/media.json', mediaRows);
    addJson(
      'audit/events.json',
      events.map((e) => ({
        reportVersion: e.reportVersion,
        entityType: e.entityType,
        entityId: e.entityId,
        sectionId: e.sectionId,
        sectionKey: e.sectionKey,
        field: e.field,
        op: e.op,
        beforeValue: e.beforeValue,
        afterValue: e.afterValue,
        actor: e.actor,
        actorName: e.actorName,
        sessionId: e.sessionId,
        source: e.source,
        imported: e.imported,
        createdAt: e.createdAt,
      })),
    );
    addJson(
      'audit/versions.json',
      versions.map((v) => ({ version: v.version, content: v.content, savedBy: v.savedBy, savedByName: v.savedByName, reason: v.reason, createdAt: v.createdAt })),
    );
    addJson('audit/reviews.json', {
      reviews: reviews.map((r) => ({ sessionId: r.sessionId, reviewerUserId: r.reviewerUserId, reviewerName: r.reviewerName, decision: r.decision, comment: r.comment, version: r.version, invalidatedAt: r.invalidatedAt, createdAt: r.createdAt })),
      finalisations: finalisations.map((f) => ({ cycle: f.cycle, version: f.version, finalisedBy: f.finalisedBy, finalisedAt: f.finalisedAt, reopenedBy: f.reopenedBy, reopenedAt: f.reopenedAt, reopenReason: f.reopenReason })),
    });
    addJson('definitions/references.json', {
      treeVersionId: snap.tree_version_id,
      phraseBankVersionId: snap.phrase_bank_version_id,
      note: 'Identifiers of the question tree and phrase bank the report was written with. The report text itself is in the documents and the data files.',
    });

    const originalVersion = versions.length > 0 ? versions[0].version : 1;
    add('README.txt', Buffer.from(readmeText({ reportId, exportedAt, exportedBy: user.id, status: report.status, originalVersion, currentVersion: report.version, finalVersion: report.finalVersion }), 'utf8'));

    const { zip, manifest } = buildArchive(
      entries,
      {
        producedBy: 'SurveyScriber',
        reportId,
        surveyId: reportId,
        ownerUserId: report.ownerUserId,
        exportedAt,
        exportedBy: user.id,
        surveyType: snap.survey_type,
        reportType: report.reportType,
        status: report.status,
        originalVersion,
        currentVersion: report.version,
        finalVersion: report.finalVersion,
        treeVersionId: snap.tree_version_id,
        phraseBankVersionId: snap.phrase_bank_version_id,
        documents,
      },
      this.key,
    );
    const sha256 = sha256Hex(zip);
    await this.audit.log({
      actorType: ActorType.STAFF,
      actorId: user.id,
      action: 'REPORT_ARCHIVE_EXPORTED',
      entityType: AuditEntityType.REPORT,
      entityId: reportId,
      metadata: { sha256, size: zip.length, files: manifest.files.length + 1, status: report.status, version: report.version },
      request: req,
    });
    return { zip, sha256, fileName: `surveyscriber-archive-${reportId.slice(0, 8)}-${exportedAt.slice(0, 10)}.zip`, files: manifest.files.length + 1 };
  }

  // ------------------------------------------------------------------------------------------------ restore

  async restore(user: Owner, file: UploadedArchive | undefined, req?: Request) {
    if (!file || !file.buffer || file.buffer.length === 0) throw Errors.validation('an archive file is required', 'file');
    const sha256 = createHash('sha256').update(file.buffer).digest('hex');
    const record = async (outcome: 'RESTORED' | 'REJECTED', code: string | null, message: string | null, reportId: string | null) => {
      try {
        await this.prisma.reportArchiveImport.create({
          data: { uploaderId: user.id, fileName: file.originalname ? safeFileName(file.originalname, 'archive.zip') : null, size: file.buffer.length, sha256, outcome, errorCode: code, message: message?.slice(0, 500) ?? null, restoredReportId: reportId },
        });
      } catch (e) {
        this.logger.warn(`Could not record the archive import: ${(e as Error).message}`);
      }
    };
    try {
      const result = await this.restoreValidated(user, file, sha256, req);
      await record('RESTORED', null, null, result.reportId);
      return result;
    } catch (error) {
      if (error instanceof ArchiveError) {
        await record('REJECTED', 'ARCHIVE_INVALID', error.message, null);
        throw Errors.archiveInvalid(error.message);
      }
      if (error instanceof HttpException) {
        const body = error.getResponse() as { error?: string; message?: string };
        await record('REJECTED', body.error ?? String(error.getStatus()), body.message ?? error.message, null);
      }
      throw error;
    }
  }

  private async restoreValidated(user: Owner, file: UploadedArchive, sha256: string, req?: Request) {
    const archive = readArchive(file.buffer, this.key, this.limits);
    const data = this.parse(archive);
    const m = archive.manifest;

    // Ownership: only the owner (or an admin) restores a report.
    if (m.ownerUserId !== user.id && user.role !== UserRole.ADMIN) throw Errors.archiveNotOwner();
    const owner = await this.prisma.user.findUnique({ where: { id: m.ownerUserId }, select: { id: true } });
    if (!owner) throw Errors.archiveNotOwner();

    // Never overwrite: the report, its survey and every id inside must be free.
    await this.assertNoCollision(data);

    const stored: string[] = [];
    try {
      const mediaPaths = new Map<string, string>();
      for (const md of data.media) {
        const bytes = archive.files.get(md.path)!;
        mediaPaths.set(md.id, await this.storage.store(m.reportId, md.id, bytes, md.path.endsWith('.png') ? 'png' : 'jpg'));
        stored.push(mediaPaths.get(md.id)!);
      }
      const fileRows: Prisma.ReportFileCreateManyInput[] = [];
      for (const d of m.documents) {
        const bytes = archive.files.get(d.path)!;
        const id = randomUUID();
        const put = await this.storage.storeVerified(`report-files/${m.reportId}`, id, bytes, EXTENSION[d.kind]);
        stored.push(put.storagePath);
        fileRows.push({ id, reportId: m.reportId, state: d.state, kind: d.kind, fileName: safeFileName(d.fileName, `${d.state.toLowerCase()}.${EXTENSION[d.kind]}`), storagePath: put.storagePath, size: put.size, sha256: put.sha256, cycle: d.cycle, version: d.version, uploadedBy: user.id });
      }

      const now = new Date();
      const keepFinalised = data.report.status === ReportStatus.FINALISED && data.report.finalVersion !== null;
      const status = keepFinalised ? ReportStatus.FINALISED : ReportStatus.DRAFT;
      await this.prisma.$transaction(
        async (tx: Tx) => {
          await tx.survey.create({
            data: { id: m.reportId, userId: m.ownerUserId, title: data.survey.title, propertyAddress: data.survey.propertyAddress, status: data.survey.status, type: data.survey.type, jobRef: data.survey.jobRef, clientName: data.survey.clientName, inspectionDate: data.survey.inspectionDate, createdAt: data.survey.createdAt },
          });
          if (data.sections.length > 0) await tx.section.createMany({ data: data.sections.map((s) => ({ id: s.id, surveyId: m.reportId, title: s.title, sectionTypeKey: s.sectionTypeKey, order: s.order, phraseOutput: s.phraseOutput, userNotes: s.userNotes, createdAt: s.createdAt })) });
          const answers = data.sections.flatMap((s) => s.answers.map((a) => ({ id: a.id, sectionId: s.id, questionKey: a.questionKey, value: a.value, createdAt: a.createdAt })));
          if (answers.length > 0) await tx.answer.createMany({ data: answers });
          if (data.media.length > 0) {
            await tx.media.createMany({
              data: data.media.map((md) => ({
                id: md.id,
                surveyId: m.reportId,
                type: md.type,
                fileName: md.fileName,
                mimeType: md.mimeType,
                size: md.size,
                storagePath: mediaPaths.get(md.id)!,
                caption: md.caption,
                sortOrder: md.sortOrder,
                sectionKey: md.sectionKey,
                source: md.source,
                replacedById: md.replacedById,
                annotations: md.annotations === null ? Prisma.DbNull : md.annotations,
                deletedAt: md.deletedAt,
                createdAt: md.createdAt,
              })),
            });
          }
          await tx.report.create({
            data: {
              id: m.reportId,
              surveyId: m.reportId,
              ownerUserId: m.ownerUserId,
              reportType: data.report.reportType,
              status,
              content: data.report.content as unknown as Prisma.InputJsonValue,
              version: data.report.version,
              editCycle: data.report.editCycle,
              finalisedAt: keepFinalised ? data.report.finalisedAt : null,
              finalVersion: keepFinalised ? data.report.finalVersion : null,
              restoredAt: now,
              restoredFromSha256: sha256,
              createdAt: data.report.createdAt,
            },
          });
          await tx.reportVersion.createMany({ data: data.versions.map((v) => ({ reportId: m.reportId, version: v.version, content: v.content as unknown as Prisma.InputJsonValue, savedBy: v.savedBy, savedByName: v.savedByName, reason: v.reason, createdAt: v.createdAt })) });
          // The original comes back immutable. PostgreSQL recomputes its checksum; it must equal the one the archive carries.
          const checksum = await this.originals.restore(tx, { reportId: m.reportId, userId: user.id, ...data.snapshot });
          if (checksum !== data.snapshot.checksum) throw new ArchiveError('The original snapshot does not match its checksum');
          if (fileRows.length > 0) await tx.reportFile.createMany({ data: fileRows });
          if (data.reviews.length > 0) await tx.review.createMany({ data: data.reviews.map((r) => ({ reportId: m.reportId, ...r, invalidatedAt: r.invalidatedAt ?? (keepFinalised ? null : now) })) });
          if (data.finalisations.length > 0) await tx.reportFinalisation.createMany({ data: data.finalisations.map((f) => ({ reportId: m.reportId, ...f })) });
          if (data.events.length > 0) {
            await tx.reportAuditEvent.createMany({
              data: data.events.map((e) => ({ reportId: m.reportId, ...e, beforeValue: json(e.beforeValue), afterValue: json(e.afterValue), imported: true })),
            });
          }
          await tx.reportAuditEvent.create({
            data: {
              reportId: m.reportId,
              reportVersion: data.report.version,
              entityType: 'REPORT',
              field: 'archive',
              op: 'RESTORED',
              afterValue: { archiveSha256: sha256, exportedAt: m.exportedAt, exportedBy: m.exportedBy, importedEvents: data.events.length, files: m.files.length + 1 },
              actor: `owner:${user.id}`,
              source: 'RESTORE',
              imported: false,
              createdAt: now,
            },
          });
        },
        { timeout: 120_000, maxWait: 20_000 },
      );
      await this.audit.log({
        actorType: ActorType.STAFF,
        actorId: user.id,
        action: 'REPORT_ARCHIVE_RESTORED',
        entityType: AuditEntityType.REPORT,
        entityId: m.reportId,
        metadata: { sha256, files: m.files.length + 1, status, version: data.report.version, importedEvents: data.events.length },
        request: req,
      });
      return {
        reportId: m.reportId,
        surveyId: m.reportId,
        status,
        version: data.report.version,
        restoredFromArchive: true,
        restoredAt: now,
        counts: { sections: data.sections.length, media: data.media.length, documents: m.documents.length, versions: data.versions.length, importedEvents: data.events.length },
      };
    } catch (error) {
      for (const p of stored) await this.storage.delete(p).catch(() => undefined); // a refused restore leaves no file behind
      const code = (error as { code?: string }).code;
      if (code === 'P2002') throw Errors.archiveCollision(m.reportId);
      throw error;
    }
  }

  private async assertNoCollision(d: ParsedArchive) {
    const id = d.manifest.reportId;
    const [survey, report] = await Promise.all([this.prisma.survey.findUnique({ where: { id }, select: { id: true } }), this.prisma.report.findUnique({ where: { id }, select: { id: true } })]);
    if (survey || report) throw Errors.archiveCollision(id);
    const sectionIds = d.sections.map((s) => s.id);
    const answerIds = d.sections.flatMap((s) => s.answers.map((a) => a.id));
    const mediaIds = d.media.map((x) => x.id);
    const [a, b, c] = await Promise.all([
      sectionIds.length ? this.prisma.section.count({ where: { id: { in: sectionIds } } }) : 0,
      answerIds.length ? this.prisma.answer.count({ where: { id: { in: answerIds } } }) : 0,
      mediaIds.length ? this.prisma.media.count({ where: { id: { in: mediaIds } } }) : 0,
    ]);
    if (a + b + c > 0) throw Errors.archiveCollision(id);
  }

  /** Turns the JSON files of a verified archive into typed data, refusing anything that does not fit. */
  private parse(archive: ReadArchive): ParsedArchive {
    const { manifest: m, files } = archive;
    const mp = 'manifest.json';
    m.reportId = uuid(m.reportId, `${mp} reportId`);
    if (uuid(m.surveyId, `${mp} surveyId`) !== m.reportId) bad(mp, 'surveyId and reportId differ');
    m.ownerUserId = uuid(m.ownerUserId, `${mp} ownerUserId`);
    m.exportedBy = uuid(m.exportedBy, `${mp} exportedBy`);
    date(m.exportedAt, `${mp} exportedAt`);
    oneOf(m.status, Object.values(ReportStatus), `${mp} status`);
    int(m.currentVersion, `${mp} currentVersion`, 1);
    arr(m.documents, `${mp} documents`, 200);
    for (const d of m.documents) {
      const o = obj(d, `${mp} document`);
      if (!files.has(str(o.path, `${mp} document path`, 200)) || !/^(original|final)\/documents\//.test(o.path as string)) bad(mp, 'a document is not in the archive');
      oneOf(o.state, ['ORIGINAL', 'FINAL'] as const, `${mp} document state`);
      oneOf(o.kind, ['PDF', 'DOCX'] as const, `${mp} document kind`);
      int(o.cycle, `${mp} document cycle`, 1);
      intOrNull(o.version, `${mp} document version`);
      str(o.fileName, `${mp} document fileName`, 255);
      if ((o.state === 'ORIGINAL') !== (o.path as string).startsWith('original/')) bad(mp, 'a document is in the wrong folder');
      const detected = detectFileKind(files.get(o.path as string)!);
      if (detected !== o.kind) throw new ArchiveError(`${o.path} is not a real ${o.kind as string} file`);
    }

    const rp = 'final/report.json';
    const r = obj(parseJson(files, rp), rp);
    const report = {
      reportType: oneOf(r.reportType, ['L2', 'L3', 'VALUATION'] as const, `${rp} reportType`),
      status: oneOf(r.status, Object.values(ReportStatus), `${rp} status`),
      version: int(r.version, `${rp} version`, 1),
      editCycle: int(r.editCycle, `${rp} editCycle`, 1),
      finalVersion: intOrNull(r.finalVersion, `${rp} finalVersion`),
      finalisedAt: dateOrNull(r.finalisedAt, `${rp} finalisedAt`),
      createdAt: date(r.createdAt, `${rp} createdAt`),
      content: content(r.content, `${rp} content`),
    };
    if (report.version !== m.currentVersion) bad(rp, 'version differs from the manifest');

    const sp = 'original/snapshot.json';
    const s = obj(parseJson(files, sp), sp);
    const snapObj = obj(s.snapshot, `${sp} snapshot`);
    content(snapObj.sections, `${sp} snapshot.sections`);
    const checksum = str(s.checksum, `${sp} checksum`, 64);
    if (!/^[0-9a-f]{64}$/.test(checksum)) bad(sp, 'checksum is not valid');
    const snapshot = {
      schemaVersion: int(s.schemaVersion, `${sp} schemaVersion`, 1),
      surveyType: str(s.surveyType, `${sp} surveyType`, 20),
      treeVersionId: strOrNull(s.treeVersionId, `${sp} treeVersionId`, 100),
      phraseBankVersionId: strOrNull(s.phraseBankVersionId, `${sp} phraseBankVersionId`, 100),
      generatedAt: date(s.generatedAt, `${sp} generatedAt`),
      appVersion: strOrNull(s.appVersion, `${sp} appVersion`, 50),
      checksum,
      snapshot: snapObj,
    };

    const vp = 'survey.json';
    const sv = obj(parseJson(files, 'final/survey.json'), vp);
    const so = obj(sv.survey, `${vp} survey`);
    const survey = {
      title: str(so.title, `${vp} title`, 255),
      propertyAddress: str(so.propertyAddress, `${vp} propertyAddress`, 500),
      status: oneOf(so.status, Object.values(SurveyStatus), `${vp} status`),
      type: so.type === null || so.type === undefined ? null : oneOf(so.type, Object.values(SurveyType), `${vp} type`),
      jobRef: strOrNull(so.jobRef, `${vp} jobRef`, 100),
      clientName: strOrNull(so.clientName, `${vp} clientName`, 255),
      inspectionDate: dateOrNull(so.inspectionDate, `${vp} inspectionDate`),
      createdAt: date(so.createdAt, `${vp} createdAt`),
    };
    const orders = new Set<number>();
    const ids = new Set<string>();
    const sections = arr(sv.sections, `${vp} sections`, 2000).map((x, i) => {
      const p = `${vp} sections[${i}]`;
      const o = obj(x, p);
      const sec = {
        id: uuid(o.id, `${p} id`),
        title: str(o.title, `${p} title`, 255),
        sectionTypeKey: strOrNull(o.sectionTypeKey, `${p} sectionTypeKey`, 100),
        order: int(o.order, `${p} order`),
        phraseOutput: strOrNull(o.phraseOutput, `${p} phraseOutput`, 200_000),
        userNotes: strOrNull(o.userNotes, `${p} userNotes`, 200_000),
        createdAt: date(o.createdAt, `${p} createdAt`),
        answers: arr(o.answers, `${p} answers`, 5000).map((y, j) => {
          const ap = `${p} answers[${j}]`;
          const a = obj(y, ap);
          return { id: uuid(a.id, `${ap} id`), questionKey: str(a.questionKey, `${ap} questionKey`, 255), value: str(a.value, `${ap} value`, 500_000), createdAt: date(a.createdAt, `${ap} createdAt`) };
        }),
      };
      if (orders.has(sec.order) || ids.has(sec.id)) bad(p, 'duplicate section');
      orders.add(sec.order);
      ids.add(sec.id);
      const keys = new Set<string>();
      for (const a of sec.answers) {
        if (keys.has(a.questionKey) || ids.has(a.id)) bad(p, 'duplicate answer');
        keys.add(a.questionKey);
        ids.add(a.id);
      }
      return sec;
    });

    const mediaP = 'final/media.json';
    const mediaIds = new Set<string>();
    const media = arr(parseJson(files, mediaP), mediaP, 5000).map((x, i) => {
      const p = `${mediaP}[${i}]`;
      const o = obj(x, p);
      const path = str(o.path, `${p} path`, 200);
      const bytes = files.get(path);
      if (!bytes || !/^(original|final)\/media\//.test(path)) bad(p, 'its file is not in the archive');
      const ext = path.slice(path.lastIndexOf('.') + 1);
      const mimeType = oneOf(o.mimeType, Object.keys(MIME_EXT), `${p} mimeType`);
      if (EXT_MIME[ext] !== mimeType) bad(p, 'file type does not match its extension');
      const png = bytes![0] === 0x89 && bytes![1] === 0x50;
      const jpg = bytes![0] === 0xff && bytes![1] === 0xd8;
      if ((mimeType === 'image/png' && !png) || (mimeType === 'image/jpeg' && !jpg)) throw new ArchiveError(`${path} is not a real ${mimeType} picture`);
      const id = uuid(o.id, `${p} id`);
      if (mediaIds.has(id) || ids.has(id) || !path.includes(id)) bad(p, 'duplicate or mismatched id');
      mediaIds.add(id);
      const source = oneOf(o.source, ['PHONE', 'EDITOR'] as const, `${p} source`);
      if ((source === 'PHONE') !== path.startsWith('original/')) bad(p, 'picture is in the wrong folder');
      if (sha256Hex(bytes!) !== o.sha256) bad(p, 'checksum differs');
      let annotations: Prisma.InputJsonValue[] | null = null;
      if (o.annotations !== null && o.annotations !== undefined) {
        try {
          annotations = cleanAnnotations(o.annotations);
        } catch {
          bad(p, 'drawing is not valid');
        }
      }
      return {
        id,
        type: oneOf(o.type, [MediaType.PHOTO, MediaType.SIGNATURE] as const, `${p} type`),
        fileName: str(o.fileName, `${p} fileName`, 255),
        mimeType,
        size: bytes!.length,
        caption: strOrNull(o.caption, `${p} caption`, 1000),
        sortOrder: int(o.sortOrder, `${p} sortOrder`),
        sectionKey: strOrNull(o.sectionKey, `${p} sectionKey`, 100),
        source,
        replacedById: uuidOrNull(o.replacedById, `${p} replacedById`),
        annotations,
        deletedAt: dateOrNull(o.deletedAt, `${p} deletedAt`),
        createdAt: date(o.createdAt, `${p} createdAt`),
        path,
      };
    });

    const versionsP = 'audit/versions.json';
    const seenVersions = new Set<number>();
    const versions = arr(parseJson(files, versionsP), versionsP, 5000).map((x, i) => {
      const p = `${versionsP}[${i}]`;
      const o = obj(x, p);
      const version = int(o.version, `${p} version`, 1);
      if (seenVersions.has(version)) bad(p, 'duplicate version');
      seenVersions.add(version);
      return { version, content: content(o.content, `${p} content`), savedBy: strOrNull(o.savedBy, `${p} savedBy`, 80), savedByName: strOrNull(o.savedByName, `${p} savedByName`, 80), reason: str(o.reason, `${p} reason`, 20), createdAt: date(o.createdAt, `${p} createdAt`) };
    });
    if (!seenVersions.has(report.version)) bad(versionsP, 'the current version is missing');

    const eventsP = 'audit/events.json';
    const events = arr(parseJson(files, eventsP), eventsP, 200_000).map((x, i) => {
      const p = `${eventsP}[${i}]`;
      const o = obj(x, p);
      return {
        reportVersion: int(o.reportVersion, `${p} reportVersion`),
        entityType: str(o.entityType, `${p} entityType`, 20),
        entityId: uuidOrNull(o.entityId, `${p} entityId`),
        sectionId: uuidOrNull(o.sectionId, `${p} sectionId`),
        sectionKey: strOrNull(o.sectionKey, `${p} sectionKey`, 100),
        field: str(o.field, `${p} field`, 30),
        op: str(o.op, `${p} op`, 30),
        beforeValue: o.beforeValue ?? null,
        afterValue: o.afterValue ?? null,
        actor: str(o.actor, `${p} actor`, 80),
        actorName: strOrNull(o.actorName, `${p} actorName`, 80),
        sessionId: uuidOrNull(o.sessionId, `${p} sessionId`),
        source: str(o.source, `${p} source`, 20),
        createdAt: date(o.createdAt, `${p} createdAt`),
      };
    });

    const revP = 'audit/reviews.json';
    const rv = obj(parseJson(files, revP), revP);
    const reviews = arr(rv.reviews, `${revP} reviews`, 5000).map((x, i) => {
      const p = `${revP} reviews[${i}]`;
      const o = obj(x, p);
      return {
        sessionId: uuidOrNull(o.sessionId, `${p} sessionId`),
        reviewerUserId: uuidOrNull(o.reviewerUserId, `${p} reviewerUserId`),
        reviewerName: strOrNull(o.reviewerName, `${p} reviewerName`, 80),
        decision: oneOf(o.decision, Object.values(ReviewDecision), `${p} decision`),
        comment: strOrNull(o.comment, `${p} comment`, 20_000),
        version: int(o.version, `${p} version`),
        invalidatedAt: dateOrNull(o.invalidatedAt, `${p} invalidatedAt`),
        createdAt: date(o.createdAt, `${p} createdAt`),
      };
    });
    const cycles = new Set<number>();
    const finalisations = arr(rv.finalisations, `${revP} finalisations`, 1000).map((x, i) => {
      const p = `${revP} finalisations[${i}]`;
      const o = obj(x, p);
      const cycle = int(o.cycle, `${p} cycle`, 1);
      if (cycles.has(cycle)) bad(p, 'duplicate cycle');
      cycles.add(cycle);
      return {
        cycle,
        version: int(o.version, `${p} version`),
        finalisedBy: uuid(o.finalisedBy, `${p} finalisedBy`),
        finalisedAt: date(o.finalisedAt, `${p} finalisedAt`),
        reopenedBy: uuidOrNull(o.reopenedBy, `${p} reopenedBy`),
        reopenedAt: dateOrNull(o.reopenedAt, `${p} reopenedAt`),
        reopenReason: strOrNull(o.reopenReason, `${p} reopenReason`, 500),
      };
    });

    return { manifest: m, report, snapshot, survey, sections, media, versions, events, reviews, finalisations };
  }
}

interface ParsedArchive {
  manifest: Manifest;
  report: { reportType: string; status: ReportStatus; version: number; editCycle: number; finalVersion: number | null; finalisedAt: Date | null; createdAt: Date; content: ReportContent };
  snapshot: { schemaVersion: number; surveyType: string; treeVersionId: string | null; phraseBankVersionId: string | null; generatedAt: Date; appVersion: string | null; checksum: string; snapshot: Record<string, unknown> };
  survey: { title: string; propertyAddress: string; status: SurveyStatus; type: SurveyType | null; jobRef: string | null; clientName: string | null; inspectionDate: Date | null; createdAt: Date };
  sections: { id: string; title: string; sectionTypeKey: string | null; order: number; phraseOutput: string | null; userNotes: string | null; createdAt: Date; answers: { id: string; questionKey: string; value: string; createdAt: Date }[] }[];
  media: { id: string; type: MediaType; fileName: string; mimeType: string; size: number; caption: string | null; sortOrder: number; sectionKey: string | null; source: 'PHONE' | 'EDITOR'; replacedById: string | null; annotations: Prisma.InputJsonValue[] | null; deletedAt: Date | null; createdAt: Date; path: string }[];
  versions: { version: number; content: ReportContent; savedBy: string | null; savedByName: string | null; reason: string; createdAt: Date }[];
  events: { reportVersion: number; entityType: string; entityId: string | null; sectionId: string | null; sectionKey: string | null; field: string; op: string; beforeValue: unknown; afterValue: unknown; actor: string; actorName: string | null; sessionId: string | null; source: string; createdAt: Date }[];
  reviews: { sessionId: string | null; reviewerUserId: string | null; reviewerName: string | null; decision: ReviewDecision; comment: string | null; version: number; invalidatedAt: Date | null; createdAt: Date }[];
  finalisations: { cycle: number; version: number; finalisedBy: string; finalisedAt: Date; reopenedBy: string | null; reopenedAt: Date | null; reopenReason: string | null }[];
}

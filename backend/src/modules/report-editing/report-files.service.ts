import { HttpStatus, Inject, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ActorType, AuditEntityType, ReportFileKind, ReportFileState, ReportStatus, UserRole } from '@prisma/client';
import { createHash, randomUUID } from 'crypto';
import { Request } from 'express';
import { PrismaService } from '../prisma/prisma.service';
import { AuditService } from '../audit/audit.service';
import { STORAGE_SERVICE, StorageService } from '../media/storage/storage.interface';
import { Errors, editingError } from './editing.errors';
import { EXTENSION, MIME, detectFileKind, safeFileName } from './report-file-content';
import type { Owner } from './report-editing.service';

export interface UploadedReportFile {
  buffer: Buffer;
  originalname?: string;
}

const STATES: ReportFileState[] = [ReportFileState.ORIGINAL, ReportFileState.FINAL];

/**
 * Original and final report documents (Remote Editor spec v1.4 sections 5, 6 and 16). The phone makes the PDF and Word
 * files; the server stores them on the storage volume with their SHA-256 and never changes them afterwards.
 * - ORIGINAL: one per kind, written once. The same bytes again are accepted (a retry); different bytes are refused.
 * - FINAL: only once the report is finalised, one per edit cycle and kind, tied to the final version.
 */
@Injectable()
export class ReportFilesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly config: ConfigService,
    @Inject(STORAGE_SERVICE) private readonly storage: StorageService,
  ) {}

  get maxMb(): number {
    return Number(this.config.get('REPORT_FILE_MAX_MB', 60));
  }

  private async assertOwner(reportId: string, user: Owner) {
    const report = await this.prisma.report.findUnique({ where: { id: reportId } });
    if (!report) throw Errors.notFound();
    if (report.ownerUserId !== user.id && user.role !== UserRole.ADMIN) throw Errors.forbidden();
    return report;
  }

  private view(f: { id: string; state: ReportFileState; kind: ReportFileKind; fileName: string; size: number; sha256: string; cycle: number; version: number | null; createdAt: Date }) {
    return {
      id: f.id,
      state: f.state,
      kind: f.kind,
      fileName: f.fileName,
      size: f.size,
      sha256: f.sha256,
      cycle: f.cycle,
      version: f.version,
      createdAt: f.createdAt,
    };
  }

  async upload(user: Owner, reportId: string, file: UploadedReportFile | undefined, stateRaw: string, req?: Request) {
    const report = await this.assertOwner(reportId, user);
    const state = stateRaw as ReportFileState;
    if (!STATES.includes(state)) throw Errors.validation('state must be ORIGINAL or FINAL', 'state');
    if (!file || !file.buffer || file.buffer.length === 0) throw Errors.validation('a file is required', 'file');
    if (file.buffer.length > this.maxMb * 1024 * 1024) throw Errors.fileTooLarge(this.maxMb);

    const detected = detectFileKind(file.buffer);
    if (detected !== 'PDF' && detected !== 'DOCX') throw Errors.fileInvalid('The file must be a complete PDF or Word (.docx) document');
    const kind = detected as ReportFileKind;
    const cycle = report.editCycle;

    if (state === ReportFileState.FINAL) {
      if (report.status !== ReportStatus.FINALISED || report.finalVersion === null) {
        throw editingError(HttpStatus.CONFLICT, 'INVALID_STATE', 'Final documents can only be stored after the report is finalised', { status: report.status });
      }
    }

    const existing = await this.prisma.reportFile.findFirst({
      where: state === ReportFileState.ORIGINAL ? { reportId, state, kind } : { reportId, state, kind, cycle },
    });
    const incoming = createHash('sha256').update(file.buffer).digest('hex');
    if (existing) {
      if (existing.sha256 === incoming) return { ...this.view(existing), duplicate: true };
      throw Errors.fileExists(
        state === ReportFileState.ORIGINAL ? 'The original document is already stored and cannot be replaced' : 'The final document of this edit cycle is already stored',
        { fileId: existing.id },
      );
    }

    const id = randomUUID();
    const stored = await this.storage.storeVerified(`report-files/${reportId}`, id, file.buffer, EXTENSION[detected]);
    let row;
    try {
      row = await this.prisma.reportFile.create({
        data: {
          id,
          reportId,
          state,
          kind,
          fileName: safeFileName(file.originalname, `${state.toLowerCase()}.${EXTENSION[detected]}`),
          storagePath: stored.storagePath,
          size: stored.size,
          sha256: stored.sha256,
          cycle,
          version: state === ReportFileState.FINAL ? report.finalVersion : null,
          uploadedBy: user.id,
        },
      });
    } catch (error) {
      await this.storage.delete(stored.storagePath).catch(() => undefined); // a refused row leaves no file behind
      const code = (error as { code?: string }).code;
      if (code === 'P2002') throw Errors.fileExists('This document is already stored');
      throw error;
    }
    await this.audit.log({
      actorType: ActorType.STAFF,
      actorId: user.id,
      action: state === ReportFileState.ORIGINAL ? 'REPORT_ORIGINAL_FILE_STORED' : 'REPORT_FINAL_FILE_STORED',
      entityType: AuditEntityType.REPORT,
      entityId: reportId,
      metadata: { fileId: id, kind, size: stored.size, sha256: stored.sha256, cycle },
      request: req,
    });
    return { ...this.view(row), duplicate: false };
  }

  async list(user: Owner, reportId: string) {
    await this.assertOwner(reportId, user);
    const rows = await this.prisma.reportFile.findMany({ where: { reportId }, orderBy: [{ createdAt: 'asc' }] });
    return { files: rows.map((r) => this.view(r)) };
  }

  /** The stored file for an authorised owner. The bytes are checked against the stored SHA-256 before they are sent. */
  async forDownload(user: Owner, reportId: string, fileId: string) {
    await this.assertOwner(reportId, user);
    const row = await this.prisma.reportFile.findFirst({ where: { id: fileId, reportId } });
    if (!row) throw Errors.notFound();
    const actual = await this.storage.checksum(row.storagePath).catch(() => null);
    if (actual !== row.sha256) {
      throw editingError(HttpStatus.INTERNAL_SERVER_ERROR, 'FILE_INVALID', 'The stored file failed its integrity check');
    }
    const kind = row.kind as 'PDF' | 'DOCX' | 'ZIP';
    return { path: this.storage.getAbsolutePath(row.storagePath), mimeType: MIME[kind], fileName: row.fileName, sha256: row.sha256, size: row.size };
  }
}

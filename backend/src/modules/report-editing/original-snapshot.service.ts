import { Injectable } from '@nestjs/common';
import { MediaType, Prisma, UserRole } from '@prisma/client';
import { randomUUID } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';
import { Errors } from './editing.errors';
import type { Owner } from './report-editing.service';

type Tx = Prisma.TransactionClient;

export interface SnapshotMeta {
  treeVersionId?: string;
  phraseBankVersionId?: string;
  generatedAt?: string;
  appVersion?: string;
}

/**
 * The original report as the phone generated it (Remote Editor spec v1.4 sections 5.1 and 6.1). Captured once, in the same
 * transaction that creates the report; never changed afterwards (a database trigger enforces it). The checksum is the SHA-256
 * of the stored JSON as PostgreSQL writes it, computed by PostgreSQL, so it can be checked later with the same function.
 */
@Injectable()
export class OriginalSnapshotService {
  constructor(private readonly prisma: PrismaService) {}

  async capture(
    tx: Tx,
    p: { reportId: string; userId: string; reportType: string; content: unknown; meta: SnapshotMeta },
  ): Promise<void> {
    const survey = await tx.survey.findUniqueOrThrow({ where: { id: p.reportId } });
    const media = await tx.media.findMany({ where: { surveyId: p.reportId, deletedAt: null }, orderBy: [{ sortOrder: 'asc' }, { createdAt: 'asc' }] });
    const surveyType = p.reportType === 'VALUATION' ? 'VALUATION' : 'INSPECTION';
    const generatedAt = p.meta.generatedAt ? new Date(p.meta.generatedAt) : new Date();
    const snapshot = {
      schemaVersion: 1,
      surveyId: p.reportId,
      surveyType,
      treeVersionId: p.meta.treeVersionId ?? null,
      phraseBankVersionId: p.meta.phraseBankVersionId ?? null,
      generatedAt: generatedAt.toISOString(),
      appVersion: p.meta.appVersion ?? null,
      survey: { title: survey.title, propertyAddress: survey.propertyAddress, jobRef: survey.jobRef, clientName: survey.clientName },
      sections: p.content,
      media: media
        .filter((m) => m.type !== MediaType.SIGNATURE)
        .map((m) => ({ id: m.id, type: m.type, fileName: m.fileName, mimeType: m.mimeType, size: m.size, caption: m.caption, sortOrder: m.sortOrder, sectionKey: m.sectionKey })),
      signatures: media.filter((m) => m.type === MediaType.SIGNATURE).map((m) => ({ id: m.id, fileName: m.fileName, mimeType: m.mimeType, size: m.size })),
    };
    const json = JSON.stringify(snapshot);
    await tx.$executeRaw`
      INSERT INTO report_original_snapshots
        (id, report_id, schema_version, survey_type, tree_version_id, phrase_bank_version_id, generated_at, app_version, snapshot, checksum, created_by)
      VALUES
        (${randomUUID()}::uuid, ${p.reportId}::uuid, 1, ${surveyType}, ${p.meta.treeVersionId ?? null}, ${p.meta.phraseBankVersionId ?? null},
         (to_timestamp(${generatedAt.getTime() / 1000}) AT TIME ZONE 'UTC'), ${p.meta.appVersion ?? null},
         ${json}::jsonb, encode(sha256(convert_to((${json}::jsonb)::text, 'UTF8')), 'hex'), ${p.userId}::uuid)`;
  }

  /** The owner (or an admin) reads the original: the snapshot, whether it is still intact, and its original documents. */
  async read(user: Owner, reportId: string) {
    const report = await this.prisma.report.findUnique({ where: { id: reportId } });
    if (!report) throw Errors.notFound();
    if (report.ownerUserId !== user.id && user.role !== UserRole.ADMIN) throw Errors.forbidden();
    const rows = await this.prisma.$queryRaw<
      { id: string; schema_version: number; survey_type: string; tree_version_id: string | null; phrase_bank_version_id: string | null; generated_at: Date; app_version: string | null; snapshot: unknown; checksum: string; created_at: Date; intact: boolean }[]
    >`SELECT id, schema_version, survey_type, tree_version_id, phrase_bank_version_id, generated_at, app_version, snapshot, checksum, created_at,
             (encode(sha256(convert_to(snapshot::text, 'UTF8')), 'hex') = checksum) AS intact
      FROM report_original_snapshots WHERE report_id = ${reportId}::uuid`;
    if (rows.length === 0) throw Errors.notFound();
    const s = rows[0];
    const files = await this.prisma.reportFile.findMany({ where: { reportId, state: 'ORIGINAL' }, orderBy: { createdAt: 'asc' } });
    return {
      id: s.id,
      schemaVersion: s.schema_version,
      surveyType: s.survey_type,
      treeVersionId: s.tree_version_id,
      phraseBankVersionId: s.phrase_bank_version_id,
      generatedAt: s.generated_at,
      appVersion: s.app_version,
      checksum: s.checksum,
      intact: s.intact,
      createdAt: s.created_at,
      files: files.map((f) => ({ id: f.id, kind: f.kind, fileName: f.fileName, size: f.size, sha256: f.sha256 })),
      snapshot: s.snapshot,
    };
  }
}

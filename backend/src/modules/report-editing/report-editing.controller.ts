import { Body, Controller, Delete, Get, HttpCode, HttpStatus, Param, ParseIntPipe, ParseUUIDPipe, Post, Put, Query, Req, Res, StreamableFile, UploadedFile, UseGuards, UseInterceptors } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { createReadStream } from 'fs';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import { Request, Response } from 'express';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { ReportEditingService, Owner } from './report-editing.service';
import { ReportPhotosService } from './report-photos.service';
import { ReportFilesService } from './report-files.service';
import { OriginalSnapshotService } from './original-snapshot.service';
import { Errors } from './editing.errors';
import { ReportAuditService } from './report-audit.service';
import { ReportMediaService } from './report-media.service';
import { ReportArchiveService } from './report-archive.service';
import { ReportRetentionService } from './report-retention.service';
import { HoldReasonDto, RunRetentionDto } from './dto/retention.dto';
import { RestoreVersionDto, UploadSnapshotDto } from './dto/editing.dto';
import { AssignPhotosDto, ReviewActionDto, ReviewDecisionDto } from './dto/photos.dto';
import { ReviewService } from './review.service';
import { FinalisationService } from './finalisation.service';
import { FinaliseDto, ReopenDto } from './dto/finalise.dto';

/** App (owner) endpoints, spec section 16. {id} is the report id, which is the survey id. */
@ApiTags('Report editing')
@ApiBearerAuth('JWT-auth')
@Controller('reports')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN, UserRole.MANAGER, UserRole.SURVEYOR)
export class ReportEditingController {
  constructor(
    private readonly service: ReportEditingService,
    private readonly photos: ReportPhotosService,
    private readonly review: ReviewService,
    private readonly finalisation: FinalisationService,
    private readonly files: ReportFilesService,
    private readonly originals: OriginalSnapshotService,
    private readonly fieldAudit: ReportAuditService,
    private readonly media: ReportMediaService,
    private readonly archive: ReportArchiveService,
    private readonly retention: ReportRetentionService,
  ) {}

  /** What the cloud monitors for retention: coming deadlines, active holds, the deletion queue and its outcomes. Admin and Manager. */
  @Get('retention/overview')
  @Roles(UserRole.ADMIN, UserRole.MANAGER)
  retentionOverview(@CurrentUser() user: Owner) {
    return this.retention.overview(user);
  }

  /** Runs the retention job now (it also runs hourly). Admin only. `asOf` is for rehearsals and is refused in production. */
  @Post('retention/run')
  @HttpCode(HttpStatus.OK)
  @Roles(UserRole.ADMIN)
  runRetention(@Body() dto: RunRetentionDto) {
    if (dto.asOf && process.env.NODE_ENV === 'production') throw Errors.validation('asOf is not allowed in production', 'asOf');
    return this.retention.run(dto.asOf ? new Date(dto.asOf) : new Date(), { retryFailed: dto.retryFailed });
  }

  /** Restore a complete SurveyScriber archive (spec v1.4 section 14.2). multipart: file. Never overwrites an existing report. */
  @Post('restore-archive')
  @UseInterceptors(FileInterceptor('file', { limits: { fileSize: 256 * 1024 * 1024, files: 1, fields: 2 } }))
  restoreArchive(@CurrentUser() user: Owner, @UploadedFile() file: { buffer: Buffer; originalname?: string } | undefined, @Req() req: Request) {
    return this.archive.restore(user, file, req);
  }

  /** The complete archive ZIP of a report: documents, data, pictures, audit, manifest with checksums (spec v1.4 section 14.1). */
  @Post(':id/archive')
  @HttpCode(HttpStatus.OK)
  async buildArchive(@CurrentUser() user: Owner, @Param('id', ParseUUIDPipe) id: string, @Res({ passthrough: true }) res: Response, @Req() req: Request) {
    const a = await this.archive.export(user, id, req);
    res.set({
      'Content-Type': 'application/zip',
      'Content-Length': String(a.zip.length),
      'Content-Disposition': `attachment; filename="${a.fileName}"`,
      'X-Archive-Sha256': a.sha256,
      'X-Content-Type-Options': 'nosniff',
      'Cache-Control': 'private, no-store',
    });
    return new StreamableFile(a.zip);
  }

  /** Where the report stands in the retention policy: deadline, warnings, legal hold (spec section 15). */
  @Get(':id/retention')
  retentionOf(@CurrentUser() user: Owner, @Param('id', ParseUUIDPipe) id: string) {
    return this.retention.view(user, id);
  }

  /** A documented legal or complaint hold: the report is not deleted while it stands. Admin and Manager; the owner is told. */
  @Post(':id/legal-hold')
  @Roles(UserRole.ADMIN, UserRole.MANAGER)
  placeHold(@CurrentUser() user: Owner, @Param('id', ParseUUIDPipe) id: string, @Body() dto: HoldReasonDto, @Req() req: Request) {
    return this.retention.placeHold(user, id, dto.reason, req);
  }

  @Delete(':id/legal-hold')
  @HttpCode(HttpStatus.OK)
  @Roles(UserRole.ADMIN, UserRole.MANAGER)
  releaseHold(@CurrentUser() user: Owner, @Param('id', ParseUUIDPipe) id: string, @Body() dto: HoldReasonDto, @Req() req: Request) {
    return this.retention.releaseHold(user, id, dto.reason, req);
  }

  @Put(':id/snapshot')
  uploadSnapshot(@CurrentUser() user: Owner, @Param('id', ParseUUIDPipe) id: string, @Body() dto: UploadSnapshotDto, @Req() req: Request) {
    return this.service.uploadSnapshot(user, id, dto, req);
  }

  @Post(':id/edit-links')
  createLink(@CurrentUser() user: Owner, @Param('id', ParseUUIDPipe) id: string, @Req() req: Request) {
    return this.service.createLink(user, id, req);
  }

  @Get(':id/edit-links/current')
  currentLink(@CurrentUser() user: Owner, @Param('id', ParseUUIDPipe) id: string) {
    return this.service.currentLink(user, id);
  }

  @Delete(':id/edit-links/:linkId')
  @HttpCode(HttpStatus.OK)
  cancelLink(
    @CurrentUser() user: Owner,
    @Param('id', ParseUUIDPipe) id: string,
    @Param('linkId', ParseUUIDPipe) linkId: string,
    @Req() req: Request,
  ) {
    return this.service.cancelLink(user, id, linkId, req);
  }

  /** Original and final PDF/Word documents (spec v1.4 sections 5 and 16). multipart: file + state (ORIGINAL | FINAL). */
  @Post(':id/files')
  @UseInterceptors(FileInterceptor('file', { limits: { fileSize: 64 * 1024 * 1024, files: 1, fields: 4 } }))
  uploadFile(
    @CurrentUser() user: Owner,
    @Param('id', ParseUUIDPipe) id: string,
    @UploadedFile() file: { buffer: Buffer; originalname?: string } | undefined,
    @Body('state') state: string,
    @Req() req: Request,
  ) {
    return this.files.upload(user, id, file, state, req);
  }

  @Get(':id/files')
  listFiles(@CurrentUser() user: Owner, @Param('id', ParseUUIDPipe) id: string) {
    return this.files.list(user, id);
  }

  @Get(':id/files/:fileId')
  async downloadFile(
    @CurrentUser() user: Owner,
    @Param('id', ParseUUIDPipe) id: string,
    @Param('fileId', ParseUUIDPipe) fileId: string,
    @Res({ passthrough: true }) res: Response,
  ) {
    const f = await this.files.forDownload(user, id, fileId);
    res.set({
      'Content-Type': f.mimeType,
      'Content-Length': String(f.size),
      'Content-Disposition': `attachment; filename="${f.fileName.replace(/"/g, '')}"`,
      'X-Content-Type-Options': 'nosniff',
      'Cache-Control': 'private, no-store',
      ETag: `"${f.sha256}"`,
    });
    return new StreamableFile(createReadStream(f.path));
  }

  /** The original report as generated: snapshot, checksum, whether it is intact, and the original documents. */
  @Get(':id/original')
  original(@CurrentUser() user: Owner, @Param('id', ParseUUIDPipe) id: string) {
    return this.originals.read(user, id);
  }

  /** The amendment history: who changed which field from what to what, and the report's lifecycle events. */
  @Get(':id/audit')
  auditTrail(
    @CurrentUser() user: Owner,
    @Param('id', ParseUUIDPipe) id: string,
    @Query('sinceVersion') sinceVersion?: string,
    @Query('limit') limit?: string,
  ) {
    const num = (v?: string) => (v !== undefined && /^\d{1,9}$/.test(v) ? Number(v) : undefined);
    return this.fieldAudit.read(user, id, { sinceVersion: num(sinceVersion), limit: num(limit) });
  }

  /** What changed after a version: lets the phone see that the computer has newer edits, and where, without downloading the report. */
  @Get(':id/changes')
  async changes(@CurrentUser() user: Owner, @Param('id', ParseUUIDPipe) id: string, @Query('sinceVersion') sinceVersion?: string) {
    await this.service.assertOwner(user, id);
    return this.fieldAudit.changesSince(id, this.sinceOf(sinceVersion));
  }

  private sinceOf(raw?: string): number {
    if (raw === undefined || !/^\d{1,9}$/.test(raw)) throw Errors.validation('sinceVersion must be a whole number', 'sinceVersion');
    return Number(raw);
  }

  /** Every picture and signature of the report, also the replaced and deleted ones (nothing is destroyed). */
  @Get(':id/media')
  listMedia(@CurrentUser() user: Owner, @Param('id', ParseUUIDPipe) id: string) {
    return this.media.list(user, id);
  }

  /** The stored bytes of one picture, also a replaced or deleted one. */
  @Get(':id/media/:mediaId/file')
  async mediaFile(
    @CurrentUser() user: Owner,
    @Param('id', ParseUUIDPipe) id: string,
    @Param('mediaId', ParseUUIDPipe) mediaId: string,
    @Res({ passthrough: true }) res: Response,
  ) {
    const f = await this.media.file(user, id, mediaId);
    res.set({
      'Content-Type': f.mimeType,
      'Content-Length': String(f.size),
      'Content-Disposition': `inline; filename="${f.fileName.replace(/[^A-Za-z0-9._ -]/g, '_')}"`,
      'X-Content-Type-Options': 'nosniff',
      'Cache-Control': 'private, no-store',
      ETag: f.etag,
    });
    return new StreamableFile(createReadStream(f.path));
  }

  @Get(':id/media/:mediaId/annotations')
  getAnnotations(@CurrentUser() user: Owner, @Param('id', ParseUUIDPipe) id: string, @Param('mediaId', ParseUUIDPipe) mediaId: string) {
    return this.media.getAnnotations(user, id, mediaId);
  }

  /** The drawing the surveyor made on a photo (elements as plain data); an empty list removes it. */
  @Put(':id/media/:mediaId/annotations')
  putAnnotations(
    @CurrentUser() user: Owner,
    @Param('id', ParseUUIDPipe) id: string,
    @Param('mediaId', ParseUUIDPipe) mediaId: string,
    @Body() body: { annotations?: unknown },
    @Req() req: Request,
  ) {
    return this.media.putAnnotations(user, id, mediaId, body?.annotations, req);
  }

  @Get(':id/latest')
  latest(@CurrentUser() user: Owner, @Param('id', ParseUUIDPipe) id: string) {
    return this.service.latest(user, id);
  }

  @Post(':id/sync')
  @HttpCode(HttpStatus.OK)
  sync(@CurrentUser() user: Owner, @Param('id', ParseUUIDPipe) id: string, @Req() req: Request) {
    return this.service.sync(user, id, req);
  }

  /** The photos of this report for the phone: caption, section, order, and which ones were deleted since. */
  @Get(':id/photos')
  async listPhotos(@CurrentUser() user: Owner, @Param('id', ParseUUIDPipe) id: string, @Query('includeDeleted') includeDeleted?: string) {
    await this.service.latest(user, id); // owner or admin only
    return this.photos.list(id, { includeDeleted: includeDeleted === 'true' || includeDeleted === '1' });
  }

  /** The phone files its own photos under report sections (only photos nobody has organised yet). */
  @Post(':id/photos/assign')
  @HttpCode(HttpStatus.OK)
  async assignPhotos(@CurrentUser() user: Owner, @Param('id', ParseUUIDPipe) id: string, @Body() dto: AssignPhotosDto, @Req() req: Request) {
    await this.service.latest(user, id); // owner or admin only
    return this.photos.assign(id, { kind: 'owner', userId: user.id }, { expectedVersion: dto.expectedReportVersion, items: dto.items }, req);
  }

  // ---- Review workflow (spec section 14). The owner is the only one who can give the final approval. ----
  @Get(':id/review')
  async reviewView(@CurrentUser() user: Owner, @Param('id', ParseUUIDPipe) id: string) {
    await this.service.latest(user, id);
    return this.review.view(id, true);
  }

  @Post(':id/review/submit')
  @HttpCode(HttpStatus.OK)
  async reviewSubmit(@CurrentUser() user: Owner, @Param('id', ParseUUIDPipe) id: string, @Body() dto: ReviewActionDto, @Req() req: Request) {
    await this.service.latest(user, id);
    return this.review.act(id, { kind: 'owner', userId: user.id }, 'submit', { expectedVersion: dto.expectedReportVersion, comment: dto.comment }, req);
  }

  @Post(':id/review/start')
  @HttpCode(HttpStatus.OK)
  async reviewStart(@CurrentUser() user: Owner, @Param('id', ParseUUIDPipe) id: string, @Body() dto: ReviewActionDto, @Req() req: Request) {
    await this.service.latest(user, id);
    return this.review.act(id, { kind: 'owner', userId: user.id }, 'start', { expectedVersion: dto.expectedReportVersion, comment: dto.comment }, req);
  }

  /** The owner can send a report back. Approving as a reviewer is for link holders; the owner uses owner-approval. */
  @Post(':id/review/decision')
  @HttpCode(HttpStatus.OK)
  async reviewDecision(@CurrentUser() user: Owner, @Param('id', ParseUUIDPipe) id: string, @Body() dto: ReviewDecisionDto, @Req() req: Request) {
    await this.service.latest(user, id);
    return this.review.act(id, { kind: 'owner', userId: user.id }, dto.decision === 'APPROVED' ? 'approve' : 'amend', { expectedVersion: dto.expectedReportVersion, comment: dto.comment }, req);
  }

  @Post(':id/owner-approval')
  @HttpCode(HttpStatus.OK)
  async ownerApproval(@CurrentUser() user: Owner, @Param('id', ParseUUIDPipe) id: string, @Body() dto: ReviewActionDto, @Req() req: Request) {
    await this.service.latest(user, id);
    return this.review.act(id, { kind: 'owner', userId: user.id }, 'ownerApprove', { expectedVersion: dto.expectedReportVersion, comment: dto.comment }, req);
  }

  @Post(':id/review/reset')
  @HttpCode(HttpStatus.OK)
  async reviewReset(@CurrentUser() user: Owner, @Param('id', ParseUUIDPipe) id: string, @Body() dto: ReviewActionDto, @Req() req: Request) {
    await this.service.latest(user, id);
    return this.review.act(id, { kind: 'owner', userId: user.id }, 'reset', { expectedVersion: dto.expectedReportVersion, comment: dto.comment }, req);
  }

  /** Only the owner finalises, and only a version they approved. Ends every link and browser session. */
  @Post(':id/finalise')
  @HttpCode(HttpStatus.OK)
  finalise(@CurrentUser() user: Owner, @Param('id', ParseUUIDPipe) id: string, @Body() dto: FinaliseDto, @Req() req: Request) {
    return this.finalisation.finalise(user, id, dto.expectedReportVersion, req);
  }

  /** Explicit reopen of a finalised report: a new edit cycle; the earlier final version stays on record. */
  @Post(':id/reopen')
  @HttpCode(HttpStatus.OK)
  reopen(@CurrentUser() user: Owner, @Param('id', ParseUUIDPipe) id: string, @Body() dto: ReopenDto, @Req() req: Request) {
    return this.finalisation.reopen(user, id, dto.expectedReportVersion, dto.reason, req);
  }

  @Get(':id/finalisations')
  finalisations(@CurrentUser() user: Owner, @Param('id', ParseUUIDPipe) id: string) {
    return this.finalisation.history(user, id);
  }

  @Get(':id/versions')
  versions(@CurrentUser() user: Owner, @Param('id', ParseUUIDPipe) id: string) {
    return this.service.listVersions(user, id);
  }

  @Post(':id/versions/:version/restore')
  @HttpCode(HttpStatus.OK)
  restore(
    @CurrentUser() user: Owner,
    @Param('id', ParseUUIDPipe) id: string,
    @Param('version', ParseIntPipe) version: number,
    @Body() dto: RestoreVersionDto,
    @Req() req: Request,
  ) {
    return this.service.restoreVersion(user, id, version, dto.baseVersion, req);
  }
}

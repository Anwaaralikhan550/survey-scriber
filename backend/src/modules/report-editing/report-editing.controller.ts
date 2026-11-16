import { Body, Controller, Delete, Get, HttpCode, HttpStatus, Param, ParseIntPipe, ParseUUIDPipe, Post, Put, Query, Req, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import { Request } from 'express';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { ReportEditingService, Owner } from './report-editing.service';
import { ReportPhotosService } from './report-photos.service';
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
  ) {}

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

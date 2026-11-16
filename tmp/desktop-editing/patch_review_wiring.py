base = r'E:/survey-scriber/backend/src/modules/report-editing/'


def patch(name, pairs):
    p = base + name
    t = open(p, encoding='utf-8').read()
    for a, b in pairs:
        assert a in t, (name, a[:60])
        t = t.replace(a, b, 1)
    open(p, 'w', encoding='utf-8').write(t)


patch('review.service.ts', [
    ("import { Injectable } from '@nestjs/common';", "import { HttpStatus, Injectable } from '@nestjs/common';"),
    ("import { sanitizeText } from './report-content';\nimport { HttpStatus } from '@nestjs/common';", "import { sanitizeText } from './report-content';"),
])
patch('editing.errors.ts', [("  | 'CSRF_INVALID';", "  | 'CSRF_INVALID'\n  | 'INVALID_STATE';")])

t = open(base + 'dto/photos.dto.ts', encoding='utf-8').read()
t = t.replace("import { ArrayMaxSize, IsArray, IsInt,", "import { ArrayMaxSize, IsArray, IsIn, IsInt,", 1)
t += '''
export class ReviewActionDto extends ReplacePhotoDto {
  @IsOptional()
  @IsString()
  @MaxLength(4000)
  comment?: string;
}

export class ReviewDecisionDto extends ReviewActionDto {
  @IsIn(['APPROVED', 'AMENDMENTS_REQUIRED'])
  decision!: 'APPROVED' | 'AMENDMENTS_REQUIRED';
}
'''
open(base + 'dto/photos.dto.ts', 'w', encoding='utf-8').write(t)

patch('report-editing.module.ts', [
    ("import { ReportPhotosService } from './report-photos.service';", "import { ReportPhotosService } from './report-photos.service';\nimport { EditorReviewController } from './editor-review.controller';\nimport { ReviewService } from './review.service';"),
    ("controllers: [ReportEditingController, EditorController, EditorPhotosController],", "controllers: [ReportEditingController, EditorController, EditorPhotosController, EditorReviewController],"),
    ("    ReportPhotosService,\n    {", "    ReportPhotosService,\n    ReviewService,\n    {"),
    ("exports: [ReportEditingService, EditorSessionService, ReportPhotosService],", "exports: [ReportEditingService, EditorSessionService, ReportPhotosService, ReviewService],"),
])

owner_block = '''  // ---- Review workflow (spec section 14). The owner is the only one who can give the final approval. ----
  @Get(':id/review')
  async reviewView(@CurrentUser() user: Owner, @Param('id', ParseUUIDPipe) id: string) {
    await this.service.latest(user, id);
    return this.review.view(id);
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

  @Get(':id/versions')'''
patch('report-editing.controller.ts', [
    ("import { AssignPhotosDto } from './dto/photos.dto';", "import { AssignPhotosDto, ReviewActionDto, ReviewDecisionDto } from './dto/photos.dto';\nimport { ReviewService } from './review.service';"),
    ("    private readonly photos: ReportPhotosService,\n  ) {}", "    private readonly photos: ReportPhotosService,\n    private readonly review: ReviewService,\n  ) {}"),
    ("  @Get(':id/versions')", owner_block),
])
print('ok')

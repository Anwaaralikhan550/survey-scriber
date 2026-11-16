import { Body, Controller, Get, HttpCode, HttpStatus, Param, ParseUUIDPipe, Post, Req, UseGuards, UseInterceptors } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { Request } from 'express';
import { Public } from '../auth/decorators/public.decorator';
import { Errors } from './editing.errors';
import { EditorRequest, EditorSecurityHeadersInterceptor, EditorSessionGuard } from './editor.guard';
import { ReviewService } from './review.service';
import { ReviewActionDto, ReviewDecisionDto } from './dto/photos.dto';

/** Review workflow for the browser editor (spec section 14, Screen F). A link holder is a reviewer, never the owner. */
@ApiTags('Report editor review')
@Controller('editor/reports/:id/review')
@UseGuards(EditorSessionGuard)
@UseInterceptors(EditorSecurityHeadersInterceptor)
export class EditorReviewController {
  constructor(private readonly review: ReviewService) {}

  @Public()
  @Get()
  view(@Param('id', ParseUUIDPipe) id: string, @Req() req: EditorRequest) {
    if (req.editor.report.id !== id) throw Errors.forbidden();
    return this.review.view(id);
  }

  @Public()
  @Post('submit')
  @HttpCode(HttpStatus.OK)
  submit(@Param('id', ParseUUIDPipe) id: string, @Body() dto: ReviewActionDto, @Req() req: EditorRequest) {
    return this.review.act(id, { kind: 'session', ctx: req.editor }, 'submit', { expectedVersion: dto.expectedReportVersion, comment: dto.comment }, req as unknown as Request);
  }

  @Public()
  @Post('start')
  @HttpCode(HttpStatus.OK)
  start(@Param('id', ParseUUIDPipe) id: string, @Body() dto: ReviewActionDto, @Req() req: EditorRequest) {
    return this.review.act(id, { kind: 'session', ctx: req.editor }, 'start', { expectedVersion: dto.expectedReportVersion, comment: dto.comment }, req as unknown as Request);
  }

  @Public()
  @Post('decision')
  @HttpCode(HttpStatus.OK)
  decide(@Param('id', ParseUUIDPipe) id: string, @Body() dto: ReviewDecisionDto, @Req() req: EditorRequest) {
    const action = dto.decision === 'APPROVED' ? 'approve' : 'amend';
    return this.review.act(id, { kind: 'session', ctx: req.editor }, action, { expectedVersion: dto.expectedReportVersion, comment: dto.comment }, req as unknown as Request);
  }
}

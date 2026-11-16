import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  Put,
  Query,
  Req,
  Res,
  StreamableFile,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiTags } from '@nestjs/swagger';
import { SkipThrottle } from '@nestjs/throttler';
import { Request, Response } from 'express';
import { createReadStream } from 'fs';
import { Public } from '../auth/decorators/public.decorator';
import { Errors } from './editing.errors';
import { EditorContext, EditorSessionService } from './editor-session.service';
import { EditorRequest, EditorSecurityHeadersInterceptor, EditorSessionGuard } from './editor.guard';
import { PhotoActor, ReportPhotosService } from './report-photos.service';
import { PhotoMetaDto, PhotoUploadDto, ReplacePhotoDto } from './dto/photos.dto';

const MULTIPART = { limits: { fileSize: 12 * 1024 * 1024, files: 1, fields: 8 } };

/** Photo manager endpoints for the browser editor (spec sections 9 and 16). Session cookie + CSRF, like saving text. */
@ApiTags('Report editor photos')
@Controller('editor/reports/:id/photos')
@UseGuards(EditorSessionGuard)
@UseInterceptors(EditorSecurityHeadersInterceptor)
export class EditorPhotosController {
  constructor(
    private readonly photos: ReportPhotosService,
    private readonly sessions: EditorSessionService,
  ) {}

  private actor(ctx: EditorContext): PhotoActor {
    return { kind: 'session', sessionId: ctx.session.id, linkId: ctx.link.id };
  }

  /** Reads are allowed while read-only; every change needs an editable session on this report. */
  private forWrite(req: EditorRequest, id: string) {
    const ctx = req.editor;
    if (ctx.report.id !== id) throw Errors.forbidden();
    if (ctx.readOnly) throw ctx.readOnlyReason === 'REPORT_FINALISED' ? Errors.finalised() : Errors.linkExpired();
    return { actor: this.actor(ctx), guard: (tx: Parameters<EditorSessionService['assertWritable']>[0]) => this.sessions.assertWritable(tx, ctx) };
  }

  @Public()
  @Get()
  list(@Param('id', ParseUUIDPipe) id: string, @Req() req: EditorRequest) {
    if (req.editor.report.id !== id) throw Errors.forbidden();
    return this.photos.list(id);
  }

  /** A grid of thumbnails asks for many pictures at once; this is a cookie-checked read, so it is not rate limited. */
  @SkipThrottle({ default: true, short: true, medium: true, long: true })
  @Public()
  @Get(':photoId/file')
  async file(
    @Param('id', ParseUUIDPipe) id: string,
    @Param('photoId', ParseUUIDPipe) photoId: string,
    @Req() req: EditorRequest,
    @Res({ passthrough: true }) res: Response,
  ) {
    if (req.editor.report.id !== id) throw Errors.forbidden();
    const f = await this.photos.getFile(id, photoId);
    res.set({ 'Content-Type': f.mimeType, 'Content-Disposition': 'inline', 'Cache-Control': 'private, no-cache', ETag: f.tag, 'X-Content-Type-Options': 'nosniff' });
    return new StreamableFile(createReadStream(f.path));
  }

  @Public()
  @Post()
  @UseInterceptors(FileInterceptor('file', MULTIPART))
  upload(@Param('id', ParseUUIDPipe) id: string, @UploadedFile() file: Express.Multer.File, @Body() dto: PhotoUploadDto, @Req() req: EditorRequest) {
    const { actor, guard } = this.forWrite(req, id);
    return this.photos.upload(id, actor, file, { expectedVersion: dto.expectedReportVersion, sectionKey: dto.sectionKey, caption: dto.caption, guard }, req as unknown as Request);
  }

  @Public()
  @Put(':photoId')
  update(@Param('id', ParseUUIDPipe) id: string, @Param('photoId', ParseUUIDPipe) photoId: string, @Body() dto: PhotoMetaDto, @Req() req: EditorRequest) {
    const { actor, guard } = this.forWrite(req, id);
    return this.photos.update(
      id,
      photoId,
      actor,
      { expectedVersion: dto.expectedReportVersion, caption: dto.caption, sectionKey: dto.sectionKey, order: dto.order },
      guard,
      req as unknown as Request,
    );
  }

  @Public()
  @Post(':photoId/replace')
  @UseInterceptors(FileInterceptor('file', MULTIPART))
  replace(
    @Param('id', ParseUUIDPipe) id: string,
    @Param('photoId', ParseUUIDPipe) photoId: string,
    @UploadedFile() file: Express.Multer.File,
    @Body() dto: ReplacePhotoDto,
    @Req() req: EditorRequest,
  ) {
    const { actor, guard } = this.forWrite(req, id);
    return this.photos.replace(id, photoId, actor, file, { expectedVersion: dto.expectedReportVersion, guard }, req as unknown as Request);
  }

  @Public()
  @Delete(':photoId')
  remove(@Param('id', ParseUUIDPipe) id: string, @Param('photoId', ParseUUIDPipe) photoId: string, @Query() q: ReplacePhotoDto, @Req() req: EditorRequest) {
    const { actor, guard } = this.forWrite(req, id);
    return this.photos.remove(id, photoId, actor, { expectedVersion: q.expectedReportVersion, guard }, req as unknown as Request);
  }
}

import { Body, Controller, Get, HttpCode, HttpStatus, Param, ParseUUIDPipe, Patch, Post, Req, Res, UseGuards, UseInterceptors } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { ConfigService } from '@nestjs/config';
import { Request, Response } from 'express';
import { Public } from '../auth/decorators/public.decorator';
import { EditorSessionService } from './editor-session.service';
import { EDITOR_COOKIE, EditorRequest, EditorSecurityHeadersInterceptor, EditorSessionGuard } from './editor.guard';
import { OpenLinkDto, SaveChangesDto } from './dto/editing.dto';

/** Token attempts per IP (spec 17). Production defaults; the browser tests start the server with higher values. */
const OPEN_LIMITS = {
  perSecond: Number(process.env.EDITOR_OPEN_LIMIT_PER_SECOND ?? 3),
  perMinute: Number(process.env.EDITOR_OPEN_LIMIT_PER_MINUTE ?? 10),
  perHour: Number(process.env.EDITOR_OPEN_LIMIT_PER_HOUR ?? 30),
};

/** Browser editor endpoints, spec section 16. Authorised by the session cookie, not by the app's JWT. */
@ApiTags('Report editor')
@Controller('editor')
@UseInterceptors(EditorSecurityHeadersInterceptor)
export class EditorController {
  constructor(
    private readonly sessions: EditorSessionService,
    private readonly config: ConfigService,
  ) {}

  /** Exchange the link token for the session cookie. The page then removes the token from its URL. */
  @Public()
  @Post('open')
  @HttpCode(HttpStatus.OK)
  @Throttle({ short: { limit: OPEN_LIMITS.perSecond, ttl: 1000 }, medium: { limit: OPEN_LIMITS.perMinute, ttl: 60000 }, long: { limit: OPEN_LIMITS.perHour, ttl: 3600000 } })
  async open(@Body() dto: OpenLinkDto, @Req() req: Request, @Res({ passthrough: true }) res: Response) {
    const s = await this.sessions.open(dto.token, req);
    res.cookie(EDITOR_COOKIE, s.cookieValue, {
      httpOnly: true,
      secure: this.config.get('NODE_ENV') === 'production',
      sameSite: 'strict',
      path: '/api/v1/editor',
      expires: s.sessionExpiresAt,
    });
    return { reportId: s.reportId, csrfToken: s.csrfToken, sessionExpiresAt: s.sessionExpiresAt, linkExpiresAt: s.linkExpiresAt };
  }

  @Public()
  @UseGuards(EditorSessionGuard)
  @Post('close')
  @HttpCode(HttpStatus.OK)
  async close(@Req() req: EditorRequest, @Res({ passthrough: true }) res: Response) {
    const out = await this.sessions.close(req.editor, req);
    res.clearCookie(EDITOR_COOKIE, { path: '/api/v1/editor' });
    return out;
  }

  @Public()
  @UseGuards(EditorSessionGuard)
  @Get('reports/:id')
  read(@Param('id', ParseUUIDPipe) id: string, @Req() req: EditorRequest) {
    return this.sessions.read(req.editor, id);
  }

  @Public()
  @UseGuards(EditorSessionGuard)
  @Patch('reports/:id')
  save(@Param('id', ParseUUIDPipe) id: string, @Body() dto: SaveChangesDto, @Req() req: EditorRequest) {
    return this.sessions.save(req.editor, id, dto, req);
  }
}

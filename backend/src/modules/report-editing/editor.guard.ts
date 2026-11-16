import { CallHandler, CanActivate, ExecutionContext, Injectable, NestInterceptor } from '@nestjs/common';
import { Observable } from 'rxjs';
import { Request, Response } from 'express';
import { EditorContext, EditorSessionService } from './editor-session.service';
import { readCookie } from './token.util';

export const EDITOR_COOKIE = 'ss_editor';

export type EditorRequest = Request & { editor: EditorContext };

/** Checks the HttpOnly session cookie against the live link, and the CSRF header on every write. */
@Injectable()
export class EditorSessionGuard implements CanActivate {
  constructor(private readonly sessions: EditorSessionService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const req = context.switchToHttp().getRequest<EditorRequest>();
    const ctx = await this.sessions.authenticate(readCookie(req.headers.cookie, EDITOR_COOKIE));
    if (!['GET', 'HEAD', 'OPTIONS'].includes(req.method)) {
      this.sessions.verifyCsrf(ctx, req.headers['x-csrf-token'] as string | undefined);
    }
    req.editor = ctx;
    return true;
  }
}

/** Spec 17: no caching, no referrer, no indexing on the token page and the editor API. */
@Injectable()
export class EditorSecurityHeadersInterceptor implements NestInterceptor {
  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const res = context.switchToHttp().getResponse<Response>();
    res.setHeader('Cache-Control', 'no-store');
    res.setHeader('Referrer-Policy', 'no-referrer');
    res.setHeader('X-Robots-Tag', 'noindex, nofollow, noarchive');
    return next.handle();
  }
}

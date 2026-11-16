import os


def patch(p, a, b):
    t = open(p, encoding='utf-8', newline='').read()
    crlf = '\r\n' in t
    a2 = a.replace('\n', '\r\n') if crlf else a
    b2 = b.replace('\n', '\r\n') if crlf else b
    assert a2 in t, (p, a[:70])
    open(p, 'w', encoding='utf-8', newline='').write(t.replace(a2, b2, 1))


base = 'E:/survey-scriber/backend/src/'

# 1. a field belongs only on the block types that can hold it
patch(base + 'modules/report-editing/report-content.ts',
      "/** Validate and normalise one block. Throws ContentValidationError for anything malformed. */",
      """/** Which fields each kind of block may carry. A rating cannot sit on a paragraph, a table cannot hold text, and so on. */
const FIELDS_BY_TYPE: Record<BlockType, string[]> = {
  paragraph: ['text'],
  rating: ['rating', 'text'],
  recommendation: ['recommendation', 'text'],
  photo: ['photoId', 'text'],
  table: ['table'],
};

/** Validate and normalise one block. Throws ContentValidationError for anything malformed. */""")
patch(base + 'modules/report-editing/report-content.ts',
      "  const out: ContentBlock = { id, type, order: 0 };\n  if (b.required === true) out.required = true;",
      """  for (const key of ['text', 'rating', 'recommendation', 'photoId', 'table']) {
    if (b[key] !== undefined && !FIELDS_BY_TYPE[type].includes(key)) {
      throw new ContentValidationError(`a ${type} block cannot have ${key}`, `${path}.${key}`);
    }
  }
  const out: ContentBlock = { id, type, order: 0 };
  if (b.required === true) out.required = true;""")

# 2. guard errors carry the editor's security headers too
patch(base + 'modules/report-editing/editor.guard.ts',
      "    const req = context.switchToHttp().getRequest<EditorRequest>();\n    const ctx = await",
      """    const req = context.switchToHttp().getRequest<EditorRequest>();
    // Guards run before interceptors, so a refused request would otherwise reach the browser without these headers.
    setEditorHeaders(context.switchToHttp().getResponse<Response>());
    const ctx = await""")
patch(base + 'modules/report-editing/editor.guard.ts',
      """    const res = context.switchToHttp().getResponse<Response>();
    res.setHeader('Cache-Control', 'no-store');
    res.setHeader('Referrer-Policy', 'no-referrer');
    res.setHeader('X-Robots-Tag', 'noindex, nofollow, noarchive');
    return next.handle();""",
      """    setEditorHeaders(context.switchToHttp().getResponse<Response>());
    return next.handle();""")
patch(base + 'modules/report-editing/editor.guard.ts',
      "export const EDITOR_COOKIE = 'ss_editor';",
      """export const EDITOR_COOKIE = 'ss_editor';

function setEditorHeaders(res: Response): void {
  res.setHeader('Cache-Control', 'no-store');
  res.setHeader('Referrer-Policy', 'no-referrer');
  res.setHeader('X-Robots-Tag', 'noindex, nofollow, noarchive');
}""")

# 3. client errors raised by the body parser (too large, malformed JSON) are the client's 4xx, not a 500
patch(base + 'common/filters/http-exception.filter.ts',
      "    } else if (exception instanceof Error) {",
      """    } else if (this.clientErrorStatus(exception)) {
      // Errors from the body parser (http-errors): a body that is too large or not valid JSON is the caller's mistake.
      statusCode = this.clientErrorStatus(exception) as number;
      message = statusCode === HttpStatus.PAYLOAD_TOO_LARGE ? 'The request is too large' : 'The request could not be read';
      error = statusCode === HttpStatus.PAYLOAD_TOO_LARGE ? 'PayloadTooLarge' : 'BadRequest';
    } else if (exception instanceof Error) {""")
patch(base + 'common/filters/http-exception.filter.ts',
      "  catch(exception: unknown, host: ArgumentsHost) {",
      """  /** The 4xx status of an http-errors style error (body-parser), or 0 when it is not one. */
  private clientErrorStatus(exception: unknown): number {
    if (typeof exception !== 'object' || exception === null) return 0;
    const e = exception as { status?: unknown; statusCode?: unknown; type?: unknown };
    const status = typeof e.status === 'number' ? e.status : typeof e.statusCode === 'number' ? e.statusCode : 0;
    return status >= 400 && status < 500 && typeof e.type === 'string' ? status : 0;
  }

  catch(exception: unknown, host: ArgumentsHost) {""")
print('ok')

def rw(p, fn):
    t = open(p, encoding='utf-8', newline='').read()
    nl = '\r\n' if '\r\n' in t else '\n'
    t = fn(t.replace('\r\n', '\n'))
    open(p, 'w', encoding='utf-8', newline='').write(t.replace('\n', nl))


def sub(t, a, b):
    assert t.count(a) == 1, (t.count(a), a[:70])
    return t.replace(a, b, 1)


def es(t):
    t = sub(t, "import { ReportAuditService } from './report-audit.service';", "import { ReportAuditService } from './report-audit.service';\nimport { cleanReviewerName } from './reviewer-name';")
    t = sub(t, "{ reportId, version, actor: `session:${ctx.session.id}`, sessionId: ctx.session.id, source: 'BROWSER' }", "{ reportId, version, actor: `session:${ctx.session.id}`, actorName: ctx.session.reviewerName, sessionId: ctx.session.id, source: 'BROWSER' }")
    t = sub(t, "            savedBy: `session:${ctx.session.id}`,\n", "            savedBy: `session:${ctx.session.id}`,\n            savedByName: ctx.session.reviewerName,\n")
    t = sub(t, "      readOnlyReason: ctx.readOnlyReason ?? null,\n      content: r.content,", "      readOnlyReason: ctx.readOnlyReason ?? null,\n      reviewer: { name: ctx.session.reviewerName, verified: false },\n      content: r.content,")
    t = sub(t, "  verifyCsrf(ctx: EditorContext, header: string | undefined): void {", """  /**
   * The display name of the person using this link session (spec v1.4 sections 7 and 18). Typed, never verified; it is written
   * into the amendment history, the review entries and the version list from then on. A new session starts without a name.
   */
  async setReviewerName(ctx: EditorContext, raw: unknown, req?: Request) {
    const name = cleanReviewerName(raw);
    if (name === null) throw Errors.validation('Please enter your name (2 to 80 letters, no symbols)', 'name');
    await this.prisma.editorSession.update({ where: { id: ctx.session.id }, data: { reviewerName: name } });
    await this.log('REVIEWER_NAME_SET', ctx.report.id, req, { sessionId: ctx.session.id, linkId: ctx.link.id, name, verified: false });
    return { name, verified: false };
  }

  verifyCsrf(ctx: EditorContext, header: string | undefined): void {""")
    return t


rw('src/modules/report-editing/editor-session.service.ts', es)


def ctrl(t):
    t = sub(t, "import { OpenLinkDto, SaveChangesDto } from './dto/editing.dto';", "import { OpenLinkDto, ReviewerNameDto, SaveChangesDto } from './dto/editing.dto';")
    t = sub(t, "import { Body, Controller, Get, HttpCode, HttpStatus, Param, ParseUUIDPipe, Patch, Post, Req, Res, UseGuards, UseInterceptors } from '@nestjs/common';", "import { Body, Controller, Get, HttpCode, HttpStatus, Param, ParseUUIDPipe, Patch, Post, Put, Req, Res, UseGuards, UseInterceptors } from '@nestjs/common';")
    t = sub(t, "  @Public()\n  @UseGuards(EditorSessionGuard)\n  @Get('reports/:id')", """  /** The display name of the person using this link (typed, not verified). */
  @Public()
  @UseGuards(EditorSessionGuard)
  @Put('session/name')
  @HttpCode(HttpStatus.OK)
  setName(@Body() dto: ReviewerNameDto, @Req() req: EditorRequest) {
    return this.sessions.setReviewerName(req.editor, dto.name, req);
  }

  @Public()
  @UseGuards(EditorSessionGuard)
  @Get('reports/:id')""")
    return t


rw('src/modules/report-editing/editor.controller.ts', ctrl)


def dto(t):
    return t.rstrip('\n') + "\n\nexport class ReviewerNameDto {\n  @IsString()\n  @MaxLength(200)\n  name!: string;\n}\n"


rw('src/modules/report-editing/dto/editing.dto.ts', dto)


def aud(t):
    t = sub(t, "  sessionId?: string;\n  source: AuditSource;\n}", "  sessionId?: string;\n  /** The unverified display name of a link session. */\n  actorName?: string | null;\n  source: AuditSource;\n}")
    t = sub(t, "        actor: ctx.actor,\n        sessionId: ctx.sessionId ?? null,\n        source: ctx.source,\n      },\n    });\n  }", "        actor: ctx.actor,\n        actorName: ctx.actorName ?? null,\n        sessionId: ctx.sessionId ?? null,\n        source: ctx.source,\n      },\n    });\n  }")
    t = sub(t, "      actor: ctx.actor,\n      sessionId: ctx.sessionId ?? null,\n      source: ctx.source,\n    };", "      actor: ctx.actor,\n      actorName: ctx.actorName ?? null,\n      sessionId: ctx.sessionId ?? null,\n      source: ctx.source,\n    };")
    t = sub(t, "        actor: e.actor,\n        source: e.source,", "        actor: e.actor,\n        actorName: e.actorName,\n        actorNameVerified: false,\n        source: e.source,")
    return t


rw('src/modules/report-editing/report-audit.service.ts', aud)


def ai(t):
    return sub(t, "{ reportId, version: report.version, actor: `session:${ctx.session.id}`, sessionId: ctx.session.id, source: 'AI' }", "{ reportId, version: report.version, actor: `session:${ctx.session.id}`, actorName: ctx.session.reviewerName, sessionId: ctx.session.id, source: 'AI' }")


rw('src/modules/report-editing/ai-suggestion.service.ts', ai)


def rev(t):
    t = sub(t, "      by: r.reviewerUserId ? 'owner' : 'reviewer',\n", "      by: r.reviewerUserId ? 'owner' : 'reviewer',\n      // a link holder's typed name: never verified\n      reviewerName: r.reviewerUserId ? null : r.reviewerName,\n      nameVerified: false,\n")
    t = sub(t, "...(actor.kind === 'session' ? { sessionId: actor.ctx.session.id } : { reviewerUserId: actor.userId }),", "...(actor.kind === 'session' ? { sessionId: actor.ctx.session.id, reviewerName: actor.ctx.session.reviewerName } : { reviewerUserId: actor.userId }),")
    return t


rw('src/modules/report-editing/review.service.ts', rev)


def vers(t):
    return sub(t, "select: { version: true, savedBy: true, reason: true, createdAt: true },", "select: { version: true, savedBy: true, savedByName: true, reason: true, createdAt: true },")


rw('src/modules/report-editing/report-editing.service.ts', vers)
print('ok')

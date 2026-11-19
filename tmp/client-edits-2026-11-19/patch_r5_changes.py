def rw(p, fn):
    t = open(p, encoding='utf-8', newline='').read()
    nl = '\r\n' if '\r\n' in t else '\n'
    t = fn(t.replace('\r\n', '\n'))
    open(p, 'w', encoding='utf-8', newline='').write(t.replace('\n', nl))


def sub(t, a, b):
    assert t.count(a) == 1, (t.count(a), a[:70])
    return t.replace(a, b, 1)


def aud(t):
    return sub(t, "  /** The owner (or an admin) reads the history:", """  /**
   * What changed in the report after [sinceVersion] (spec v1.4 sections 10 and 17): the version and status now, and the sections
   * and blocks that were amended, from the amendment history. A phone or a browser asks this to know whether it is behind and
   * where, without downloading the report.
   */
  async changesSince(reportId: string, sinceVersion: number) {
    const report = await this.prisma.report.findUnique({ where: { id: reportId }, select: { version: true, status: true, content: true } });
    if (!report) throw Errors.notFound();
    const events = await this.prisma.reportAuditEvent.findMany({
      where: { reportId, reportVersion: { gt: sinceVersion } },
      orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
      select: { reportVersion: true, entityType: true, entityId: true, sectionId: true, sectionKey: true, field: true, op: true, source: true },
    });
    const titles = new Map<string, string>((report.content as unknown as ReportContent).map((s) => [s.id, s.title]));
    const sections = new Map<string, { sectionId: string; sectionKey: string | null; title: string | null; blockIds: Set<string>; fields: Set<string> }>();
    for (const e of events) {
      if (!e.sectionId || e.entityType === 'REPORT' || e.entityType === 'AI') continue;
      const s = sections.get(e.sectionId) ?? { sectionId: e.sectionId, sectionKey: e.sectionKey, title: titles.get(e.sectionId) ?? null, blockIds: new Set<string>(), fields: new Set<string>() };
      if (e.entityType === 'BLOCK' && e.entityId) s.blockIds.add(e.entityId);
      s.fields.add(e.field);
      sections.set(e.sectionId, s);
    }
    return {
      reportId,
      version: report.version,
      status: report.status,
      sinceVersion,
      changed: report.version > sinceVersion,
      fromPhone: events.some((e) => e.source === 'PHONE'),
      fromBrowser: events.some((e) => e.source === 'BROWSER'),
      restored: events.some((e) => e.source === 'RESTORE'),
      sections: [...sections.values()].map((s) => ({ sectionId: s.sectionId, sectionKey: s.sectionKey, title: s.title, blockIds: [...s.blockIds], fields: [...s.fields] })),
    };
  }

  /** The owner (or an admin) reads the history:""")


rw('src/modules/report-editing/report-audit.service.ts', aud)


def ctrl(t):
    marker = "  @Get(':id/latest')"
    add = """  /** What changed after a version: lets the phone see that the computer has newer edits, and where, without downloading the report. */
  @Get(':id/changes')
  async changes(@CurrentUser() user: Owner, @Param('id', ParseUUIDPipe) id: string, @Query('sinceVersion') sinceVersion?: string) {
    await this.service.assertOwner(user, id);
    return this.fieldAudit.changesSince(id, this.sinceOf(sinceVersion));
  }

  private sinceOf(raw?: string): number {
    if (raw === undefined || !/^\d{1,9}$/.test(raw)) throw Errors.validation('sinceVersion must be a whole number', 'sinceVersion');
    return Number(raw);
  }

"""
    t = sub(t, marker, add + marker)
    t = sub(t, "import { OriginalSnapshotService } from './original-snapshot.service';", "import { OriginalSnapshotService } from './original-snapshot.service';\nimport { Errors } from './editing.errors';")
    return t


rw('src/modules/report-editing/report-editing.controller.ts', ctrl)


def svc(t):
    return sub(t, "  private async assertReportOwner(reportId: string, user: Owner) {", "  /** The owner (or an admin) of the report; anyone else gets FORBIDDEN, a missing report NOT_FOUND. */\n  async assertOwner(user: Owner, reportId: string) {\n    return this.assertReportOwner(reportId, user);\n  }\n\n  private async assertReportOwner(reportId: string, user: Owner) {")


rw('src/modules/report-editing/report-editing.service.ts', svc)


def edctrl(t):
    t = sub(t, "  @Public()\n  @UseGuards(EditorSessionGuard)\n  @Get('reports/:id')", """  /** What changed after a version (for the browser to reconcile after a conflict). Allowed while read-only. */
  @Public()
  @UseGuards(EditorSessionGuard)
  @Get('reports/:id/changes')
  changes(@Param('id', ParseUUIDPipe) id: string, @Req() req: EditorRequest, @Query('sinceVersion') sinceVersion?: string) {
    if (req.editor.report.id !== id) throw Errors.forbidden();
    if (sinceVersion === undefined || !/^\d{1,9}$/.test(sinceVersion)) throw Errors.validation('sinceVersion must be a whole number', 'sinceVersion');
    return this.audit.changesSince(id, Number(sinceVersion));
  }

  @Public()
  @UseGuards(EditorSessionGuard)
  @Get('reports/:id')""")
    t = sub(t, "    private readonly sessions: EditorSessionService,\n    private readonly config: ConfigService,\n  ) {}", "    private readonly sessions: EditorSessionService,\n    private readonly config: ConfigService,\n    private readonly audit: ReportAuditService,\n  ) {}")
    t = sub(t, "import { OpenLinkDto, ReviewerNameDto, SaveChangesDto } from './dto/editing.dto';", "import { OpenLinkDto, ReviewerNameDto, SaveChangesDto } from './dto/editing.dto';\nimport { ReportAuditService } from './report-audit.service';\nimport { Errors } from './editing.errors';")
    t = sub(t, "import { Body, Controller, Get, HttpCode, HttpStatus, Param, ParseUUIDPipe, Patch, Post, Put, Req, Res, UseGuards, UseInterceptors } from '@nestjs/common';", "import { Body, Controller, Get, HttpCode, HttpStatus, Param, ParseUUIDPipe, Patch, Post, Put, Query, Req, Res, UseGuards, UseInterceptors } from '@nestjs/common';")
    return t


rw('src/modules/report-editing/editor.controller.ts', edctrl)
print('ok')

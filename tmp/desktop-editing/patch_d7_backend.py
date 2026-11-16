import os
os.chdir(r'E:/survey-scriber/backend/src/modules/report-editing')


def patch(p, a, b):
    t = open(p, encoding='utf-8', newline='').read()
    crlf = '\r\n' in t
    a2 = a.replace('\n', '\r\n') if crlf else a
    b2 = b.replace('\n', '\r\n') if crlf else b
    assert a2 in t, (p, a[:60])
    open(p, 'w', encoding='utf-8', newline='').write(t.replace(a2, b2, 1))


m = 'report-editing.module.ts'
patch(m, "import { ReviewService } from './review.service';", "import { ReviewService } from './review.service';\nimport { FinalisationService } from './finalisation.service';")
patch(m, "    AiSuggestionService,\n", "    AiSuggestionService,\n    FinalisationService,\n")
patch(m, "exports: [ReportEditingService,", "exports: [FinalisationService, ReportEditingService,")

c = 'report-editing.controller.ts'
patch(c, "import { ReviewService } from './review.service';", "import { ReviewService } from './review.service';\nimport { FinalisationService } from './finalisation.service';\nimport { FinaliseDto, ReopenDto } from './dto/finalise.dto';")
patch(c, "    private readonly review: ReviewService,\n  ) {}", "    private readonly review: ReviewService,\n    private readonly finalisation: FinalisationService,\n  ) {}")
patch(c, "  @Get(':id/versions')\n", """  /** Only the owner finalises, and only a version they approved. Ends every link and browser session. */
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
""")

s = 'editor-session.service.ts'
patch(s, "      throw Errors.linkRevoked();\n    }\n    if (session.revokedAt ||", "      // Finalising ends every link on purpose: say that, not that the link was cancelled.\n      throw LOCKED.includes(report.status) ? Errors.finalised() : Errors.linkRevoked();\n    }\n    if (session.revokedAt ||")
print('ok')

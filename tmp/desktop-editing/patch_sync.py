p = r'E:/survey-scriber/backend/src/modules/sync/sync.service.ts'
raw = open(p, encoding='utf-8', newline='').read()
crlf = '\r\n' in raw
t = raw.replace('\r\n', '\n')

old = "    try {\n      switch (operation.entityType) {\n        case SyncEntityType.SURVEY:\n          return await this.processSurveyOperation(tx, operation, user);"
new = ("    try {\n"
       "      // A finalised report is locked: the phone cannot change the survey behind it (desktop editing spec, section 15).\n"
       "      if (await this.isReportLocked(tx, operation)) {\n"
       "        return {\n"
       "          operationId: operation.operationId,\n"
       "          success: false,\n"
       "          error: 'REPORT_FINALISED: this report has been finalised and can no longer be changed',\n"
       "        };\n"
       "      }\n"
       "      switch (operation.entityType) {\n        case SyncEntityType.SURVEY:\n          return await this.processSurveyOperation(tx, operation, user);")
assert old in t
t = t.replace(old, new, 1)

anchor = "  private async processSurveyOperation("
helper = '''  /** True when the operation touches a survey whose editable report is finalising or finalised. */
  private async isReportLocked(
    tx: Parameters<Parameters<typeof this.prisma.$transaction>[0]>[0],
    operation: SyncOperationDto,
  ): Promise<boolean> {
    if (operation.operationType === SyncOperationType.CREATE) return false;
    let surveyId: string | undefined;
    if (operation.entityType === SyncEntityType.SURVEY) {
      surveyId = operation.entityId;
    } else if (operation.entityType === SyncEntityType.SECTION) {
      const section = await tx.section.findUnique({ where: { id: operation.entityId }, select: { surveyId: true } });
      surveyId = section?.surveyId;
    } else if (operation.entityType === SyncEntityType.ANSWER) {
      const answer = await tx.answer.findUnique({
        where: { id: operation.entityId },
        select: { section: { select: { surveyId: true } } },
      });
      surveyId = answer?.section.surveyId;
    }
    if (!surveyId) return false;
    const report = await tx.report.findUnique({ where: { id: surveyId }, select: { status: true } });
    return report?.status === ReportStatus.FINALISING || report?.status === ReportStatus.FINALISED;
  }

'''
assert t.count(anchor) == 1
t = t.replace(anchor, helper + anchor, 1)
open(p, 'w', encoding='utf-8', newline='').write(t.replace('\n', '\r\n') if crlf else t)
print('ok', crlf)

def rw(p, fn):
    t = open(p, encoding='utf-8', newline='').read()
    nl = '\r\n' if '\r\n' in t else '\n'
    t = fn(t.replace('\r\n', '\n'))
    open(p, 'w', encoding='utf-8', newline='').write(t.replace('\n', nl))


def sub(t, a, b):
    assert t.count(a) == 1, (t.count(a), a[:70])
    return t.replace(a, b, 1)


def pushdto(t):
    return sub(t, "  @ValidateNested({ each: true })\n  @Type(() => SyncOperationDto)\n  operations: SyncOperationDto[];\n}", """  @ValidateNested({ each: true })
  @Type(() => SyncOperationDto)
  operations: SyncOperationDto[];

  @ApiPropertyOptional({
    description:
      'Remote Editor: for surveys that were edited on a computer, the cloud report version this phone has taken. A change to such a survey is refused when the version is missing or older than the cloud report.',
    example: { '550e8400-e29b-41d4-a716-446655440000': 7 },
  })
  @IsOptional()
  @IsObject()
  reportVersions?: Record<string, number>;
}""")


rw('src/modules/sync/dto/sync-push.dto.ts', pushdto)


def respdto(t):
    return sub(t, "  duplicate?: boolean;\n}\n\nexport class SyncPushResponseDto {", """  duplicate?: boolean;

  @ApiPropertyOptional({
    description: 'Machine-readable reason when the change was refused on purpose (REPORT_VERSION_CONFLICT, REPORT_FINALISED)',
    example: 'REPORT_VERSION_CONFLICT',
  })
  errorCode?: string;

  @ApiPropertyOptional({
    description: 'REPORT_VERSION_CONFLICT: the cloud report version the phone has to synchronise to first',
    example: 8,
  })
  currentReportVersion?: number;
}

export class SyncPushResponseDto {""")


rw('src/modules/sync/dto/sync-response.dto.ts', respdto)


def svc(t):
    t = sub(t, "        const result = await this.processOperation(tx, operation, user);", "        const result = await this.processOperation(tx, operation, user, dto.reportVersions);")
    t = sub(t, "    const serverTimestamp = new Date();\n    const allSuccess = results.every((r) => r.success);",
            """    // A change refused because the survey was edited on a computer must be judged again on the retry:
    // forget the batch key, so the same batch is not answered "duplicate, success" later.
    if (results.some((r) => r.errorCode === 'REPORT_VERSION_CONFLICT')) {
      await this.prisma.syncIdempotency
        .deleteMany({ where: { userId: user.id, idempotencyKey: dto.idempotencyKey } })
        .catch(() => undefined);
    }

    const serverTimestamp = new Date();
    const allSuccess = results.every((r) => r.success);""")
    t = sub(t, "    operation: SyncOperationDto,\n    user: AuthenticatedUser,\n  ): Promise<SyncOperationResultDto> {\n    try {\n      // A finalised report is locked: the phone cannot change the survey behind it (desktop editing spec, section 15).\n      if (await this.isReportLocked(tx, operation)) {\n        return {\n          operationId: operation.operationId,\n          success: false,\n          error: 'REPORT_FINALISED: this report has been finalised and can no longer be changed',\n        };\n      }",
            """    operation: SyncOperationDto,
    user: AuthenticatedUser,
    reportVersions?: Record<string, number>,
  ): Promise<SyncOperationResultDto> {
    try {
      const refused = await this.reportGate(tx, operation, reportVersions);
      if (refused) return refused;""")
    old = t[t.index("  /** True when the operation touches a survey whose editable report is finalising or finalised. */"):t.index("  private async processSurveyOperation(")]
    new = """  /**
   * Remote Editor (spec v1.4 sections 10 and 11): the phone cannot change the survey behind a finalised report, and cannot
   * overwrite a survey that was edited on a computer with a copy that has not taken those edits (stale push). A refused change is
   * answered with a code the phone shows; nothing is applied and nothing is silently dropped. Returns null when the change may go on.
   */
  private async reportGate(
    tx: Parameters<Parameters<typeof this.prisma.$transaction>[0]>[0],
    operation: SyncOperationDto,
    reportVersions?: Record<string, number>,
  ): Promise<SyncOperationResultDto | null> {
    if (operation.operationType === SyncOperationType.CREATE) return null;
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
    if (!surveyId) return null;
    const report = await tx.report.findUnique({ where: { id: surveyId }, select: { status: true, version: true } });
    if (!report) return null;
    if (report.status === ReportStatus.FINALISING || report.status === ReportStatus.FINALISED) {
      return {
        operationId: operation.operationId,
        success: false,
        errorCode: 'REPORT_FINALISED',
        error: 'REPORT_FINALISED: this report has been finalised and can no longer be changed',
      };
    }
    const editedRemotely = (await tx.reportVersion.findFirst({ where: { reportId: surveyId, reason: 'SAVE' }, select: { id: true } })) !== null;
    if (!editedRemotely) return null;
    const known = reportVersions?.[surveyId];
    if (typeof known === 'number' && Number.isInteger(known) && known >= report.version) return null;
    return {
      operationId: operation.operationId,
      success: false,
      errorCode: 'REPORT_VERSION_CONFLICT',
      currentReportVersion: report.version,
      error: `REPORT_VERSION_CONFLICT: this report was edited on a computer (cloud version ${report.version}). Synchronise it on the phone first; your change is kept and will be sent afterwards.`,
    };
  }

"""
    t = t.replace(old, new)
    return t


rw('src/modules/sync/sync.service.ts', svc)
print('ok')

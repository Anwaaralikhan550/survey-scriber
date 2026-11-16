import re
base = r'E:/survey-scriber/backend/src/modules/report-editing/'

def patch(name, pairs):
    p = base + name
    t = open(p, encoding='utf-8').read()
    for old, new in pairs:
        assert old in t, (name, old[:70])
        t = t.replace(old, new, 1)
    open(p, 'w', encoding='utf-8').write(t)

IMPORT = "import { invalidateApprovalsAfterChange } from './review-effects';\n"

# 1. text save in the browser
patch('editor-session.service.ts', [
    ("import { newToken, safeEqualHex, sha256 } from './token.util';", "import { newToken, safeEqualHex, sha256 } from './token.util';\n" + IMPORT.strip()),
    ("    let result: { version: number; savedAt: Date };\n    try {", "    let result: { version: number; savedAt: Date; invalidated: boolean };\n    try {"),
    ("        return { version, savedAt: row.createdAt };\n      });",
     "        const invalidated = (await invalidateApprovalsAfterChange(tx, reportId, cur.status)) !== null;\n        return { version, savedAt: row.createdAt, invalidated };\n      });"),
    ("    await this.log('REPORT_SAVED', reportId, req, { sessionId: ctx.session.id, linkId: ctx.link.id, version: result.version });",
     "    await this.log('REPORT_SAVED', reportId, req, { sessionId: ctx.session.id, linkId: ctx.link.id, version: result.version });\n    if (result.invalidated) await this.log('REVIEW_INVALIDATED', reportId, req, { sessionId: ctx.session.id, version: result.version });"),
])

# 2. photo changes
patch('report-photos.service.ts', [
    ("import { sanitizeText } from './report-content';", "import { sanitizeText } from './report-content';\n" + IMPORT.strip()),
    ("    return this.prisma.$transaction(async (tx) => {\n      const rows = await tx.$queryRaw<{ version: number; status: ReportStatus; content: unknown }[]>`",
     "    const out = await this.prisma.$transaction(async (tx) => {\n      const rows = await tx.$queryRaw<{ version: number; status: ReportStatus; content: unknown }[]>`"),
    ("      return { version, result };\n    });\n  }\n\n  private async nextOrder",
     "      const invalidated = (await invalidateApprovalsAfterChange(tx, reportId, cur.status)) !== null;\n      return { version, result, invalidated };\n    });\n    if (out.invalidated) {\n      await this.audit.log({ actorType: actor.kind === 'owner' ? ActorType.STAFF : ActorType.SYSTEM, actorId: actor.kind === 'owner' ? actor.userId : undefined, action: 'REVIEW_INVALIDATED', entityType: AuditEntityType.REPORT, entityId: reportId, metadata: { version: out.version, cause: 'photo change' } });\n    }\n    return { version: out.version, result: out.result };\n  }\n\n  private async nextOrder"),
])

# 3. phone snapshot upload + 4. restore
patch('report-editing.service.ts', [
    ("import { newToken } from './token.util';", "import { newToken } from './token.util';\n" + IMPORT.strip()),
    ("      return { version: next, updatedAt: updated.updatedAt, created: false };",
     "      const invalidated = (await invalidateApprovalsAfterChange(tx, surveyId, locked.status)) !== null;\n      return { version: next, updatedAt: updated.updatedAt, created: false, invalidated };"),
    ("        return { version: created.version, updatedAt: created.updatedAt, created: true };",
     "        return { version: created.version, updatedAt: created.updatedAt, created: true, invalidated: false };"),
    ("    await this.log('REPORT_SNAPSHOT_UPLOADED', user, surveyId, req, { version: result.version, created: result.created });",
     "    await this.log('REPORT_SNAPSHOT_UPLOADED', user, surveyId, req, { version: result.version, created: result.created });\n    if (result.invalidated) await this.log('REVIEW_INVALIDATED', user, surveyId, req, { version: result.version, cause: 'new upload from the phone' });"),
    ("      return next;\n    });\n    await this.log('REPORT_VERSION_RESTORED', user, reportId, req, { restoredFrom: version, version: out });\n    return { reportId, version: out, restoredFrom: version };",
     "      const invalidated = (await invalidateApprovalsAfterChange(tx, reportId, locked.status)) !== null;\n      return { next, invalidated };\n    });\n    await this.log('REPORT_VERSION_RESTORED', user, reportId, req, { restoredFrom: version, version: out.next });\n    if (out.invalidated) await this.log('REVIEW_INVALIDATED', user, reportId, req, { version: out.next, cause: 'restore' });\n    return { reportId, version: out.next, restoredFrom: version };"),
])
print('ok')

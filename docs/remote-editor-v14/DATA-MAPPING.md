# Remote Editor v1.4: data-mapping note (R0, 19 Nov 2026)

What exists in the repo today (after D1-D8, backend deployed 17 Nov) against what v1.4 needs. Verified by reading the code, not from memory.

| v1.4 item | Exists | Where | Gap / action (step) |
|---|---|---|---|
| Survey/Section/Answer/Media reused | yes | `prisma/schema.prisma` | no parallel store; `Report.content` is the editable structured copy (blocks with UUIDs) |
| Editable copy + `reportVersion` | yes | `Report.version`, `ReportVersion` (full snapshot per save) | none |
| Immutable original snapshot | partly | `ReportVersion` v1 reason SNAPSHOT, but editable table, no tree/phrase version, no checksum | new `report_original_snapshots` + DB trigger (R2) |
| Original PDF/DOCX, final PDF/DOCX | no | server keeps only the uploaded survey PDF (`Survey.pdfPath`); DOCX not uploaded | `report_files` ORIGINAL/FINAL/ARCHIVE, phone uploads both (R1, R2) |
| One active 72 h link, hashed token, session, CSRF | yes | `EditLink`, `EditorSession`, `editor.guard.ts` | none |
| Reviewer name | no | session is anonymous | `EditorSession.reviewerName` (R4) |
| Version-checked save 409, idempotency | yes | `ReportEditingService` | none |
| Stale phone push rejected | no | `SyncService` only blocks FINALISING/FINALISED | check version for remotely edited surveys (R5) |
| Changes-since-version API | no | `GET /reports/:id/latest`, `POST /reports/:id/sync` return whole report | `changes?since=` (R5) |
| Field-level audit before/after | no | `AuditLog` rows hold lengths only on purpose | `report_audit_events` in the save transaction (R3) |
| Photo manager | yes | `report-photos.service.ts`, `image-processor.ts` | keep original on replace, annotations, signature audit (R6) |
| Storage abstraction | partly | `media/storage/storage.interface.ts` + `LocalStorageService` (UUID paths, outside web root, no checksum, not atomic) | add verified atomic store + checksum; reuse the interface and token `STORAGE_SERVICE` (R1) |
| Review/approval bound to version, finalise, reopen | yes | `review.service.ts`, `finalisation.service.ts`, `ReportFinalisation` | none |
| AI advisory | yes | `ai-suggestion.service.ts` | none |
| Archive ZIP export/restore | no | - | R7 |
| Retention, warnings, purge, legal hold | no | - | R8 (needs a scheduler; check `@nestjs/schedule` in package.json) |
| Roles Admin/Manager/Surveyor/Viewer | yes | `UserRole` enum, `RolesGuard` | legal hold uses Admin + Manager (R8) |
| Phone | Drift v22; sync queue; ExportBottomSheet generates PDF + Word | `lib/features/report_editing`, `lib/features/report_export` | upload originals/finals, remote-changes notice, conflict screen, archive buttons (R2, R5, R7) |
| Editor site live | no | nginx/TLS files ready in `tool/desktop_editor/deploy`; server `.env` has no `EDITOR_BASE_URL` | R9 (needs domain + server admin) |
| Backups | manual dumps only in `~/deploy-backups` (some older than 30 days) | server | server admin (policy text in R9) |

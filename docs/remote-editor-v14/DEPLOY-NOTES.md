# Remote Editor v1.4: deployment, backup and retention notes

Written 19 Nov 2026 (R9). Builds on `docs/desktop-editing/DEPLOYMENT.md` (the v1.3 editor, nginx, TLS, headers): read that first for the editor site itself.
**Nothing here has been deployed.** The live server (158.69.1.183) has migrations only up to `20261116120000`. Pushing, deploying and building the APK wait for the owner's go-ahead.

## 1. What changes for the server

| Part | Change |
|---|---|
| Database | 7 new migrations (section 2). All additive. One (`report_original_snapshots`) installs a trigger that makes originals immutable. |
| Backend | files, original snapshot, field-level audit, reviewer name, stale-write guard, media lineage, archive, retention (hourly job), legal hold. New dependency in `package.json`: `fflate` (already installed as a library of another package, now direct). |
| nginx | body limits for the phone's report routes (section 4). |
| Editor site | rebuilt (reviewer name dialog). Same hosting as v1.3. |
| Phone app | next APK: archive download/restore, retention card, legal hold (Admin/Manager), conflict screen, `file_picker` plugin (new). |

## 2. Migrations to apply, in this order

| Migration | What it does |
|---|---|
| `20261119090000_report_files` | `report_files`: original and final PDF/Word documents (SHA-256, one ORIGINAL per kind, one FINAL per edit cycle) |
| `20261119100000_report_original_snapshots` | immutable original of each report; trigger refuses UPDATE, DELETE only together with the report; backfills reports that already exist |
| `20261119110000_report_audit_events` | field-level history (before/after), append-only |
| `20261119120000_reviewer_name` | reviewer display name on sessions, versions, audit, reviews |
| `20261119130000_media_lineage` | `media.source`, `replaced_by_id`, `annotations`; marks existing browser-added pictures as EDITOR |
| `20261119140000_report_archive` | `reports.restored_at`, `report_audit_events.imported`, `report_archive_imports` |
| `20261119150000_report_retention` | `report_retention`, `report_legal_holds` (one active hold per report), `report_deletions` (queue and tombstones), 3 notification types |

Check afterwards: `npx prisma migrate diff --from-url "$DATABASE_URL" --to-schema-datamodel prisma/schema.prisma --exit-code` says "No difference detected".

Deploy sequence (the one used on 17 Nov): back up code and `pg_dump` into `~/deploy-backups`, upload the source tarball and the **locally built** `dist` (the server's own `nest build` fails with EACCES on `dist`), run `surveyscriber-deploy` (npm ci, migrate), swap the prebuilt `dist` in, `sudo systemctl restart surveyscriber-backend`. Take the storage volume backup in the same minute (section 5): a database backup without the file volume is incomplete.

## 3. Environment (new variables, backend)

| Variable | Default | Meaning |
|---|---|---|
| `REPORT_FILE_MAX_MB` | 60 | largest original/final PDF or Word document |
| `REPORT_ARCHIVE_MAX_MB` | 256 | largest archive ZIP that can be restored |
| `ARCHIVE_SIGNING_KEY` | falls back to `JWT_ACCESS_SECRET` | signs every archive manifest. **A restore only accepts archives signed with this key**, so keep it in the same secret backup as the database credentials, and set it explicitly (do not rely on the JWT secret, which may be rotated) before the first archive is made |
| `REPORT_RETENTION_DAYS` | 60 | finalised reports |
| `REPORT_DRAFT_RETENTION_DAYS` | 30 | drafts, from the last meaningful activity |
| `REPORT_RETENTION_WARNING_DAYS` | 30,45,55 | warning days for finalised reports |
| `REPORT_DRAFT_WARNING_DAYS` | 20,25,28 | warning days for drafts |
| `REPORT_PURGE_MAX_ATTEMPTS` | 8 | failed file deletions before an item waits for an operator |
| `REPORT_HOLD_RELEASE_GRACE_DAYS` | 7 | after a legal hold is released nothing is deleted for this long |
| `REPORT_RETENTION_STARTS_AT` | the first moment the job ran | the policy never counts from before this. **Set it explicitly to the day of the deploy**, so that reports that already exist get the full 30/60 days and their warnings, and nothing is deleted on the first run |
| `REPORT_RETENTION_ENABLED` | true | `false` stops the hourly job (the Admin route still works) |
| `EDITOR_BASE_URL`, `GEMINI_API_KEY` | not set on the server | still to be set when the editor goes live (see v1.3 notes) |

E-mail warnings use the existing SMTP settings (`SMTP_HOST` etc.); without them the notice is written to the backend log and the in-app notification is still created.

## 4. nginx: body limits

nginx stops a body before the backend sees it, so the phone's report routes need their own limits. They are in `tool/desktop_editor/deploy/editor-locations.conf` (editor host). **The API host that the phone uses needs the same three `location` blocks**:

```nginx
# server-wide default stays 13m (photos are at most 10 MB)
location ~ ^/api/v1/reports/[^/]+/files$ {            # original / final PDF and Word: up to 60 MB
    client_max_body_size 64m;  proxy_read_timeout 120s;  proxy_pass http://127.0.0.1:3000;  # + your usual proxy headers
}
location = /api/v1/reports/restore-archive {          # restore an archive: up to 256 MB, takes a while
    client_max_body_size 260m; proxy_read_timeout 300s;  proxy_send_timeout 300s;  proxy_pass http://127.0.0.1:3000;
}
location ~ ^/api/v1/reports/[^/]+/archive$ {          # building an archive reads every file of the report
    proxy_read_timeout 300s;   proxy_pass http://127.0.0.1:3000;
}
```

Without them the phone's original/final document upload and the archive restore fail with 413 for anything over 13 MB.

## 5. Backup policy (spec sections 15.3 and 16): what the code does, what the server admin must do

Spec: PostgreSQL **and** the persistent file volume are backed up off the server, encrypted, restore tested; backups of deleted data expire so deleted reports do not live on in recoverable backups for ever. The retention job deletes a purged report from the database and the volume immediately; the rolling backups below keep it for at most 30 more days.

**Server-admin tasks (not done by this project, listed for the owner):**

1. Nightly `pg_dump -Fc` of the SurveyScriber database **and** a copy of `MEDIA_LOCAL_ROOT` (`/home/ubuntu/surveyscriber-backend/storage`, contains `report-files/`), taken at the same time.
2. Encrypt before it leaves the server (age/gpg), copy off the server (other provider or storage box).
3. Rolling retention **30 days** at the destination: a backup file older than 30 days is deleted automatically. This is the documented "backup expiry" of spec 15.3.
4. Once a month restore the latest backup into a scratch database and scratch folder, and open a report with its pictures (the restore test of spec 16).
5. Keep `ARCHIVE_SIGNING_KEY` (and the other secrets) in a separate encrypted secret backup; without it archives made before cannot be restored.
6. Delete the old dumps that are already past the 30 days (list below), after the owner agrees.

### Old dumps found on the server on 19 Nov 2026 (read-only listing of `~/deploy-backups`, 274 MB, disk 44 % used)

Dumps that contain SurveyScriber **database content** (they hold real data and fall under the 30-day rule once they pass it; today none of these is older than 30 days, the expiry date is when it must go):

| File | Made | Size | Must be deleted by |
|---|---|---|---|
| `surveyscriber-db-20261023-093955.sql.gz` | 23 Oct 2026 | 0.2 MB | **22 Nov 2026** |
| `baseline_phrase_banks.sql` | 29 Oct 2026 | 0.5 MB | 28 Nov 2026 (phrase banks only, no reports) |
| `ss-db-20261106_105927.dump` | 6 Nov | 1.8 MB | 6 Dec 2026 |
| `ss-db-predeploy-20261106_123744.dump` | 6 Nov | 1.8 MB | 6 Dec 2026 |
| `ss-db-predeploy-20261110_132311.dump` | 10 Nov | 2.2 MB | 10 Dec 2026 |
| `ss-bank-before-20261114_055631.dump`, `ss-bank-before-20261114_105130.dump` | 14 Nov | 8.4 / 8.6 MB | 14 Dec 2026 |
| `ss-valbank-before-20261114_093911.dump`, `_103358.dump`, `_105132.dump` | 14 Nov | 8.5-8.7 MB | 14 Dec 2026 |
| `ss-db-predeploy-20261117_165559.dump` | 17 Nov | 9.5 MB | 17 Dec 2026 |

Older than 30 days already (code or other projects, no SurveyScriber report data seen by name; the owner should confirm before deleting):

| File or folder | Made | Size | Note |
|---|---|---|---|
| `~/surveyscriber-backend-backup-20260711_073043.tar.gz` | 11 Jul 2026 | 1.2 MB | old backend code backup; check that it holds no database export |
| `~/surveyscriber-backups/auth_lockout_20260713_103217/` | 13 Jul 2026 | small | `schema.prisma` and auth sources only |
| `~/deploy-backups/naija-before-.tar.gz` | 23 Sep 2026 | 206 MB | belongs to the `naija` site, not SurveyScriber |
| `~/deploy-backups/phase*_2026092*/` (14 folders) | 21-22 Sep 2026 | small | `naija` site deploy backups |
| `~/naija-pending-*.tar.gz`, `~/naija-secure-*.tar.gz` | 23 Sep 2026 | 0.2 MB each | `naija` site |

The code and source tarballs in `~/deploy-backups` (`ss-code-before-*`, `ss-release-*`, `backend-src-*`, `server-src-*`) hold no report data. A cron job (`backup-app-db.sh`, 02:30) belongs to the `naija` site; there is **no scheduled SurveyScriber backup yet**: every dump above was made by hand before a deploy. Setting the nightly job in step 1 is the first thing to do.

## 6. Retention in operation

The job runs hourly (`@Cron`) and can be run by an Admin at any time: `POST /api/v1/reports/retention/run` (`{"retryFailed": true}` also retries items that gave up). It is idempotent: run twice, same result.

Each run: (1) works out, for every report, the policy and the deadline from the report's own dates (finalised: 60 days from `finalised_at`; draft: 30 days from the last save/upload/workflow action; restored: from the restore); (2) sends the warning that is due, once (day 30/45/55 or 20/25/28), as an in-app notification and e-mail; (3) queues what has passed its deadline, unless a hold, a live edit link, a review in progress or a grace period stands in the way; (4) deletes queued reports: files first, then the database rows; (5) keeps only a tombstone (`report_deletions`: id, owner, dates, policy, outcome, number of files; no content).

Reports in review or finalising are never purged. A live edit link protects a draft while it lasts (72 hours).

**Monitoring** (`GET /api/v1/reports/retention/overview`, Admin or Manager): upcoming deadlines, active holds, queue size (`pending`, `failed`), purges in the last 30 days, last 20 purges. Backend log lines: `Retention run: {...}` when something happened; `Purge of <id> failed (attempt n)` for a file that could not be deleted (it retries after 5, 10, 20 ... minutes up to a day, then waits as FAILED after 8 attempts). Typical cause: a permission problem on the volume; fix it and run the job with `retryFailed`.

**Legal hold** (Admin or Manager, for any report): `POST /api/v1/reports/<id>/legal-hold {"reason": "..."}` (3 to 500 characters). It is recorded with who, role and when, audited (`REPORT_LEGAL_HOLD_PLACED`), the owner gets an in-app notice and an e-mail with the reason, and nothing is deleted while it stands. `DELETE` the same address with a reason releases it (`REPORT_LEGAL_HOLD_RELEASED`); the owner is told the earliest deletion date, which is at least 7 days later. Also available in the app on the report's "Edit on a computer" screen for Admin and Manager.

**Retention report for the owner** (run on the server database):

```sql
-- what will be deleted in the next 30 days
SELECT r.report_id, r.policy, r.delete_at FROM report_retention r
 WHERE r.delete_at < now() + interval '30 days'
   AND NOT EXISTS (SELECT 1 FROM report_legal_holds h WHERE h.report_id = r.report_id AND h.released_at IS NULL)
 ORDER BY r.delete_at;
-- active holds
SELECT report_id, placed_by_role, placed_at, reason FROM report_legal_holds WHERE released_at IS NULL;
-- the deletion queue and the tombstones
SELECT status, count(*) FROM report_deletions GROUP BY status;
SELECT report_id, policy, purged_at, files_deleted FROM report_deletions WHERE status = 'DONE' ORDER BY purged_at DESC LIMIT 20;
```

## 7. Smoke test after deploying v1.4 (15 minutes, in addition to the v1.3 list)

1. `GET /api/v1/reports/<id>/retention` as the owner: policy, deadline, three reminders listed.
2. App: Edit on a computer, report card shows "How long SurveyScriber keeps this report". Download complete archive: a ZIP arrives, the share sheet opens. Open it: `manifest.json`, `README.txt`, `original/`, `final/`, `audit/`.
3. In a scratch copy (or after the report is deleted by hand in a test database): Reports page, Restore archived report, choose the ZIP: report returns, marked "Restored from archive"; restoring it again is refused with "already in SurveyScriber".
4. Browser: open a link, enter a name; save; the app's history shows the name "(not verified)".
5. Place a legal hold on a test report as an Admin: owner notification arrives; `POST /api/v1/reports/retention/run`: the report stays; release it.
6. `curl -sS -o /dev/null -w "%{http_code}" -X POST -H "Content-Type: application/zip" --data-binary @big.bin https://<api>/api/v1/reports/restore-archive` with a 100 MB file: 401 (reaches the backend), not 413.

## 8. How this was verified (19 Nov 2026, re-runnable)

| What | Command | Result |
|---|---|---|
| Editor unit tests and build | `cd tool/desktop_editor && npm test && npm run build` | 10/10, built |
| Editor behind real nginx, with the v1.4 body-limit checks | start `nginx:1.27-alpine` with `tool/desktop_editor/deploy/*.conf`, backend on :3099 (`tmp/desktop-editing/run_backend_r9.cmd`), `node tmp/desktop-editing/p27_nginx.js` | 40/40 |
| Run everything on one PC | `powershell -File tool/desktop_editor/deploy/run-local.ps1` | editor and API answer on :5174 / the API port |
| Retention rules, every day of the 15.1 and 15.2 tables | `cd backend && npx jest src/modules/report-editing/retention.spec.ts` | 41/41 |
| Retention, purge, hold, archive end to end | `npx jest --config ./test/jest-e2e.json report-retention report-archive` | 47/47 |

## 9. Open items

- Everything above is local. No push, deploy, APK, bank publish, DNS, TLS or `EDITOR_BASE_URL` yet.
- The SurveyScriber backup job, off-server encryption and the 30-day rolling expiry are server-admin work (section 5).
- The phone does not yet send the question-tree and phrase-bank version ids with the original snapshot; they are stored as empty.
- A purged report is removed from the cloud only. The surveyor's phone keeps its own data.

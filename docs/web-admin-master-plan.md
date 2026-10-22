# SurveyScriber Web Admin — Master Plan

**Goal:** Move every function of the mobile in-app Admin Panel to a professional browser application
(desktop-first, tablet-friendly), talking to the same NestJS backend, with no loss of functionality,
no data loss, and a polished, international-standard UI/UX.

**Basis:** line-by-line analysis of `lib/features/admin/**` (≈20,500 Dart lines, 25+ screens),
`lib/features/booking_requests`, `lib/features/booking_change_requests`, the router/permission layer,
and `backend/src/**` (controllers, DTOs, guards, Prisma schema, deployment files). Nothing in this
plan was assumed — every gap below was found in the code (file:line in the appendix).

---

## 1. Executive summary

1. **Rebuilding as-is would copy 25 known defects.** The analysis found blocking bugs in today's mobile admin
   (e.g. Change Requests never load, invoice creation always fails, Invoice Detail crashes, only the
   first 20 users ever appear, tree edits never reach surveyors' phones). The web admin is built
   against the *backend contract*, and every defect is closed on the way (§9).
2. **The backend needs a short hardening phase before a browser client goes live**
   (see the private security notes), plus ~20 missing admin endpoints (create/deactivate users, clients API, tree versions/rollback, dashboard stats…).
3. **Survey Tree Manager needs a server-side draft model.** Today drafts live only in files on one
   phone; a website cannot read those. Drafts, backups and history move to the server.
4. **Tree edits only reach surveyors after one mobile-app release.** The app currently ignores
   published trees (`bundledTreeVersion` 7/3 forces the bundled asset, and the "latest tree"
   endpoint is ADMIN-only). One small app change + APK makes trees live like phrases already are.
5. **Recommended stack:** React 18 + TypeScript + Vite, TanStack Query/Table/Router, Radix-based
   component kit (shadcn/ui) + Tailwind, react-hook-form + zod, types generated from the backend
   OpenAPI file. Served as static files by Caddy/nginx on the same VPS, same origin as the API.
6. **Delivery:** 8 phases, each with tests and acceptance criteria; ~9–11 working weeks for one
   full-stack developer (≈6–7 with two). Mobile admin is retired only after sign-off (§12).

---

## 2. Scope — complete inventory to migrate

### 2.1 Screens that exist today (all migrate)

| # | Mobile screen | Route | Backend | Web module |
|---|---|---|---|---|
| 1 | Admin Dashboard (links + config version) | `/admin` | `config/version`, `config/all` | **Overview** (adds real KPIs) |
| 2 | User Management (list, change role) | `/admin/users` | `admin/config/users`, `…/:id/role` | **People › Staff** |
| 3 | Client Management (read-only, built from invoices) | `/admin/clients`, `/:id` | none (derived from `invoices`) | **People › Clients** (new API) |
| 4 | Invoices list / detail / create; issue, mark paid, cancel, PDF | `/admin/invoices…` | `invoices/*` | **Billing › Invoices** |
| 5 | Data Export (CSV: bookings, invoices, reports) | `/admin/exports` | `exports/*` | **Data › Exports** |
| 6 | Integrations hub | `/admin/integrations` | `webhooks` | **Integrations** |
| 7 | Webhooks list / create / detail / deliveries / test | `/admin/webhooks…` | `webhooks/*` | **Integrations › Webhooks** |
| 8 | Automation Guide (static docs) | `/admin/automation` | — | **Integrations › Developer guide** (corrected) |
| 9 | Audit Logs (filters, infinite scroll) | `/admin/audit-logs` | `audit-logs` | **Security › Audit log** |
| 10 | Booking Requests (approve / decline) — orphaned route | `/admin/booking-requests` | `booking-requests/*` | **Bookings › Requests** |
| 11 | Change Requests (approve / decline) — orphaned route | `/admin/change-requests` | `booking-changes/*` | **Bookings › Change requests** |
| 12 | Survey Tree Manager: sections, nodes, screens, fields, options, conditions, phrase templates, add/delete, reset, backups, restore, publish | `/admin/trees` | `admin/config/v2-tree/*` | **Survey Builder** |
| 13 | Phrase Templates (inspection bank) | inside Tree Manager | `admin/config/phrase-bank/*` | **Phrase Library** (both banks) |
| 14 | Phrase Portal (`tool/phrase_portal`, local Node tool) | — | `phrase-bank/*` | merged into **Phrase Library**, tool retired |

### 2.2 Built but unreachable in the app (decision D3)

`FieldManagementPage`, `SectionTypeManagementPage`, `PhraseManagementPage` (dropdown option lists) are
fully server-backed but have no route. Backend still serves their data via `config/all`.
Plan: include as **Settings › Legacy form config** behind a feature flag (Phase 7), with their four
known bugs fixed — or drop permanently if the client confirms they are unused.

### 2.3 Backend capabilities admins have never had (added because the web admin needs them)

Scheduling admin (surveyor availability/exceptions, delete booking), webhook delete + delivery filters,
invoice edit/delete of drafts and `paidDate`, request detail views + review notes, audit actor/entity
filters, metrics/health status. Each is listed in its module (§6) and can be descoped per decision D4.

---

## 3. Architecture

```
Browser (admin.<domain>)                   Application server
┌───────────────────────────┐   HTTPS    ┌─────────────────────────────────────┐
│ React SPA (static files)  │──────────▶│ Caddy (TLS, HSTS, gzip/brotli)      │
│  • TanStack Query cache   │            │   /            → /srv/admin-web     │
│  • access token in memory │            │   /api/*       → backend (internal) │
│  • refresh = httpOnly     │            └──────────────┬──────────────────────┘
│    cookie (path /api/v1/  │                           │ docker network only
│    auth)                  │                  NestJS backend ── Postgres 16
└───────────────────────────┘                  (backend reachable only via proxy)
Mobile app → https://api.<domain>/api/v1 (same backend, same Caddy)
```

- **Same origin** for web + API removes CORS complexity, lets the refresh token live in an
  httpOnly `Secure; SameSite=Strict` cookie (XSS cannot steal it), and lets `<a download>` and
  `Content-Disposition` work naturally.
- **No new server runtime**: the SPA is static files; deploy = upload `dist/` + Caddy reload.
- **Monorepo placement:** `admin-web/` at repo root next to `backend/` and `lib/`.
- **Contract safety:** `openapi-typescript` generates types from `backend/openapi.json` on every
  build; CI fails if the backend contract changes without the web types being regenerated.

### 3.1 Why not Flutter Web (reuse the mobile code)?

| Factor | Flutter Web | React SPA |
|---|---|---|
| Reuse | Partial — admin code imports `dart:io`, `path_provider`, `share_plus`, Drift (sqlite wasm); all must be rewritten anyway | none, but the mobile admin has 25 defects to rewrite regardless |
| Data-dense tables, multi-pane editors, keyboard, text selection, browser find, right-click | weak (canvas rendering) | native |
| First load | 2–4 MB+ CanvasKit | ~250 KB gzip target |
| Accessibility (screen readers, zoom) | limited | full WCAG 2.2 AA achievable |
| Hiring / maintenance | niche for web | mainstream |

**Recommendation: React SPA.** (Decision D1 — confirm.)

### 3.2 Front-end stack (pinned versions at start of Phase 1)

| Concern | Choice |
|---|---|
| Language/build | TypeScript (strict), Vite |
| Routing | TanStack Router (type-safe routes, search-param state for filters → shareable URLs) |
| Server state | TanStack Query (cache, retries, optimistic updates, background refetch) |
| Tables | TanStack Table + virtualization (`@tanstack/react-virtual`) |
| Components | shadcn/ui (Radix primitives: accessible dialogs, menus, popovers, comboboxes) |
| Styling | Tailwind CSS with design tokens (§5) |
| Forms | react-hook-form + zod (schemas mirror backend DTO rules) |
| Drag & drop | dnd-kit (keyboard-accessible reordering) |
| Charts | Recharts (Overview KPIs only) |
| Dates/money | date-fns (en-GB, Europe/London); money kept as integer pence, formatted with `Intl.NumberFormat('en-GB',{currency:'GBP'})` |
| Diff | `jsondiffpatch` (tree/phrase publish review) |
| Icons | Lucide |
| Tests | Vitest + Testing Library, MSW (API mocks), Playwright E2E against docker backend, axe-core |
| Quality gates | ESLint, Prettier, `tsc --noEmit`, bundle-size budget, Lighthouse CI |

---

## 4. Security & access model

### 4.1 Sessions (backend change B4)

- Login: `POST /auth/login` with header `X-Client: web` → backend returns access token in body and
  sets refresh token as httpOnly cookie (body field omitted for web). Mobile unchanged.
- Access token kept **in memory only**; silent refresh shortly before expiry; one in-flight
  refresh shared by all requests.
- Logout revokes the refresh cookie server-side. "Sign out everywhere" button (revokes all tokens).
- Idle timeout: 30 min of no activity → lock screen; absolute session cap = refresh lifetime (7 days).
- Cookie scoped to the auth endpoints with standard CSRF protections (details in private security notes).

### 4.2 Roles (decision D2 settles the open cells)

Today the app and backend disagree (Audit Logs, Webhooks, Users). Single source of truth = backend
`@Roles`; web reads the user's role from `/auth/me` and hides what the backend would refuse.

| Area | ADMIN | MANAGER | Notes |
|---|---|---|---|
| Overview | ✓ | ✓ | KPIs filtered to what the role may see |
| Staff users (list, invite, role, deactivate) | ✓ | — | backend ADMIN-only |
| Clients | ✓ | ✓ (read) / D2 | new API |
| Bookings requests / change requests | ✓ | ✓ | backend ADMIN+MANAGER |
| Invoices | ✓ | ✓ | VIEWER read-only if VIEWERs get web access (D2) |
| Exports | ✓ | ✓ | |
| Webhooks | ✓ | ✓ (backend allows; app blocked) | D2 |
| Audit log | ✓ | — (backend ADMIN-only; app let managers in → 403) | D2 |
| Survey Builder, Phrase Library | ✓ | — | backend ADMIN-only |
| SURVEYOR / VIEWER | no web admin access (friendly "not authorised" page with link to app) | | |

### 4.3 Hardening (backend changes B1–B3, B5)

- HTTPS everywhere with HSTS; backend reachable only through the reverse proxy.
- Strict CSP for the SPA (self-only sources, no inline scripts, no framing).
- Rate limiting tuned so a normal dashboard is never throttled while authentication endpoints stay strict.
- Correct proxy/client-IP handling, CORS exposed headers for downloads, production-only API docs policy.
- Every admin mutation audited.
- Specific findings and fixes are tracked in private security notes (not in this repository).

---

## 5. Design system & UX standard

**Brand continuity with the app:** primary navy `#1E3A5F`, secondary slate `#4A6572`, tertiary
`#6B5778`, error `#BA1A1A`, background `#F8FAFC`, font **Inter** (same as the app), tabular numerals
for money and counts.

### 5.1 Layout

- **App shell:** collapsible left sidebar (grouped: Overview · Bookings · People · Billing ·
  Survey Builder · Phrase Library · Data · Integrations · Security · Settings), top bar with global
  search (⌘K command palette), notifications bell (poll `notifications/unread-count` every 60 s),
  environment badge (Production / Staging in amber), user menu.
- **Content:** page header (title, breadcrumb, primary action on the right), filter bar, content.
  Max content width 1440 px; tables full-width; detail views as **right-side drawers** so the list
  context is kept (no full page jumps for quick actions).
- **Responsive:** ≥1280 full layout; 768–1279 sidebar collapses to icons, drawers become full-width;
  <768 read-mostly (lists + approve/decline work; Survey Builder shows "use a larger screen").

### 5.2 Interaction rules (apply to every screen)

| Rule | Detail |
|---|---|
| Loading | skeletons shaped like the final content; never blank pages; spinners only inside buttons |
| Empty states | illustration-free icon + one sentence + primary action ("No webhooks yet — Add webhook") |
| Errors | inline, specific, from backend `message`/`details` (validation errors mapped to fields); request ID shown in a "Copy details" link for support |
| Destructive actions | confirm dialog naming the object ("Cancel invoice INV-0042?"); type-to-confirm for irreversible ones (publish tree, rollback, deactivate admin) |
| Undo | toast with Undo for soft deletes (8 s), matching backend restore endpoints |
| Optimistic UI | status toggles, approve/decline; rollback on error with toast |
| Unsaved changes | dirty-state badge + browser `beforeunload` guard + route-leave dialog |
| Filters | live in the URL (shareable, back-button safe); "Clear all" + per-filter clear (fixes mobile bug) |
| Tables | sortable columns, column visibility, density toggle, sticky header, keyboard row navigation, page size 25/50/100 with server-side paging |
| Dates | `21 Oct 2026, 14:05` (en-GB, Europe/London), relative time on hover |
| Money | `£1,234.50`, right-aligned, from integer pence |
| Keyboard | ⌘K palette, `/` focus search, `g o` go overview, `Esc` closes drawer, Ctrl+S saves editors |
| Feedback | every mutation ends in a toast (success) or inline error; never silent |
| Dark mode | full token set for dark; follows OS, user override in menu |
| Motion | 150–200 ms ease-out for drawers/dialogs; respects `prefers-reduced-motion` |

### 5.3 Accessibility & quality bar

WCAG 2.2 AA: contrast ≥4.5:1, visible focus rings, all actions keyboard-reachable, ARIA via Radix,
form labels/descriptions, live regions for toasts, axe-core zero violations in CI.
Performance: initial JS ≤250 KB gzip, route chunks lazy-loaded, LCP <1.5 s on broadband,
interactions <100 ms, Survey Builder editing 3,353 fields without jank (virtualized lists).

---

## 6. Module-by-module specification

Each module lists screens, actions → endpoints, and mobile defects it fixes.

### 6.1 Overview (replaces Admin Dashboard)
- KPI cards: live bookings, pending booking requests, pending change requests, invoices
  outstanding (count + £), overdue invoices, surveys in progress/completed this month,
  failed webhook deliveries (24 h). Each card links to its pre-filtered list.
- "Needs attention" list (pending requests oldest first, overdue invoices, failed deliveries).
- System status strip: API health/version (`/health`, `/version`), config version, last tree and
  phrase publish (version, who, when).
- **Backend B10:** `GET /admin/overview` aggregate endpoint (one call; avoids rate-limit bursts).
- Fixes: dead `_StatCard`, no stats, missing request tiles.

### 6.2 Bookings
**Booking requests:** tabs All/Pending/Approved/Declined with counts; table (client, property,
preferred dates, submitted, status); drawer detail (`GET booking-requests/:id`); Approve with optional
review notes; Decline with reason (≤1000 chars, counter).
- Decision D5: approving a request today **does not create a booking**. Offer "Approve & create
  booking" that opens a prefilled booking form (surveyor, date, time) → `POST scheduling/bookings`.

**Change requests:** same pattern; side-by-side "current vs proposed" date/time; type badges
(Reschedule/Cancel); approve applies change (backend transaction).
- Fixes: wrong response parsing (`requests` vs `data/pagination`) that made the mobile screen always
  fail; orphaned routes; synchronous `initState` loads.

**Availability (new, optional D4):** per-surveyor weekly hours + exceptions
(`availability/:userId`, `availability/exceptions/:userId`); booking delete.

### 6.3 People
**Staff:** server-side paged/searchable table (`page, limit, q, role, isActive`) — shows all users, not 20;
columns name, email, role, status, last login, created.
- Actions: change role (blocks last admin + self-demotion, mirrored in UI with explanation),
  **invite user** (B6: `POST /admin/users` → email with set-password link reusing reset flow),
  **deactivate/reactivate** (B6), **send password reset** (B6), view user's audit trail
  (`audit-logs?actorId=`).
- Fixes: 20-user cap, swallowed 403 messages, `initials` crash on empty names.

**Clients:** (B7 new staff Clients API: list/search/paged, detail, create, edit, deactivate)
- Detail tabs: Profile · Bookings · Invoices · Requests · Portal access (send magic link).
- Fixes: clients derived from first 100 invoices only, blank emails, bookingCount always 0,
  `initials` crash, search clear icon.

### 6.4 Billing › Invoices
- List: status tabs with counts, date range, client filter, search by number; proper "load more" →
  real pagination (fixes list-replacing bug); overdue badge from server dates.
- Detail drawer/page: header, client, booking, line items, totals (pence-exact), notes, terms,
  cancellation info, activity timeline (from audit log).
- Actions by state machine: DRAFT → Edit · Delete · Issue; ISSUED → Mark paid (with **paid date**) ·
  Cancel (reason required); PAID/CANCELLED → read-only. PDF: open in new tab / download
  (`GET invoices/:id/pdf` as blob, filename from `Content-Disposition`).
- Create/Edit form: **client combobox (real client UUID)** or "from booking" (uses `Booking.clientId`
  — backend B13 exposes it), line-item grid with keyboard add/remove, VAT rate, due date, live totals.
- Fixes: create always 400 (email sent as `clientId`), Invoice Detail null-check crash,
  `/invoices/create` unguarded route, stale client after clearing booking.

### 6.5 Data › Exports
- Entity selector, date range, status, row limit up to backend max 10,000 (UI said 5,000), preview
  row count, download CSV via blob with server filename. Export history (from audit log `export.*`).
- Fixes: phone-only `path_provider`/`share_plus` flow.

### 6.6 Integrations
- **Webhooks list:** table with status, URL, events, last delivery result, success rate; enable/
  disable; delete (soft) — unused today.
- **Create/Edit:** URL validated as **HTTPS, public host** client-side (backend rule; mobile allowed
  http and failed vaguely), grouped event picker with select-all; secret shown once with copy +
  "I have stored it" confirmation.
- **Detail:** overview, deliveries table with filters (event, status, test) and real pagination
  (fixes `pagination` nesting bug), payload/response viewer (JSON, collapsible), "Send test event",
  "Redeliver" (if backend supports; else D4).
- **Developer guide:** regenerated from the backend enums: correct event list
  (adds BOOKING_CHANGE_APPROVED, INVOICE_ISSUED, REPORT_APPROVED; removes non-existent ones), correct
  signature header `X-Signature: sha256=…` + `X-Webhook-Event`, `X-Webhook-Version`, real payload
  sample, verification code snippets (Node, Python, PHP).

### 6.7 Security › Audit log
- Table with server paging (uses `data/meta`, not deprecated fields), filters: actor type, actor
  (user picker → `actorId`), entity type, entity id, action contains, date range; each filter
  individually clearable (mobile bug); row drawer shows **metadata JSON** (never shown on mobile),
  IP, user agent, request ID; CSV export of the current filter.

### 6.8 Survey Builder (replaces Survey Tree Manager) — the core module

**Server model first (backend B8):**
- `TreeDraft` table: one draft per tree type, `baseVersion`, `treeData`, `updatedBy`, `updatedAt`,
  `revision` (optimistic concurrency: every save sends `If-Match: revision`; 409 → "Another admin
  changed this draft" with reload/merge choice).
- Endpoints: `GET /admin/config/trees/:type` (published + draft status), `GET/PUT/DELETE …/draft`
  (create draft from latest published; save; discard = "Reset"), `POST …/draft/publish` (validates,
  creates version, deletes draft, idempotent by checksum, shrink guard), `GET …/versions` (list),
  `GET …/versions/:v`, `POST …/versions/:v/restore` (creates a new draft from an old version =
  rollback), `GET …/validate` (server validation report).
- Publish keeps unknown keys (e.g. `reportDefaults`) — the editor works on raw JSON nodes and only
  changes the edited properties, so **no silent data loss** (mobile drops unmodelled keys).
- Shared validation rules package used by backend and web (same TS code): duplicate ids, parent
  references, cross-section parents, condition targets, dropdown options, empty titles/labels,
  `conditionalMode` values, phrase-template `{fieldId}` references. Errors block publish; warnings
  are shown (mobile computed warnings but never displayed).

**Editor UX (three panes):**
1. **Left — Structure tree:** sections → groups → screens (true hierarchy from `parentId`, including
   cross-section parents), counts per node, search ("find field by id/label"), filter "only items
   with issues"; drag-and-drop reorder of sections, nodes (within/between groups) and fields
   (dnd-kit, keyboard accessible); right-click/⋯ menu: add screen/group, rename, move, duplicate,
   delete (shows how many descendants will be removed).
2. **Centre — Screen canvas:** the screen's fields as cards in form order, mirroring how the
   surveyor sees them; inline label edit; type badge; condition chip ("shown when D_ROOF = Pitched");
   add field between any two fields.
3. **Right — Inspector:** all properties of the selected field/screen with proper controls:
   type (with safe-change rules), label, id (auto-generated, unique, editable with live check),
   options editor (reorder, bulk paste, duplicates warned), **condition builder** (pick a field from a
   searchable list → operator → value from that field's options; advanced expression mode with
   syntax check for the 246 existing expressions), phrase template with `{field}` autocomplete and
   preview. Each change is one undoable step.

**Around the editor:**
- **Phone preview** toggle: renders the selected screen as the surveyor's form (read-only,
  conditions live-evaluated with test answers).
- **Undo/redo** (Ctrl+Z / Ctrl+Shift+Z), autosave of the draft every 3 s of inactivity with
  "Saved · 14:05" indicator, offline/409 handling.
- **Issues panel** (errors/warnings with "jump to").
- **Publish flow:** "Review changes" → diff grouped by section (added/removed/changed fields with
  before/after) → validation must be green → type `PUBLISH` → version N created → toast with
  "Phones receive this on next start". **Version history** drawer with restore (rollback).
- Fixes: Save Condition wiping phrase templates, `{field.id}` prefill trap, Remove Field without
  confirm, stale section view, hidden cross-section children, no reorder UI, restore without backup,
  local-only drafts/backups, last-publish-wins overwrites, no history/rollback.

**Make published trees reach phones (mobile change M1 + backend B8b):**
- Backend: `GET /config/v2-tree/:type?known=<checksum>` for any authenticated staff role (not
  ADMIN-only) with unchanged short-circuit (avoids 690 KB download each start).
- App: drop the `bundledTreeVersion` force-bundled branch → order becomes cache-checked server tree →
  bundled asset; remove admin local override path; refresh on resume (same pattern as phrase banks).
- Safety: app accepts a server tree only if it passes the same validation; otherwise keeps the
  previous one. Ongoing surveys keep their answers (existing screen re-init rules reviewed + tested).

### 6.9 Phrase Library (both banks; replaces in-app Phrase Templates + phrase portal)
- Bank switcher: Home Survey (1,256 phrases) · Valuation (495 templates, shows draft/approval meta).
- Virtualized list with search across key and text, filters: section, "changed since last
  publish", "has tokens", screen (valuation `screenId`).
- Editor: text area with **locked token chips** (`{TOKEN}` cannot be removed/renamed without
  explicit override + reason), live token diff, valuation `allowedTokens` enforced, character count,
  preview with sample values.
- Draft + publish exactly like trees (B9: phrase drafts, versions list, restore); token-set validation
  also server-side so no client can bypass it; publish diff; history and rollback.
- Valuation approval workflow (decision D6): "Mark as approved" sets `meta.reviewStatus` and is
  audited — the app's release-mode rule for draft banks keeps working.
- Retire `tool/phrase_portal` after sign-off (or keep as offline dev tool, read-only).

### 6.10 Settings (optional, Phase 7)
- Legacy form config (fields, section types, dropdown phrase categories) — only if D3 = keep;
  fixes slug hyphen/underscore 400, cannot-clear-values, wrong reorder indices,
  INSPECTION vs REINSPECTION naming.
- My profile, change password, sessions ("sign out everywhere").

---

## 7. Backend work list (all additive; mobile app keeps working)

| ID | Change | Phase |
|---|---|---|
| B1 | Domain + TLS reverse proxy; app URLs configured | 0 |
| B2 | Rate-limit tuning for browser use; tests | 0 |
| B3 | CORS exposed headers; production configuration review | 0 |
| B4 | Web session: httpOnly refresh cookie for web clients; sign-out-everywhere | 0 |
| B5 | Audit coverage check (role changes, user status, publishes, invoice transitions) | 0 |
| B6 | Staff users: invite (create + set-password email), deactivate/reactivate (revokes tokens), admin-triggered reset, last-login in list | 2 |
| B7 | Staff Clients API: list/search/paged, detail with counts, create, edit, deactivate, send portal link | 2 |
| B8 | Tree drafts + versions + restore + validate endpoints; publish idempotency + shrink guard; shared validator | 5 |
| B8b | Staff-readable `config/v2-tree/:type?known=` | 5 |
| B9 | Phrase-bank drafts, versions list/get/restore, server token-set validation, approval meta | 6 |
| B10 | `GET /admin/overview` aggregate KPIs | 1 |
| B11 | Contract fixes the web relies on: audit-log `data/meta` only; webhook deliveries `meta` consistent; keep old shapes for current app until M-release | 1–3 |
| B12 | Optional: "approve & create booking" transaction (D5); webhook redelivery (D4) | 3/4 |
| B13 | Expose `clientId` on bookings responses | 3 |
| B14 | OpenAPI regenerated in CI (`openapi.json` committed), used to generate web types | 0 |

## 8. Mobile app changes

| ID | Change | When |
|---|---|---|
| M1 | Trees load from server (cache + `known` checksum) instead of forced bundled asset; refresh on resume | with Phase 5 |
| M2 | Admin entry in Settings becomes "Open Web Admin" (opens browser) — after web sign-off | Phase 8 |
| M3 | Fix client-side "My change requests" parsing (same broken model as admin screen) | Phase 3 |
| M4 | Remove ~4 MB of bundled tree backup files from `pubspec.yaml` asset globs | Phase 5 |
| M5 | API base URL → `https://api.<domain>/api/v1` | Phase 0 (needs new APK) |

---

## 9. Defects closed by this plan (from the analysis)

| # | Defect in today's mobile admin | Closed in |
|---|---|---|
| 1 | Change Requests always error (response shape mismatch) | 6.2 / M3 |
| 2 | Invoice create always 400 (email as clientId) | 6.4 / B13 |
| 3 | Invoice Detail null-check crash on first frame and after errors | 6.4 |
| 4 | Invoice list "Load more" replaces instead of appends | 6.4 |
| 5 | Only first 20 users visible | 6.3 |
| 6 | Clients only from first 100 invoices; blank emails; bookingCount 0; initials crash | 6.3 / B7 |
| 7 | Webhook deliveries never page past 20 | 6.6 |
| 8 | Webhook create accepts http, backend rejects vaguely | 6.6 |
| 9 | Automation guide lists wrong events and wrong signature header | 6.6 |
| 10 | Audit filters cannot be cleared individually; metadata never shown | 6.7 |
| 11 | Role mismatches (audit, webhooks, users) → silent redirects / 403 | 4.2 |
| 12 | Booking/change request screens unreachable | 6.2 |
| 13 | Tree edits never reach surveyors (forced bundled tree; ADMIN-only latest endpoint) | 6.8 / M1 / B8b |
| 14 | Tree drafts/backups only on one phone; last publish silently overwrites others | 6.8 / B8 |
| 15 | Local override kept after publish pins that phone to its copy | M1 |
| 16 | Save Condition wipes phrase template | 6.8 |
| 17 | Phrase template prefilled `{field.id}` saved by accident | 6.8 |
| 18 | Unmodelled keys (`reportDefaults`) deleted on save | 6.8 |
| 19 | Remove Field without confirmation; empty titles/labels accepted; warnings never shown | 6.8 |
| 20 | No reorder UI; stale section view; cross-section children hidden | 6.8 |
| 21 | Restore overwrites without backup; no version history/rollback | 6.8 / B8 |
| 22 | Phrase editor: no search, no token protection, inspection only | 6.9 |
| 23–24 | Infrastructure/security hardening items (private security notes) | B1–B3 |
| 25 | Legacy config bugs (slug format, cannot clear values, reorder indices) | 6.10 (if kept) |

---

## 10. Phased delivery

Every phase ends with: unit + component tests green, Playwright E2E against docker Postgres +
real backend, axe 0 violations, review against §5 rules, demo/screenshots for the client,
commit per task. Nothing is deployed to production without explicit approval.

| Phase | Content | Est. (1 dev) | Exit criteria |
|---|---|---|---|
| **0 Foundations** | Decisions D1–D7; domain + TLS (B1); hardening (B2–B3); web sessions (B4); OpenAPI pipeline (B14); `admin-web` scaffold, design tokens, app shell, login/forgot/reset password, role gate, error/toast framework, CI | 1.5 wk | HTTPS login works end-to-end; refresh/logout/idle lock tested; Lighthouse ≥95 a11y |
| **1 Overview + Security** | B10 overview KPIs; Audit log module; system status | 0.5 wk | KPIs match DB counts in E2E seed |
| **2 People** | B6 staff actions; B7 clients API; Staff + Clients modules | 1.5 wk | invite→set password→login E2E; last-admin rules; 500-user seed paging |
| **3 Bookings + Billing** | Requests, change requests (M3), invoices full lifecycle + PDF, B13 | 1.5 wk | DRAFT→ISSUED→PAID and cancel E2E; pence-exact totals; PDF download name |
| **4 Data + Integrations** | Exports; webhooks (CRUD, deliveries, test, guide) | 1 wk | CSV opens in Excel with correct columns; webhook test against local receiver verifies signature |
| **5 Survey Builder** | B8/B8b, shared validator, three-pane editor, preview, diff, history/rollback; M1, M4 | 2.5–3 wk | round-trip of both real trees = byte-equal except edited props; concurrency 409 test; published tree reaches a test phone build |
| **6 Phrase Library** | B9; both banks; token lock; drafts/versions; approval; retire phrase portal | 1 wk | token-removal blocked server-side; rollback restores exact bank |
| **7 Settings & polish** | Legacy config (if D3), profile/sessions, dark mode QA, keyboard map, performance budget, full a11y audit, help tooltips | 0.5–1 wk | all §5.3 budgets met |
| **8 Cutover** | Staging soak with client; data checks; production deploy; M2 + M5 APK; mobile admin hidden; runbook | 0.5 wk | client sign-off checklist (§12) |

**Total ≈ 9.5–11 weeks** (one developer); parallelisable to ≈6–7 weeks (backend + frontend developer).

---

## 11. Testing strategy

| Level | What | Tool |
|---|---|---|
| Backend unit | every new service method (drafts, versions, invites, clients, overview, throttling) | Jest |
| Backend E2E | real Postgres in docker; auth cookie flow; role matrix (each endpoint × 4 roles) | Jest + supertest |
| Contract | web types generated from OpenAPI; CI fails on drift | openapi-typescript |
| Front-end unit/component | forms (zod rules = DTO rules), state machines (invoice), tree operations, token lock, diff | Vitest + Testing Library + MSW |
| Shared validator | runs over the real inspection (442 nodes / 3,353 fields) and valuation trees — must report 0 errors on current assets | Vitest |
| E2E | critical journeys per phase (login, invite, approve request, invoice lifecycle, export, webhook test, edit+publish tree, edit+publish phrase, rollback) | Playwright vs docker stack |
| Accessibility | every route | axe-core in Playwright |
| Visual | key screens light/dark, 1440 / 1024 / 390 widths | Playwright screenshots |
| Security | authz matrix, cookie flags, CSP, rate limits, token reuse, XSS in phrase/text fields | automated + manual checklist |
| Mobile regression | M1 tree loading (online, offline, corrupt server tree, mid-survey update) | flutter test |

---

## 12. Cutover & rollback

1. Staging (`staging-admin.<domain>`) with a copy of production data (anonymised clients) for client UAT.
2. Sign-off checklist: every row of §2.1 performed on web by the client; §9 defects re-tested.
3. Production deploy of backend (additive, backward compatible) → web admin → APK with M1/M2/M5.
4. Mobile admin stays available (hidden behind Settings) for one release as fallback, then removed.
5. Rollback: web is static (redeploy previous `dist/`); backend changes are additive (old app keeps
   working); trees/phrases can roll back via version history in one click.

---

## 13. Decisions needed from you / the client

| ID | Decision | Recommendation |
|---|---|---|
| D1 | Front-end technology | React SPA (§3.1) |
| D2 | Manager/Viewer access: audit log, webhooks, clients, invoices read-only for Viewer? | follow backend: Manager = operations, Admin = everything |
| D3 | Keep legacy form-config screens (fields, section types, dropdown phrases)? | confirm unused → drop |
| D4 | Add new capabilities (availability admin, webhook redelivery, booking delete) in v1? | availability yes; others later |
| D5 | Approving a booking request should create a booking? | yes, "Approve & create booking" |
| D6 | Who approves the valuation phrase bank (meta reviewStatus)? | admin with audit trail |
| D7 | Domain name for `admin.` / `api.` (needed for HTTPS) | client's own domain |
| D8 | Hosting: same VPS (recommended) vs separate static host | same VPS behind Caddy |

---

## Appendix A — key code references

- Router admin guard: `lib/app/router/app_router.dart:286-310`; permissions `lib/core/permissions/permission.dart:54-105`
- Tree runtime forced bundled: `lib/core/database/base_survey_repository.dart:57-123`; versions
  `inspection_repository.dart:15`, `valuation_repository.dart:12`
- Tree admin local files/publish: `lib/features/admin/data/tree_admin_repository.dart:83-187, 726-781`
- Save Condition wipes template: `tree_admin_repository.dart:327-338`
- Change-request parsing bug: `lib/features/booking_change_requests/data/models/booking_change_request_model.dart:222-231`
- Invoice clientId bug: `lib/features/admin/invoices/presentation/providers/admin_invoices_providers.dart:550-554`;
  DTO `backend/src/modules/invoices/dto/invoice.dto.ts:73-76`
- Webhook deliveries paging: `lib/features/admin/data/models/webhook_model.dart:100-106` vs
  `backend/src/modules/webhooks/webhooks.service.ts:343-349`
- Tree/phrase endpoints: `backend/src/modules/config/config.controller.ts`, `config.service.ts:1312-1717`

const fs = require('fs');
const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell, WidthType, ShadingType,
  BorderStyle, AlignmentType, HeadingLevel, LevelFormat,
} = require('docx');

const FONT = 'Arial';
const border = { style: BorderStyle.SINGLE, size: 4, color: 'BFBFBF' };
const borders = { top: border, bottom: border, left: border, right: border };
const W2 = [2600, 6426];
const W3 = [2300, 3363, 3363];

const run = (text, o = {}) => new TextRun({ text, font: FONT, size: o.size || 20, bold: !!o.bold, color: o.color || '000000' });
const cell = (text, w, head) => new TableCell({
  width: { size: w, type: WidthType.DXA }, borders,
  margins: { top: 80, bottom: 80, left: 100, right: 100 },
  shading: head ? { type: ShadingType.CLEAR, fill: '1F3864' } : undefined,
  children: String(text).split('\n').map((line) => new Paragraph({ spacing: { after: 40 }, children: [run(line, { bold: !!head, color: head ? 'FFFFFF' : '000000' })] })),
});
const table = (widths, head, rows) => new Table({
  width: { size: 9026, type: WidthType.DXA }, columnWidths: widths,
  rows: [
    new TableRow({ tableHeader: true, children: head.map((t, i) => cell(t, widths[i], true)) }),
    ...rows.map((r) => new TableRow({ cantSplit: true, children: r.map((t, i) => cell(t, widths[i])) })),
  ],
});
const h = (t) => new Paragraph({ heading: HeadingLevel.HEADING_1, children: [new TextRun({ text: t, font: FONT })] });
const p = (t) => new Paragraph({ spacing: { after: 120 }, children: [run(t, { size: 22 })] });
const bullet = (t) => new Paragraph({ numbering: { reference: 'bul', level: 0 }, spacing: { after: 40 }, children: [run(t, { size: 22 })] });

const doc = new Document({
  styles: {
    default: { document: { run: { font: FONT, size: 22 } } },
    paragraphStyles: [
      { id: 'Title', name: 'Title', basedOn: 'Normal', run: { font: FONT, size: 40, bold: true, color: '1F3864' }, paragraph: { spacing: { before: 0, after: 120 } } },
      { id: 'Heading1', name: 'Heading 1', basedOn: 'Normal', next: 'Normal', quickFormat: true, run: { font: FONT, size: 26, bold: true, color: '1F3864' }, paragraph: { spacing: { before: 320, after: 120 }, keepNext: true, outlineLevel: 0 } },
    ],
  },
  numbering: { config: [{ reference: 'bul', levels: [{ level: 0, format: LevelFormat.BULLET, text: '\u2022', alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 540, hanging: 270 } } } }] }] },
  sections: [{
    properties: { page: { size: { width: 11906, height: 16838 }, margin: { top: 1134, right: 1440, bottom: 1134, left: 1440 } } },
    children: [
      new Paragraph({ style: 'Title', children: [new TextRun({ text: 'SurveyScriber: current system, confirmation', font: FONT })] }),
      p('Reply to your five questions for the Secure Desktop Report Editing specification v1.3. 16 November 2026. Everything below was checked against the current SurveyScriber code, not written from memory.'),

      h('1. Current technology stack'),
      table(W2, ['Part', 'What is used today'], [
        ['Mobile app', 'Flutter (Dart 3.5 or newer). State: Riverpod. Navigation: go_router. HTTP: dio.\nLocal database on the phone: SQLite through drift (schema version 22).\nPDF: the "pdf" package. Word: built in the app by our own code (a .docx is a zip of XML files).'],
        ['Backend', 'NestJS 10 on Node 20, TypeScript. ORM: Prisma 6.\nAuthentication: JWT access token (15 minutes) plus refresh token. Roles: Admin, Manager, Surveyor, Viewer.\nRate limiting, security headers (helmet), audit log, and an AI module are present.'],
        ['Database', 'PostgreSQL 16.'],
        ['File storage', 'Photos and signatures are stored on the server disk (a persistent volume). There is no S3 or other object storage yet.'],
        ['Hosting', 'One VPS, backend packaged with Docker, nginx in front. The admin portal is a static web app on the same server.'],
        ['Admin portal', 'Plain JavaScript web app (login, phrase banks, report trees, users). Phones read the published phrase banks and trees from the backend.'],
      ]),

      h('2. Existing report data structure'),
      p('A report is not stored as one document. It is stored as a survey plus its answers, built from a published tree:'),
      table(W3, ['Item', 'On the phone (SQLite)', 'In the cloud (PostgreSQL)'], [
        ['Report header', 'surveys (id, type, status, job reference, address, client, dates)', 'Survey (same fields, owner user, soft delete, PDF path)'],
        ['Sections / screens', 'inspection_v2_screens (section key, screen, title, order, completed, generated text, manual-edit flag, surveyor note)', 'Section (section type key, order, generated text, notes)'],
        ['Answers', 'inspection_v2_answers (survey, screen, field, value text)', 'Answer (section, key "screen::field", value text)'],
        ['Photos', 'media_items (path, caption, order, status, annotations flag) and photo_annotations', 'Media (file name, type, size, storage path). No caption or order in the cloud yet.'],
        ['Signatures', 'signatures (strokes, signer, role, preview)', 'Media of type SIGNATURE'],
      ]),
      bullet('The structure (sections, screens, fields, options) comes from a JSON tree: assets/property_inspection/inspection_tree.json (Home Survey) and assets/property_valuation/valuation_tree.json (Valuation). Published copies are versioned on the server.'),
      bullet('The wording comes from a phrase bank (about 1,256 inspection phrases and about 495 valuation templates) plus the phrase engine in the app.'),
      bullet('IDs are stable UUIDs. For the new tree format they are derived deterministically from the survey, screen and field, so the same answer always has the same ID on every device.'),
      bullet('Today there is no integer version number on a report. Only an updated-at time stamp exists. This is one of the gaps for the spec (see the end).'),

      h('3. Current report generation process'),
      bullet('Reports are generated on the surveyor\'s phone, offline, from the saved answers: answers + tree + phrase bank, then the phrase engine writes the sentences, then ReportBuilder lays out sections, tables, photos and signatures, then one renderer writes the PDF and another writes the Word file.'),
      bullet('The server does not build reports. It stores the PDF that the phone uploads and can return the report data (answers with their labels).'),
      bullet('Consequence for the spec: the existing report engine lives in the app. A browser editor can change the saved data, and the phone then regenerates PDF and Word after Synchronise. Showing a full live report preview inside the browser would need that engine to be ported to the server or the browser (a larger task).'),

      h('4. Existing cloud synchronisation architecture'),
      bullet('Offline first. Every change on the phone is written to a local queue (sync_queue) and sent when the network is available.'),
      bullet('Push: POST /sync/push sends a batch with an idempotency key, so a repeated batch is applied once. Entities: survey, section, answer. Photos upload separately through /media/upload.'),
      bullet('Pull: GET /sync/pull returns everything changed after a time cursor, including deletions.'),
      bullet('Conflicts today: on the server the last write wins (there is no version check on push). On the phone, a pull does not overwrite an item that still has an unsent local change. There is no field-level merge.'),
      bullet('Present and reusable: hashed single-use tokens (used for client magic links), audit log table, survey status flow (Draft, In progress, Completed, Pending review, Approved, Rejected), roles, and a version check (baseVersion with HTTP 409) used when publishing trees.'),
      bullet('Not present: edit links, a single active link per report, a report version number, per-edit audit, photo captions and order in the cloud, and a browser editor.'),

      h('5. Current Level 2 report database'),
      bullet('There is no separate Level 2 database. Level 2 Home Survey is the "inspection" survey type in the app. Its content definition is the inspection tree plus the inspection phrase bank. Surveys and answers are stored in the same tables as every other report type.'),
      bullet('The admin portal publishes the tree and the phrase bank into one versioned table (v2_tree_versions). Each publish is a new version with rollback and an audit entry. Phones download the latest version and cache it.'),
      bullet('Valuation has its own tree and phrase bank in the same mechanism.'),
      bullet('The server database also contains older enum values LEVEL_2 and LEVEL_3 that the app does not use. Level 3 is not built as a separate report type yet.'),

      h('Gaps against the specification v1.3'),
      p('These do not exist today and are part of the implementation plan: edit link table and one-active-link rule; report version number and 409 on stale save (also on phone push); structured editable blocks with stable IDs and version history; browser editor; photo caption, order, section and annotations in the cloud with EXIF removal; review and owner approval workflow tied to a version; AI suggestions with accept or reject; finalise, lock and reopen; field-level audit.'),
      new Paragraph({ spacing: { before: 240 }, children: [run('Please tell us if any point above does not match your understanding.', { size: 22 })] }),
    ],
  }],
});
Packer.toBuffer(doc).then((buf) => {
  fs.mkdirSync('E:/survey-scriber/docs/client-desktop-editing', { recursive: true });
  const out = 'E:/survey-scriber/docs/client-desktop-editing/Reply_Confirmations_16Nov2026.docx';
  fs.writeFileSync(out, buf);
  console.log('written', buf.length);
});

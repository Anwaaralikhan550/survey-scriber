import { randomUUID } from 'crypto';

/**
 * Structured editable report (client spec v1.3, section 4).
 * Section[] with ContentBlock[]; every object has a stable UUID.
 * The browser edits these blocks, never a Word/PDF file or one big HTML string.
 */

export type BlockType = 'paragraph' | 'rating' | 'recommendation' | 'photo' | 'table';
export type Rating = 'NI' | '1' | '2' | '3';
/** What the phone's report builder produced this block from, so edits go back to the right place. */
export type BlockRole = 'phrase' | 'note' | 'rating' | 'schedule';

export interface TableData {
  headers: string[];
  rows: string[][];
}

export interface ContentBlock {
  id: string;
  type: BlockType;
  order: number;
  /** Template field: may be edited but not deleted. */
  required?: boolean;
  role?: BlockRole;
  text?: string;
  rating?: Rating;
  recommendation?: string;
  photoId?: string;
  table?: TableData;
}

export interface ReportSection {
  id: string;
  /** Template key, e.g. "E1_ROOF". Never changed by the editor. */
  key: string;
  title: string;
  order: number;
  blocks: ContentBlock[];
}

export type ReportContent = ReportSection[];

export type ChangeOp =
  | { op: 'updateBlock'; sectionId: string; blockId: string; fields: Partial<BlockFields> }
  | { op: 'addBlock'; sectionId: string; afterBlockId?: string | null; atStart?: boolean; block: NewBlock }
  | { op: 'deleteBlock'; sectionId: string; blockId: string }
  | { op: 'moveBlock'; sectionId: string; blockId: string; afterBlockId?: string | null; atStart?: boolean; toSectionId?: string };

export interface BlockFields {
  text: string;
  rating: Rating;
  recommendation: string;
  photoId: string;
  table: TableData;
}

export interface NewBlock extends Partial<BlockFields> {
  id: string;
  type: BlockType;
}

export class ContentValidationError extends Error {
  constructor(
    message: string,
    public readonly path: string,
  ) {
    super(message);
  }
}

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const BLOCK_TYPES: BlockType[] = ['paragraph', 'rating', 'recommendation', 'photo', 'table'];
const RATINGS: Rating[] = ['NI', '1', '2', '3'];
const ROLES: BlockRole[] = ['phrase', 'note', 'rating', 'schedule'];

export const LIMITS = {
  maxSections: 200,
  maxBlocksPerSection: 500,
  maxTextLength: 20000,
  maxTitleLength: 255,
  maxKeyLength: 100,
  maxChangesPerSave: 200,
  maxTableCells: 2000,
  maxContentBytes: 5 * 1024 * 1024,
};

/** Plain text only: tags and control characters are removed (XSS and malformed-text guard). */
export function sanitizeText(value: string): string {
  return value
    .replace(/<\s*(script|style)[^>]*>[\s\S]*?<\s*\/\s*\1\s*>/gi, '')
    .replace(/<\/?[a-z!][^>]*>/gi, '')
    .replace(/[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]/g, '');
}

function requireUuid(value: unknown, path: string): string {
  if (typeof value !== 'string' || !UUID_RE.test(value)) {
    throw new ContentValidationError('must be a UUID', path);
  }
  return value.toLowerCase();
}

function cleanString(value: unknown, path: string, max: number): string {
  if (typeof value !== 'string') throw new ContentValidationError('must be text', path);
  const clean = sanitizeText(value);
  if (clean.length > max) throw new ContentValidationError(`longer than ${max} characters`, path);
  return clean;
}

function cleanTable(value: unknown, path: string): TableData {
  if (typeof value !== 'object' || value === null) throw new ContentValidationError('must be a table', path);
  const t = value as Record<string, unknown>;
  if (!Array.isArray(t.headers) || !Array.isArray(t.rows)) throw new ContentValidationError('needs headers and rows', path);
  const headers = t.headers.map((h, i) => cleanString(h, `${path}.headers[${i}]`, 500));
  let cells = headers.length;
  const rows = t.rows.map((r, ri) => {
    if (!Array.isArray(r)) throw new ContentValidationError('row must be a list', `${path}.rows[${ri}]`);
    if (r.length !== headers.length) throw new ContentValidationError('row length differs from headers', `${path}.rows[${ri}]`);
    cells += r.length;
    return r.map((c, ci) => cleanString(c, `${path}.rows[${ri}][${ci}]`, 2000));
  });
  if (cells > LIMITS.maxTableCells) throw new ContentValidationError('table too large', path);
  return { headers, rows };
}

/** Validate and normalise one block. Throws ContentValidationError for anything malformed. */
export function cleanBlock(value: unknown, path: string): ContentBlock {
  if (typeof value !== 'object' || value === null) throw new ContentValidationError('must be an object', path);
  const b = value as Record<string, unknown>;
  const id = requireUuid(b.id, `${path}.id`);
  if (!BLOCK_TYPES.includes(b.type as BlockType)) throw new ContentValidationError('unknown block type', `${path}.type`);
  const type = b.type as BlockType;
  const out: ContentBlock = { id, type, order: 0 };
  if (b.required === true) out.required = true;
  if (b.role !== undefined) {
    if (!ROLES.includes(b.role as BlockRole)) throw new ContentValidationError('unknown block role', `${path}.role`);
    out.role = b.role as BlockRole;
  }
  if (b.text !== undefined) out.text = cleanString(b.text, `${path}.text`, LIMITS.maxTextLength);
  if (b.recommendation !== undefined) out.recommendation = cleanString(b.recommendation, `${path}.recommendation`, LIMITS.maxTextLength);
  if (b.rating !== undefined) {
    if (!RATINGS.includes(b.rating as Rating)) throw new ContentValidationError('rating must be NI, 1, 2 or 3', `${path}.rating`);
    out.rating = b.rating as Rating;
  }
  if (b.photoId !== undefined) out.photoId = requireUuid(b.photoId, `${path}.photoId`);
  if (b.table !== undefined) out.table = cleanTable(b.table, `${path}.table`);
  if (type === 'rating' && out.rating === undefined) throw new ContentValidationError('rating block needs a rating', path);
  if (type === 'photo' && out.photoId === undefined) throw new ContentValidationError('photo block needs a photoId', path);
  if (type === 'table' && out.table === undefined) throw new ContentValidationError('table block needs a table', path);
  return out;
}

/** Validate a whole report body (used for the phone snapshot and for every stored version). */
export function cleanContent(value: unknown): ReportContent {
  if (!Array.isArray(value)) throw new ContentValidationError('content must be a list of sections', 'content');
  if (value.length > LIMITS.maxSections) throw new ContentValidationError('too many sections', 'content');
  const seenSections = new Set<string>();
  const seenBlocks = new Set<string>();
  const sections = value.map((s, si) => {
    const path = `content[${si}]`;
    if (typeof s !== 'object' || s === null) throw new ContentValidationError('must be an object', path);
    const sec = s as Record<string, unknown>;
    const id = requireUuid(sec.id, `${path}.id`);
    if (seenSections.has(id)) throw new ContentValidationError('duplicate section id', `${path}.id`);
    seenSections.add(id);
    if (!Array.isArray(sec.blocks)) throw new ContentValidationError('blocks must be a list', `${path}.blocks`);
    if (sec.blocks.length > LIMITS.maxBlocksPerSection) throw new ContentValidationError('too many blocks', `${path}.blocks`);
    const blocks = sec.blocks.map((b, bi) => {
      const block = cleanBlock(b, `${path}.blocks[${bi}]`);
      if (seenBlocks.has(block.id)) throw new ContentValidationError('duplicate block id', `${path}.blocks[${bi}].id`);
      seenBlocks.add(block.id);
      block.order = bi;
      return block;
    });
    return {
      id,
      key: cleanString(sec.key, `${path}.key`, LIMITS.maxKeyLength),
      title: cleanString(sec.title, `${path}.title`, LIMITS.maxTitleLength),
      order: si,
      blocks,
    } as ReportSection;
  });
  if (Buffer.byteLength(JSON.stringify(sections), 'utf8') > LIMITS.maxContentBytes) {
    throw new ContentValidationError('report is too large', 'content');
  }
  return sections;
}

function findSection(content: ReportContent, sectionId: string, path: string): ReportSection {
  const sec = content.find((s) => s.id === sectionId.toLowerCase());
  if (!sec) throw new ContentValidationError('section not found', path);
  return sec;
}

function reorder(sec: ReportSection): void {
  sec.blocks.forEach((b, i) => {
    b.order = i;
  });
}

/** Place a block after another one; atStart puts it first; no afterBlockId puts it last. */
function insertAfter(sec: ReportSection, block: ContentBlock, afterBlockId: string | null | undefined, atStart: unknown, path: string): void {
  if (sec.blocks.length + 1 > LIMITS.maxBlocksPerSection) throw new ContentValidationError('too many blocks', path);
  if (atStart === true) {
    sec.blocks.unshift(block);
  } else if (afterBlockId === undefined || afterBlockId === null) {
    sec.blocks.push(block);
  } else {
    const at = sec.blocks.findIndex((b) => b.id === afterBlockId.toLowerCase());
    if (at < 0) throw new ContentValidationError('afterBlockId not found in this section', path);
    sec.blocks.splice(at + 1, 0, block);
  }
  reorder(sec);
}

/**
 * Apply the editor's change list to a copy of the content and return the result.
 * Never mutates the input. Any invalid change rejects the whole save (all or nothing).
 */
export function applyChanges(content: ReportContent, changes: unknown): ReportContent {
  if (!Array.isArray(changes)) throw new ContentValidationError('changes must be a list', 'changes');
  if (changes.length === 0) throw new ContentValidationError('no changes', 'changes');
  if (changes.length > LIMITS.maxChangesPerSave) throw new ContentValidationError('too many changes in one save', 'changes');
  const next: ReportContent = JSON.parse(JSON.stringify(content));
  changes.forEach((raw, i) => {
    const path = `changes[${i}]`;
    if (typeof raw !== 'object' || raw === null) throw new ContentValidationError('must be an object', path);
    const c = raw as Record<string, unknown>;
    const sec = findSection(next, String(c.sectionId ?? ''), `${path}.sectionId`);
    switch (c.op) {
      case 'updateBlock': {
        const id = requireUuid(c.blockId, `${path}.blockId`);
        const block = sec.blocks.find((b) => b.id === id);
        if (!block) throw new ContentValidationError('block not found', `${path}.blockId`);
        if (typeof c.fields !== 'object' || c.fields === null) throw new ContentValidationError('fields required', `${path}.fields`);
        const f = c.fields as Record<string, unknown>;
        const allowed = ['text', 'rating', 'recommendation', 'photoId', 'table'];
        for (const key of Object.keys(f)) {
          if (!allowed.includes(key)) throw new ContentValidationError(`field ${key} cannot be edited`, `${path}.fields.${key}`);
        }
        const merged = cleanBlock({ ...block, ...f }, `${path}.fields`);
        Object.assign(block, merged, { order: block.order, required: block.required });
        break;
      }
      case 'addBlock': {
        const block = cleanBlock(c.block, `${path}.block`);
        if (next.some((s) => s.blocks.some((b) => b.id === block.id))) {
          throw new ContentValidationError('block id already exists', `${path}.block.id`);
        }
        delete block.required; // only the template can mark a block required
        delete block.role; // only the phone's builder sets what a block was made from
        insertAfter(sec, block, c.afterBlockId as string | null | undefined, c.atStart, path);
        break;
      }
      case 'deleteBlock': {
        const id = requireUuid(c.blockId, `${path}.blockId`);
        const at = sec.blocks.findIndex((b) => b.id === id);
        if (at < 0) throw new ContentValidationError('block not found', `${path}.blockId`);
        if (sec.blocks[at].required) throw new ContentValidationError('this template field cannot be deleted', `${path}.blockId`);
        sec.blocks.splice(at, 1);
        reorder(sec);
        break;
      }
      case 'moveBlock': {
        const id = requireUuid(c.blockId, `${path}.blockId`);
        const at = sec.blocks.findIndex((b) => b.id === id);
        if (at < 0) throw new ContentValidationError('block not found', `${path}.blockId`);
        const [block] = sec.blocks.splice(at, 1);
        reorder(sec);
        const target = c.toSectionId ? findSection(next, String(c.toSectionId), `${path}.toSectionId`) : sec;
        if (block.required && target !== sec) {
          throw new ContentValidationError('a template field cannot move to another section', `${path}.toSectionId`);
        }
        insertAfter(target, block, c.afterBlockId as string | null | undefined, c.atStart, path);
        break;
      }
      default:
        throw new ContentValidationError('unknown operation', `${path}.op`);
    }
  });
  if (Buffer.byteLength(JSON.stringify(next), 'utf8') > LIMITS.maxContentBytes) {
    throw new ContentValidationError('report is too large', 'content');
  }
  return next;
}

export function newBlockId(): string {
  return randomUUID();
}

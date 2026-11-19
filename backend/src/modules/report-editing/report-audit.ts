import type { ContentBlock, ReportContent } from './report-content';

/**
 * Field-level amendments between two versions of a report (Remote Editor spec v1.4 sections 10 and 18). Derived from the
 * content before and after a save, so the audit can never disagree with the report and there is no second source of truth.
 */
export type AuditEntity = 'SECTION' | 'BLOCK';
export type AuditOp = 'ADD' | 'UPDATE' | 'DELETE' | 'MOVE';

export interface FieldChange {
  entityType: AuditEntity;
  entityId: string;
  sectionId: string;
  sectionKey: string;
  field: 'section' | 'title' | 'block' | 'text' | 'rating' | 'recommendation' | 'photoId' | 'table' | 'section_of_block' | 'position';
  op: AuditOp;
  before: unknown;
  after: unknown;
}

const VALUE_FIELDS = ['text', 'rating', 'recommendation', 'photoId', 'table'] as const;

/** The editable content of a block, without its id and numbering. */
function blockValues(b: ContentBlock): Record<string, unknown> {
  const out: Record<string, unknown> = { type: b.type };
  if (b.role !== undefined) out.role = b.role;
  for (const f of VALUE_FIELDS) if (b[f] !== undefined) out[f] = b[f];
  return out;
}

const same = (a: unknown, b: unknown) => JSON.stringify(a ?? null) === JSON.stringify(b ?? null);

interface Located {
  block: ContentBlock;
  sectionId: string;
  sectionKey: string;
}

function locate(content: ReportContent): Map<string, Located> {
  const map = new Map<string, Located>();
  for (const s of content) for (const block of s.blocks) map.set(block.id, { block, sectionId: s.id, sectionKey: s.key });
  return map;
}

export function diffContent(before: ReportContent, after: ReportContent): FieldChange[] {
  const out: FieldChange[] = [];
  const bSections = new Map(before.map((s) => [s.id, s]));
  const aSections = new Map(after.map((s) => [s.id, s]));

  for (const s of before) {
    if (!aSections.has(s.id)) {
      out.push({ entityType: 'SECTION', entityId: s.id, sectionId: s.id, sectionKey: s.key, field: 'section', op: 'DELETE', before: { key: s.key, title: s.title, blocks: s.blocks.length }, after: null });
    }
  }
  for (const s of after) {
    const old = bSections.get(s.id);
    if (!old) {
      out.push({ entityType: 'SECTION', entityId: s.id, sectionId: s.id, sectionKey: s.key, field: 'section', op: 'ADD', before: null, after: { key: s.key, title: s.title, blocks: s.blocks.length } });
    } else if (old.title !== s.title) {
      out.push({ entityType: 'SECTION', entityId: s.id, sectionId: s.id, sectionKey: s.key, field: 'title', op: 'UPDATE', before: old.title, after: s.title });
    }
  }

  const was = locate(before);
  const now = locate(after);
  for (const [id, w] of was) {
    if (!now.has(id)) {
      out.push({ entityType: 'BLOCK', entityId: id, sectionId: w.sectionId, sectionKey: w.sectionKey, field: 'block', op: 'DELETE', before: blockValues(w.block), after: null });
    }
  }
  for (const [id, n] of now) {
    const w = was.get(id);
    if (!w) {
      out.push({ entityType: 'BLOCK', entityId: id, sectionId: n.sectionId, sectionKey: n.sectionKey, field: 'block', op: 'ADD', before: null, after: blockValues(n.block) });
      continue;
    }
    if (w.sectionId !== n.sectionId) {
      out.push({ entityType: 'BLOCK', entityId: id, sectionId: n.sectionId, sectionKey: n.sectionKey, field: 'section_of_block', op: 'MOVE', before: { sectionId: w.sectionId, sectionKey: w.sectionKey }, after: { sectionId: n.sectionId, sectionKey: n.sectionKey } });
    }
    for (const f of VALUE_FIELDS) {
      if (!same(w.block[f], n.block[f])) {
        out.push({ entityType: 'BLOCK', entityId: id, sectionId: n.sectionId, sectionKey: n.sectionKey, field: f, op: 'UPDATE', before: w.block[f] ?? null, after: n.block[f] ?? null });
      }
    }
  }

  // Reordering inside a section: only the blocks that were in both versions count, so adding or deleting a neighbour is not a move.
  for (const s of after) {
    const old = bSections.get(s.id);
    if (!old) continue;
    const keep = (ids: string[]) => ids.filter((id) => was.get(id)?.sectionId === s.id && now.get(id)?.sectionId === s.id);
    const oldSeq = keep(old.blocks.map((b) => b.id));
    const newSeq = keep(s.blocks.map((b) => b.id));
    if (oldSeq.join() === newSeq.join()) continue;
    newSeq.forEach((id, i) => {
      if (oldSeq[i] !== id) {
        out.push({ entityType: 'BLOCK', entityId: id, sectionId: s.id, sectionKey: s.key, field: 'position', op: 'MOVE', before: oldSeq.indexOf(id), after: i });
      }
    });
  }
  return out;
}

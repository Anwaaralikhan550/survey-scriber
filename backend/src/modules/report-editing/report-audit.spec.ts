import { randomUUID } from 'crypto';
import { diffContent } from './report-audit';
import type { ContentBlock, ReportContent } from './report-content';

const id = () => randomUUID();
const block = (text: string, extra: Partial<ContentBlock> = {}, order = 0): ContentBlock => ({ id: id(), type: 'paragraph', order, text, ...extra });
const section = (key: string, blocks: ContentBlock[], sid: string = id()) => ({ id: sid, key, title: key, order: 0, blocks });
const clone = <T,>(v: T): T => JSON.parse(JSON.stringify(v));

describe('diffContent', () => {
  it('nothing changed: no events', () => {
    const c: ReportContent = [section('E1', [block('a'), block('b')])];
    expect(diffContent(c, clone(c))).toEqual([]);
  });

  it('a changed paragraph: one UPDATE with the old and the new text', () => {
    const c: ReportContent = [section('E1', [block('The roof is tiled.')])];
    const d = clone(c);
    d[0].blocks[0].text = 'The roof is covered with slates.';
    const out = diffContent(c, d);
    expect(out).toHaveLength(1);
    expect(out[0]).toMatchObject({ entityType: 'BLOCK', entityId: c[0].blocks[0].id, sectionKey: 'E1', field: 'text', op: 'UPDATE', before: 'The roof is tiled.', after: 'The roof is covered with slates.' });
  });

  it('a rating, a recommendation and a table are separate fields', () => {
    const c: ReportContent = [section('E1', [{ id: id(), type: 'rating', order: 0, rating: '2' }, { id: id(), type: 'recommendation', order: 1, recommendation: 'Repair.' }, { id: id(), type: 'table', order: 2, table: { headers: ['A'], rows: [['1']] } }])];
    const d = clone(c);
    d[0].blocks[0].rating = '3';
    d[0].blocks[1].recommendation = 'Repair within 3 months.';
    d[0].blocks[2].table = { headers: ['A'], rows: [['2']] };
    const out = diffContent(c, d);
    expect(out.map((e) => [e.field, e.before, e.after])).toEqual([
      ['rating', '2', '3'],
      ['recommendation', 'Repair.', 'Repair within 3 months.'],
      ['table', { headers: ['A'], rows: [['1']] }, { headers: ['A'], rows: [['2']] }],
    ]);
  });

  it('an added block has its content in after; a deleted block has it in before', () => {
    const keep = block('keep');
    const gone = block('gone text');
    const c: ReportContent = [section('E1', [keep, gone])];
    const added = block('brand new');
    const d: ReportContent = [section('E1', [keep, added], c[0].id)];
    const out = diffContent(c, d);
    expect(out.find((e) => e.op === 'DELETE')).toMatchObject({ entityId: gone.id, field: 'block', before: { type: 'paragraph', text: 'gone text' }, after: null });
    expect(out.find((e) => e.op === 'ADD')).toMatchObject({ entityId: added.id, field: 'block', before: null, after: { type: 'paragraph', text: 'brand new' } });
    expect(out).toHaveLength(2);
  });

  it('a new neighbour or a deleted neighbour is not a move', () => {
    const a = block('a');
    const b = block('b');
    const c: ReportContent = [section('E1', [a, b])];
    const d: ReportContent = [section('E1', [block('x'), a, block('y'), b], c[0].id)];
    expect(diffContent(c, d).filter((e) => e.op === 'MOVE')).toEqual([]);
    const e: ReportContent = [section('E1', [b], c[0].id)];
    expect(diffContent(c, e).filter((x) => x.op === 'MOVE')).toEqual([]);
  });

  it('swapping two blocks records the move of each', () => {
    const a = block('a');
    const b = block('b');
    const c: ReportContent = [section('E1', [a, b])];
    const d: ReportContent = [section('E1', [b, a], c[0].id)];
    const out = diffContent(c, d);
    expect(out.map((e) => [e.entityId, e.field, e.before, e.after])).toEqual([
      [b.id, 'position', 1, 0],
      [a.id, 'position', 0, 1],
    ]);
  });

  it('moving a block to another section is one MOVE of its section, the destination counts as unchanged order', () => {
    const a = block('a');
    const b = block('b');
    const s1 = section('E1', [a, b]);
    const s2 = section('E2', []);
    const d: ReportContent = [section('E1', [a], s1.id), section('E2', [b], s2.id)];
    const out = diffContent([s1, s2], d);
    expect(out).toHaveLength(1);
    expect(out[0]).toMatchObject({ entityId: b.id, field: 'section_of_block', op: 'MOVE', before: { sectionKey: 'E1' }, after: { sectionKey: 'E2' } });
  });

  it('section added, removed and renamed', () => {
    const s1 = section('E1', [block('a')]);
    const s2 = section('E2', [block('b')]);
    const renamed = { ...clone(s1), title: 'Roof coverings' };
    const s3 = section('E3', []);
    const out = diffContent([s1, s2], [renamed, s3]);
    expect(out.map((e) => [e.entityType, e.field, e.op]).sort()).toEqual([
      ['BLOCK', 'block', 'DELETE'],
      ['SECTION', 'section', 'ADD'],
      ['SECTION', 'section', 'DELETE'],
      ['SECTION', 'title', 'UPDATE'],
    ]);
  });

  it('the numbering of blocks (order) is not a change by itself', () => {
    const c: ReportContent = [section('E1', [block('a', {}, 0), block('b', {}, 1)])];
    const d = clone(c);
    d[0].blocks[0].order = 5;
    d[0].blocks[1].order = 9;
    expect(diffContent(c, d)).toEqual([]);
  });
});

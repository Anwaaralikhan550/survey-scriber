import { randomUUID } from 'crypto';
import { ContentValidationError, LIMITS, ReportContent, applyChanges, cleanContent, sanitizeText } from './report-content';

const id = () => randomUUID();

function sample(): { content: ReportContent; sec: string; b1: string; b2: string; req: string } {
  const sec = id();
  const b1 = id();
  const b2 = id();
  const req = id();
  const content = cleanContent([
    {
      id: sec,
      key: 'E1_ROOF',
      title: 'Roof',
      blocks: [
        { id: b1, type: 'paragraph', text: 'First' },
        { id: b2, type: 'paragraph', text: 'Second' },
        { id: req, type: 'rating', rating: '2', required: true },
      ],
    },
  ]);
  return { content, sec, b1, b2, req };
}

describe('report content', () => {
  it('numbers sections and blocks in order and keeps their ids', () => {
    const { content, sec, b1, b2 } = sample();
    expect(content[0].id).toBe(sec);
    expect(content[0].blocks.map((b) => [b.id, b.order])).toEqual([[b1, 0], [b2, 1], [content[0].blocks[2].id, 2]]);
  });

  it('removes HTML and control characters from text', () => {
    expect(sanitizeText('Hi <script>alert(1)</script><b>there</b>\u0000!')).toBe('Hi there!');
    const { content, sec, b1 } = sample();
    const out = applyChanges(content, [{ op: 'updateBlock', sectionId: sec, blockId: b1, fields: { text: 'x<img src=a onerror=b>y' } }]);
    expect(out[0].blocks[0].text).toBe('xy');
  });

  it('rejects malformed structure', () => {
    expect(() => cleanContent('nope')).toThrow(ContentValidationError);
    expect(() => cleanContent([{ id: 'not-a-uuid', key: 'k', title: 't', blocks: [] }])).toThrow(/UUID/);
    const s = id();
    expect(() => cleanContent([{ id: s, key: 'k', title: 't', blocks: [{ id: id(), type: 'video' }] }])).toThrow(/block type/);
    expect(() => cleanContent([{ id: s, key: 'k', title: 't', blocks: [{ id: id(), type: 'rating', rating: '9' }] }])).toThrow(/rating/);
    const dup = id();
    expect(() =>
      cleanContent([{ id: s, key: 'k', title: 't', blocks: [{ id: dup, type: 'paragraph', text: 'a' }, { id: dup, type: 'paragraph', text: 'b' }] }]),
    ).toThrow(/duplicate block/);
    expect(() => cleanContent([{ id: s, key: 'k', title: 't', blocks: [{ id: id(), type: 'paragraph', text: 'x'.repeat(LIMITS.maxTextLength + 1) }] }])).toThrow(/longer than/);
  });

  it('updates, adds, moves and deletes blocks without touching the input', () => {
    const { content, sec, b1, b2 } = sample();
    const before = JSON.stringify(content);
    const nb = id();
    const out = applyChanges(content, [
      { op: 'updateBlock', sectionId: sec, blockId: b1, fields: { text: 'First edited' } },
      { op: 'addBlock', sectionId: sec, afterBlockId: b1, block: { id: nb, type: 'paragraph', text: 'Inserted' } },
      { op: 'moveBlock', sectionId: sec, blockId: b2, afterBlockId: null },
    ]);
    expect(JSON.stringify(content)).toBe(before);
    expect(out[0].blocks.map((b) => b.id)).toEqual([b1, nb, content[0].blocks[2].id, b2]);
    expect(out[0].blocks.map((b) => b.order)).toEqual([0, 1, 2, 3]);
    expect(out[0].blocks[0].text).toBe('First edited');
    const afterDelete = applyChanges(out, [{ op: 'deleteBlock', sectionId: sec, blockId: nb }]);
    expect(afterDelete[0].blocks.map((b) => b.id)).not.toContain(nb);
    expect(afterDelete[0].blocks.map((b) => b.order)).toEqual([0, 1, 2]);
  });

  it('keeps template fields: a required block cannot be deleted or moved to another section', () => {
    const { content, sec, req } = sample();
    expect(() => applyChanges(content, [{ op: 'deleteBlock', sectionId: sec, blockId: req }])).toThrow(/cannot be deleted/);
    const other = id();
    const two = cleanContent([...content, { id: other, key: 'E2', title: 'Walls', blocks: [] }]);
    expect(() => applyChanges(two, [{ op: 'moveBlock', sectionId: sec, blockId: req, toSectionId: other }])).toThrow(/cannot move/);
    // but a required block may be edited
    const edited = applyChanges(content, [{ op: 'updateBlock', sectionId: sec, blockId: req, fields: { rating: '3' } }]);
    expect(edited[0].blocks[2].rating).toBe('3');
    expect(edited[0].blocks[2].required).toBe(true);
  });

  it('a new block can never claim to be a required template field', () => {
    const { content, sec } = sample();
    const out = applyChanges(content, [{ op: 'addBlock', sectionId: sec, block: { id: id(), type: 'paragraph', text: 'x', required: true } as never }]);
    expect(out[0].blocks[3].required).toBeUndefined();
  });

  it('moves a block to another section', () => {
    const { content, sec, b1 } = sample();
    const other = id();
    const two = cleanContent([...content, { id: other, key: 'E2', title: 'Walls', blocks: [] }]);
    const out = applyChanges(two, [{ op: 'moveBlock', sectionId: sec, blockId: b1, toSectionId: other }]);
    expect(out[1].blocks.map((b) => b.id)).toEqual([b1]);
    expect(out[0].blocks.map((b) => b.id)).not.toContain(b1);
  });

  it('refuses the whole save when one change is bad (all or nothing)', () => {
    const { content, sec, b1 } = sample();
    expect(() =>
      applyChanges(content, [
        { op: 'updateBlock', sectionId: sec, blockId: b1, fields: { text: 'ok' } },
        { op: 'updateBlock', sectionId: sec, blockId: id(), fields: { text: 'missing block' } },
      ]),
    ).toThrow(/block not found/);
  });

  it('only text, rating, recommendation, photoId and table are editable fields', () => {
    const { content, sec, b1 } = sample();
    expect(() => applyChanges(content, [{ op: 'updateBlock', sectionId: sec, blockId: b1, fields: { id: id() } }])).toThrow(/cannot be edited/);
    expect(() => applyChanges(content, [{ op: 'updateBlock', sectionId: sec, blockId: b1, fields: { type: 'rating' } }])).toThrow(/cannot be edited/);
  });

  it('rejects an empty or oversized change list and unknown operations', () => {
    const { content, sec } = sample();
    expect(() => applyChanges(content, [])).toThrow(/no changes/);
    expect(() => applyChanges(content, Array.from({ length: LIMITS.maxChangesPerSave + 1 }, () => ({ op: 'deleteBlock', sectionId: sec, blockId: id() })))).toThrow(/too many/);
    expect(() => applyChanges(content, [{ op: 'dropTable', sectionId: sec }])).toThrow(/unknown operation/);
  });

  it('atStart puts a new or moved block first; no position puts it last', () => {
    const { content, sec, b1, b2 } = sample();
    const nb = id();
    const out = applyChanges(content, [
      { op: 'addBlock', sectionId: sec, atStart: true, block: { id: nb, type: 'paragraph', text: 'First of all' } },
      { op: 'moveBlock', sectionId: sec, blockId: b2, atStart: true },
    ]);
    expect(out[0].blocks.map((b) => b.id).slice(0, 3)).toEqual([b2, nb, b1]);
    expect(out[0].blocks.map((b) => b.order)).toEqual([0, 1, 2, 3, 4].slice(0, out[0].blocks.length));
  });

  it('keeps a block role from the phone, rejects unknown roles, and never lets the editor set one', () => {
    const { sec } = sample();
    const rb = id();
    const content = cleanContent([{ id: sec, key: 'E1_ROOF/main', title: 'Roof', blocks: [{ id: rb, type: 'paragraph', text: 'x', role: 'phrase' }] }]);
    expect(content[0].blocks[0].role).toBe('phrase');
    expect(() => cleanContent([{ id: sec, key: 'k', title: 't', blocks: [{ id: id(), type: 'paragraph', role: 'boss' }] }])).toThrow(/role/);
    const edited = applyChanges(content, [{ op: 'updateBlock', sectionId: sec, blockId: rb, fields: { text: 'y' } }]);
    expect(edited[0].blocks[0].role).toBe('phrase');
    const added = applyChanges(content, [{ op: 'addBlock', sectionId: sec, block: { id: id(), type: 'paragraph', text: 'z', role: 'rating' } as never }]);
    expect(added[0].blocks[1].role).toBeUndefined();
  });
});

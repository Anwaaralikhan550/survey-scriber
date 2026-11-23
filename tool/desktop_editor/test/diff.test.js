import test from 'node:test';
import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { diffContent, applyOps, chunkOps, normalise, clone, findOverlaps, resolveOps } from '../src/diff.js';

const id = () => randomUUID();
const mk = (n, extra = {}) => ({ id: id(), type: 'paragraph', text: `p${n}`, order: 0, ...extra });

function report() {
  const a = mk(1);
  const b = mk(2);
  const c = mk(3);
  const d = mk(4);
  const e = mk(5, { type: 'rating', rating: '2', text: undefined, required: true });
  return normalise([
    { id: id(), key: 'E1', title: 'Roof', order: 0, blocks: [a, b, c] },
    { id: id(), key: 'E2', title: 'Walls', order: 1, blocks: [d, e] },
  ]);
}

// The real check of a diff: applying it to the base must give exactly the edited copy.
function roundTrip(base, edit) {
  const cur = clone(base);
  edit(cur);
  const ops = diffContent(base, cur);
  assert.deepEqual(normalise(applyOps(base, ops)), normalise(cur));
  return ops;
}

test('no change, no operations', () => {
  const base = report();
  assert.deepEqual(diffContent(base, clone(base)), []);
});

test('a text edit becomes one updateBlock with only the changed field', () => {
  const base = report();
  const ops = roundTrip(base, (c) => (c[0].blocks[1].text = 'changed'));
  assert.equal(ops.length, 1);
  assert.deepEqual(ops[0], { op: 'updateBlock', sectionId: base[0].id, blockId: base[0].blocks[1].id, fields: { text: 'changed' } });
});

test('rating and table edits', () => {
  const base = report();
  roundTrip(base, (c) => (c[1].blocks[1].rating = '3'));
  const withTable = clone(base);
  withTable[0].blocks.push({ id: id(), type: 'table', order: 3, table: { headers: ['a', 'b'], rows: [['1', '2']] } });
  const ops = roundTrip(withTable, (c) => (c[0].blocks[3].table.rows[0][1] = '9'));
  assert.equal(ops[0].fields.table.rows[0][1], '9');
});

test('add at the start, middle and end', () => {
  const base = report();
  const ops = roundTrip(base, (c) => {
    c[0].blocks.splice(0, 0, mk(10));
    c[0].blocks.splice(2, 0, mk(11));
    c[0].blocks.push(mk(12));
  });
  assert.equal(ops.filter((o) => o.op === 'addBlock').length, 3);
  assert.equal(ops.find((o) => o.atStart).op, 'addBlock');
});

test('delete a paragraph', () => {
  const base = report();
  const ops = roundTrip(base, (c) => c[0].blocks.splice(1, 1));
  assert.deepEqual(ops.map((o) => o.op), ['deleteBlock']);
});

test('reorder with the up and down buttons', () => {
  const base = report();
  roundTrip(base, (c) => c[0].blocks.reverse());
  roundTrip(base, (c) => {
    const [b] = c[0].blocks.splice(2, 1);
    c[0].blocks.unshift(b);
  });
  roundTrip(base, (c) => {
    const [b] = c[0].blocks.splice(0, 1);
    c[0].blocks.push(b);
  });
});

test('move a paragraph to another section', () => {
  const base = report();
  const ops = roundTrip(base, (c) => {
    const [b] = c[0].blocks.splice(0, 1);
    c[1].blocks.splice(1, 0, b);
  });
  assert.ok(ops.find((o) => o.op === 'moveBlock' && o.toSectionId === base[1].id));
});

test('everything at once, in random orders', () => {
  for (let round = 0; round < 200; round++) {
    const base = report();
    roundTrip(base, (c) => {
      const all = [...c[0].blocks, ...c[1].blocks].filter((b) => !b.required);
      for (const b of all) if (Math.random() < 0.3) b.text = `edit ${Math.random()}`;
      for (const s of c) {
        for (let i = s.blocks.length - 1; i >= 0; i--) if (!s.blocks[i].required && Math.random() < 0.25) s.blocks.splice(i, 1);
        for (let i = 0; i < 2; i++) if (Math.random() < 0.5) s.blocks.splice(Math.floor(Math.random() * (s.blocks.length + 1)), 0, mk(100 + i));
        s.blocks.sort(() => Math.random() - 0.5);
      }
      // a required block keeps its section
      const req = c.flatMap((s) => s.blocks).find((b) => b.required);
      for (const s of c) s.blocks = s.blocks.filter((b) => b !== req);
      c[1].blocks.splice(Math.floor(Math.random() * (c[1].blocks.length + 1)), 0, req);
    });
  }
});

test('chunkOps keeps the server limit', () => {
  const ops = Array.from({ length: 450 }, (_, i) => ({ i }));
  assert.deepEqual(chunkOps(ops).map((c) => c.length), [200, 200, 50]);
});

test('re-applying my own changes on newer server content (conflict rebase)', () => {
  const base = report();
  const mine = clone(base);
  mine[0].blocks[0].text = 'my edit';
  mine[0].blocks.push(mk(20));
  const ops = diffContent(base, mine);
  const server = clone(base);
  server[0].blocks[2].text = 'colleague edit'; // a different paragraph
  const merged = applyOps(server, ops);
  assert.equal(merged[0].blocks[0].text, 'my edit');
  assert.equal(merged[0].blocks[2].text, 'colleague edit');
  assert.equal(merged[0].blocks.length, 4);
  const gone = clone(base);
  gone[0].blocks.splice(0, 1); // colleague deleted the paragraph I edited
  assert.throws(() => applyOps(gone, ops));
});

// ---- two people changed the same paragraph (conflict re-apply must never throw their text away silently)
function conflictCase() {
  const base = report();
  const mine = clone(base);
  mine[0].blocks[0].text = 'my wording';
  mine[0].blocks[1].text = 'my other change';
  const theirs = clone(base);
  theirs[0].blocks[0].text = 'their wording';
  return { base, mine, theirs, ops: diffContent(base, mine) };
}

test('overlap: the same paragraph changed by both is found, a paragraph only I changed is not', () => {
  const { base, theirs, ops } = conflictCase();
  const found = findOverlaps(base, theirs, ops);
  assert.equal(found.length, 1);
  assert.equal(found[0].blockId, base[0].blocks[0].id);
  assert.equal(found[0].mine, 'my wording');
  assert.equal(found[0].theirs, 'their wording');
  assert.equal(found[0].sectionTitle, 'Roof');
});

test('overlap: both changed it to the same text is not a conflict; a different paragraph is not a conflict', () => {
  const { base, ops } = conflictCase();
  const same1 = clone(base);
  same1[0].blocks[0].text = 'my wording';
  assert.equal(findOverlaps(base, same1, ops).length, 0);
  const other = clone(base);
  other[0].blocks[2].text = 'a different paragraph changed';
  assert.equal(findOverlaps(base, other, ops).length, 0);
});

test('overlap: keep theirs drops my change to that paragraph only', () => {
  const { base, theirs, ops } = conflictCase();
  const found = findOverlaps(base, theirs, ops);
  const merged = normalise(applyOps(theirs, resolveOps(ops, found, { [`${found[0].blockId}:text`]: 'theirs' })));
  assert.equal(merged[0].blocks[0].text, 'their wording');
  assert.equal(merged[0].blocks[1].text, 'my other change');
});

test('overlap: keep mine puts my wording on top', () => {
  const { base, theirs, ops } = conflictCase();
  const found = findOverlaps(base, theirs, ops);
  const merged = normalise(applyOps(theirs, resolveOps(ops, found, { [`${found[0].blockId}:text`]: 'mine' })));
  assert.equal(merged[0].blocks[0].text, 'my wording');
});

test('overlap: keep both keeps their paragraph and adds mine right after it (the default, nothing is lost)', () => {
  const { base, theirs, ops } = conflictCase();
  const found = findOverlaps(base, theirs, ops);
  const merged = normalise(applyOps(theirs, resolveOps(ops, found, {}, () => 'new-id')));
  assert.equal(merged[0].blocks[0].text, 'their wording');
  assert.equal(merged[0].blocks[1].id, 'new-id');
  assert.equal(merged[0].blocks[1].text, 'my wording');
  assert.equal(merged[0].blocks[2].text, 'my other change');
});

test('overlap: a rating changed by both offers mine or theirs only (no "both")', () => {
  const base = report();
  const ratingId = base[1].blocks[1].id;
  const mine = clone(base);
  mine[1].blocks[1].rating = '3';
  const theirs = clone(base);
  theirs[1].blocks[1].rating = '1';
  const ops = diffContent(base, mine);
  const found = findOverlaps(base, theirs, ops);
  assert.equal(found[0].field, 'rating');
  const kept = normalise(applyOps(theirs, resolveOps(ops, found, {})));
  assert.equal(kept[1].blocks[1].rating, '1');
  const mineWins = normalise(applyOps(theirs, resolveOps(ops, found, { [`${ratingId}:rating`]: 'mine' })));
  assert.equal(mineWins[1].blocks[1].rating, '3');
});

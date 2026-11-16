// Turns the editor's working copy into the server's change list, and applies a change list locally.
// The server (backend/src/modules/report-editing/report-content.ts) is the authority; applyOps here is only
// used to re-apply a user's own pending changes on top of newer server content after a version conflict.

export const EDITABLE_FIELDS = ['text', 'rating', 'recommendation', 'photoId', 'table'];
export const MAX_OPS_PER_SAVE = 200;

export const clone = (v) => JSON.parse(JSON.stringify(v));
export const same = (a, b) => JSON.stringify(a ?? null) === JSON.stringify(b ?? null);

function indexBlocks(content) {
  const map = new Map();
  for (const sec of content) {
    sec.blocks.forEach((block, index) => map.set(block.id, { sectionId: sec.id, block, index }));
  }
  return map;
}

function newBlockPayload(block) {
  const out = { id: block.id, type: block.type };
  for (const f of EDITABLE_FIELDS) if (block[f] !== undefined) out[f] = block[f];
  return out;
}

/** Operations that turn `base` (what the server has) into `cur` (what the user sees). */
export function diffContent(base, cur) {
  const ops = [];
  const before = indexBlocks(base);
  const after = indexBlocks(cur);

  for (const [id, { sectionId }] of before) {
    if (!after.has(id)) ops.push({ op: 'deleteBlock', sectionId, blockId: id });
  }

  for (const [id, now] of after) {
    const was = before.get(id);
    if (!was) continue;
    const fields = {};
    for (const f of EDITABLE_FIELDS) {
      if (!same(was.block[f], now.block[f]) && now.block[f] !== undefined) fields[f] = now.block[f];
    }
    if (Object.keys(fields).length) ops.push({ op: 'updateBlock', sectionId: was.sectionId, blockId: id, fields });
  }

  // Simulate the server's order after the deletes, then fix positions one section at a time.
  const sim = new Map(base.map((s) => [s.id, s.blocks.filter((b) => after.has(b.id)).map((b) => b.id)]));
  for (const sec of cur) {
    const want = sec.blocks.map((b) => b.id);
    want.forEach((id, i) => {
      const have = sim.get(sec.id);
      if (have[i] === id) return;
      const placement = i === 0 ? { atStart: true } : { afterBlockId: want[i - 1] };
      const was = before.get(id);
      if (!was) {
        ops.push({ op: 'addBlock', sectionId: sec.id, ...placement, block: newBlockPayload(after.get(id).block) });
      } else {
        let from = null;
        for (const [sid, ids] of sim) {
          const at = ids.indexOf(id);
          if (at >= 0) {
            from = sid;
            ids.splice(at, 1);
            break;
          }
        }
        const move = { op: 'moveBlock', sectionId: from, blockId: id, ...placement };
        if (from !== sec.id) move.toSectionId = sec.id;
        ops.push(move);
      }
      have.splice(i, 0, id);
    });
  }
  return ops;
}

/** Mirror of the server's applyChanges for the subset the editor produces. Throws Error on any mismatch. */
export function applyOps(content, ops) {
  const next = clone(content);
  const sec = (id) => {
    const s = next.find((x) => x.id === id);
    if (!s) throw new Error('section not found');
    return s;
  };
  const place = (target, block, op) => {
    if (op.atStart === true) target.blocks.unshift(block);
    else if (op.afterBlockId == null) target.blocks.push(block);
    else {
      const at = target.blocks.findIndex((b) => b.id === op.afterBlockId);
      if (at < 0) throw new Error('afterBlockId not found');
      target.blocks.splice(at + 1, 0, block);
    }
  };
  for (const op of ops) {
    const s = sec(op.sectionId);
    if (op.op === 'updateBlock') {
      const b = s.blocks.find((x) => x.id === op.blockId);
      if (!b) throw new Error('block not found');
      Object.assign(b, op.fields);
    } else if (op.op === 'addBlock') {
      if (next.some((x) => x.blocks.some((b) => b.id === op.block.id))) throw new Error('block id already exists');
      place(s, { ...op.block }, op);
    } else if (op.op === 'deleteBlock') {
      const at = s.blocks.findIndex((x) => x.id === op.blockId);
      if (at < 0) throw new Error('block not found');
      if (s.blocks[at].required) throw new Error('required block');
      s.blocks.splice(at, 1);
    } else if (op.op === 'moveBlock') {
      const at = s.blocks.findIndex((x) => x.id === op.blockId);
      if (at < 0) throw new Error('block not found');
      const [b] = s.blocks.splice(at, 1);
      const target = op.toSectionId ? sec(op.toSectionId) : s;
      if (b.required && target !== s) throw new Error('required block');
      place(target, b, op);
    } else throw new Error('unknown operation');
  }
  next.forEach((x) => x.blocks.forEach((b, i) => (b.order = i)));
  return next;
}

/** Split a long change list into saves of at most `size` operations. */
export function chunkOps(ops, size = MAX_OPS_PER_SAVE) {
  const out = [];
  for (let i = 0; i < ops.length; i += size) out.push(ops.slice(i, i + size));
  return out;
}

/** Normalise order numbers so two copies of the same content compare equal. */
export function normalise(content) {
  const c = clone(content);
  c.forEach((s, si) => {
    s.order = si;
    s.blocks.forEach((b, i) => (b.order = i));
  });
  return c;
}

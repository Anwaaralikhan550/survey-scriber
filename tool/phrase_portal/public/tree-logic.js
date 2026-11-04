/**
 * Working on a survey tree, with no browser in it, shared with the node tests.
 * The tree is the same JSON the app reads. Dropdown answers stay stored by their
 * original value; optionLabels and hiddenOptions only change what people read.
 */
(function (root, factory) {
  if (typeof module === 'object' && module.exports) module.exports = factory();
  else root.TreeLogic = factory();
})(typeof self !== 'undefined' ? self : this, function () {
  const TREE_TYPE = { inspection: 'inspection_v2', valuation: 'valuation_v2' };

  const clone = (o) => JSON.parse(JSON.stringify(o));
  const nodesOf = (tree) => (tree.sections || []).flatMap((s) => s.nodes || []);

  /** Node and section lookups, so walking every field stays quick on 2,000 nodes. */
  function indexOf(tree) {
    const byId = new Map();
    const sectionOf = new Map();
    for (const section of tree.sections || []) {
      for (const node of section.nodes || []) {
        byId.set(node.id, node);
        sectionOf.set(node.id, section);
      }
    }
    return { byId, sectionOf };
  }

  /** "Outside Property > Chimney Stacks > Repairs" */
  function pathOf(tree, nodeId, index) {
    const { byId, sectionOf } = index || indexOf(tree);
    const parts = [];
    const seen = new Set();
    for (let n = byId.get(nodeId); n && !seen.has(n.id); n = byId.get(n.parentId)) {
      seen.add(n.id);
      parts.unshift(n.title);
    }
    const section = sectionOf.get(nodeId);
    if (section) parts.unshift(section.title);
    return parts.join(' > ');
  }

  /** Every dropdown in the tree, with where it lives. */
  function dropdowns(tree) {
    const index = indexOf(tree);
    const out = [];
    for (const node of nodesOf(tree)) {
      for (const field of node.fields || []) {
        if (field.type === 'dropdown' && Array.isArray(field.options)) {
          out.push({ screenId: node.id, path: pathOf(tree, node.id, index), field });
        }
      }
    }
    return out;
  }

  const wordsOf = (field, value) => (
    field.optionLabels && Object.prototype.hasOwnProperty.call(field.optionLabels, value)
      ? field.optionLabels[value]
      : value
  );
  const isHidden = (field, value) => (field.hiddenOptions || []).includes(value);

  function matches(entry, query) {
    const q = String(query || '').trim().toLowerCase();
    if (!q) return true;
    if (entry.path.toLowerCase().includes(q)) return true;
    if (String(entry.field.label || '').toLowerCase().includes(q)) return true;
    return entry.field.options.some(
      (o) => o.toLowerCase().includes(q) || wordsOf(entry.field, o).toLowerCase().includes(q),
    );
  }

  /** Change an option's words. Going back to the original words removes the rename. */
  function rename(field, value, words) {
    const text = String(words).trim();
    const labels = { ...(field.optionLabels || {}) };
    if (text === value) delete labels[value];
    else labels[value] = text;
    if (Object.keys(labels).length) field.optionLabels = labels;
    else delete field.optionLabels;
  }

  function setHidden(field, value, hidden) {
    const list = (field.hiddenOptions || []).filter((o) => o !== value);
    if (hidden) list.push(value);
    if (list.length) field.hiddenOptions = list;
    else delete field.hiddenOptions;
  }

  /** A new option is stored and shown by its own words. Returns an error message or null. */
  function addOption(field, words) {
    const text = String(words).trim();
    if (!text) return 'Please type the option text.';
    const taken = field.options.some(
      (o) => wordsOf(field, o).toLowerCase() === text.toLowerCase() || o.toLowerCase() === text.toLowerCase(),
    );
    if (taken) return '"' + text + '" is already in this list.';
    field.options.push(text);
    return null;
  }

  /** What is wrong with a field's list, or null. The server checks the same. */
  function problemWith(field) {
    const words = [];
    for (const option of field.options) {
      const text = wordsOf(field, option);
      if (!String(text).trim()) return 'An option has no text.';
      if (!isHidden(field, option)) words.push(String(text).trim().toLowerCase());
    }
    if (words.length === 0) return 'At least one option must stay.';
    const twice = words.find((w, i) => words.indexOf(w) !== i);
    if (twice !== undefined) return '"' + twice + '" appears twice.';
    return null;
  }

  function problems(tree) {
    return dropdowns(tree)
      .map((entry) => ({ entry, problem: problemWith(entry.field) }))
      .filter((p) => p.problem);
  }

  /** Plain-language list of what changed in the dropdowns, for the review before publishing. */
  function optionChanges(before, after) {
    const old = new Map(dropdowns(before).map((e) => [e.screenId + '/' + e.field.id, e.field]));
    const changes = [];
    for (const entry of dropdowns(after)) {
      const was = old.get(entry.screenId + '/' + entry.field.id);
      if (!was) continue;
      const where = entry.path + ' > ' + entry.field.label;
      for (const option of entry.field.options) {
        if (!was.options.includes(option)) {
          changes.push({ where, what: 'Added "' + wordsOf(entry.field, option) + '"' });
          continue;
        }
        const from = wordsOf(was, option);
        const to = wordsOf(entry.field, option);
        if (from !== to) changes.push({ where, what: '"' + from + '" now reads "' + to + '"' });
        if (!isHidden(was, option) && isHidden(entry.field, option)) {
          changes.push({ where, what: 'Hid "' + to + '"' });
        }
        if (isHidden(was, option) && !isHidden(entry.field, option)) {
          changes.push({ where, what: 'Brought back "' + to + '"' });
        }
      }
    }
    return changes;
  }

  const sameTree = (a, b) => JSON.stringify(a) === JSON.stringify(b);

  /**
   * rules: { screenId: { fieldId: [option values that choose a written sentence] } }
   * A field listed there builds the report by choosing sentences, so a new option
   * prints nothing until a sentence is written for it.
   */
  const pickedSentence = (rules, screenId, fieldId, value) =>
    !!(rules && rules[screenId] && rules[screenId][fieldId] && rules[screenId][fieldId].includes(value));
  const fieldPicksSentences = (rules, screenId, fieldId) =>
    !!(rules && rules[screenId] && rules[screenId][fieldId]);

  return {
    TREE_TYPE, clone, nodesOf, pathOf, dropdowns, wordsOf, isHidden, matches, rename, setHidden,
    addOption, problemWith, problems, optionChanges, sameTree, pickedSentence, fieldPicksSentences,
  };
});

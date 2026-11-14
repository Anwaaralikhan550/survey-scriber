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

  /** Screens that have tick boxes: the words next to each box are text options too. */
  function tickLists(tree) {
    const index = indexOf(tree);
    const out = [];
    for (const node of nodesOf(tree)) {
      const ticks = (node.fields || []).filter((f) => f.type === 'checkbox');
      if (ticks.length) out.push({ screenId: node.id, path: pathOf(tree, node.id, index), title: node.title, ticks });
    }
    return out;
  }

  function matchesTicks(entry, query) {
    const q = String(query || '').trim().toLowerCase();
    if (!q) return true;
    return entry.path.toLowerCase().includes(q) || entry.ticks.some((f) => String(f.label || '').toLowerCase().includes(q));
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

  function optionChangesOf(was, now, where, changes) {
    for (const option of now.options || []) {
      if (!(was.options || []).includes(option)) {
        changes.push({ where, what: 'Added "' + wordsOf(now, option) + '"' });
        continue;
      }
      const from = wordsOf(was, option);
      const to = wordsOf(now, option);
      if (from !== to) changes.push({ where, what: '"' + from + '" now reads "' + to + '"' });
      if (!isHidden(was, option) && isHidden(now, option)) changes.push({ where, what: 'Hid "' + to + '"' });
      if (isHidden(was, option) && !isHidden(now, option)) changes.push({ where, what: 'Brought back "' + to + '"' });
    }
    for (const option of was.options || []) {
      if (!(now.options || []).includes(option)) changes.push({ where, what: 'Removed "' + wordsOf(was, option) + '"' });
    }
  }

  const nodeKind = (node) => (node.type === 'group' ? 'group' : 'screen');
  const conditionOf = (f) => [f.conditionalOn, f.conditionalValue, f.conditionalMode].map((v) => v || '').join('|');

  /** Plain-language list of everything that changed, for the review before publishing. */
  function treeChanges(before, after) {
    const changes = [];
    const old = indexOf(before);
    const now = indexOf(after);
    for (const node of nodesOf(after)) {
      const where = pathOf(after, node.id, now);
      const was = old.byId.get(node.id);
      if (!was) {
        changes.push({ where, what: 'Added ' + nodeKind(node) + ' "' + node.title + '"' });
        for (const f of node.fields || []) changes.push({ where: where + ' > ' + f.label, what: 'Added field "' + f.label + '"' });
        continue;
      }
      if (was.title !== node.title) changes.push({ where, what: '"' + was.title + '" is now called "' + node.title + '"' });
      if ((was.parentId || null) !== (node.parentId || null)) changes.push({ where, what: 'Moved "' + node.title + '"' });
      const oldFields = new Map((was.fields || []).map((f) => [f.id, f]));
      for (const f of node.fields || []) {
        const fieldWhere = where + ' > ' + f.label;
        const wasField = oldFields.get(f.id);
        if (!wasField) {
          changes.push({ where: fieldWhere, what: 'Added field "' + f.label + '"' });
          continue;
        }
        if (wasField.label !== f.label) changes.push({ where: fieldWhere, what: 'Field "' + wasField.label + '" is now called "' + f.label + '"' });
        if (conditionOf(wasField) !== conditionOf(f)) changes.push({ where: fieldWhere, what: 'Changed when "' + f.label + '" shows' });
        if ((wasField.phraseTemplate || '') !== (f.phraseTemplate || '')) changes.push({ where: fieldWhere, what: 'Changed the phrase template of "' + f.label + '"' });
        optionChangesOf(wasField, f, fieldWhere, changes);
      }
      const ids = new Set((node.fields || []).map((f) => f.id));
      for (const f of was.fields || []) {
        if (!ids.has(f.id)) changes.push({ where, what: 'Removed field "' + f.label + '"' });
      }
    }
    for (const node of nodesOf(before)) {
      if (!now.byId.has(node.id)) changes.push({ where: pathOf(before, node.id, old), what: 'Deleted ' + nodeKind(node) + ' "' + node.title + '"' });
    }
    return changes;
  }

  // ---- Survey Tree Management. Same rules and ids as the mobile admin. ----

  const FIELD_TYPES = ['text', 'number', 'checkbox', 'dropdown', 'label'];
  // Empty on purpose: the app hides it, and the server allows it too.
  const HIDDEN_EMPTY_GROUPS = ['group_outside_property_other_joinery_and_finishes_main_screen_80'];
  const FIELD_PREFIX = { checkbox: 'cb_', dropdown: 'android_material_design_spinner_', text: 'edittext_', number: 'number_', label: 'label_' };

  function stats(tree) {
    const nodes = nodesOf(tree);
    const fields = nodes.flatMap((n) => n.fields || []);
    return {
      sections: (tree.sections || []).length,
      groups: nodes.filter((n) => n.type === 'group').length,
      screens: nodes.filter((n) => n.type !== 'group').length,
      fields: fields.length,
      dropdowns: fields.filter((f) => f.type === 'dropdown').length,
      conditionals: fields.filter((f) => f.conditionalOn).length,
    };
  }

  /** A section's nodes in the order the app lists them, each with how deep it sits. */
  function rowsOf(section) {
    const nodes = section.nodes || [];
    const ids = new Set(nodes.map((n) => n.id));
    const children = new Map();
    for (const n of nodes) {
      const parent = n.parentId && ids.has(n.parentId) ? n.parentId : null;
      if (!children.has(parent)) children.set(parent, []);
      children.get(parent).push(n);
    }
    const rows = [];
    const seen = new Set();
    const walk = (parent, depth) => {
      for (const n of children.get(parent) || []) {
        if (seen.has(n.id)) continue;
        seen.add(n.id);
        rows.push({ node: n, depth });
        walk(n.id, depth + 1);
      }
    };
    walk(null, 0);
    return rows;
  }

  const slug = (hint) => String(hint).toLowerCase().replace(/[^a-z0-9]/g, '_').replace(/_+/g, '_').replace(/^_|_$/g, '');
  function uniqueId(base, taken) {
    if (!taken.has(base)) return base;
    for (let i = 2; ; i += 1) {
      if (!taken.has(base + '_' + i)) return base + '_' + i;
    }
  }

  function addNode(tree, sectionKey, { title, isGroup, parentId }) {
    const section = tree.sections.find((s) => s.key === sectionKey);
    const id = uniqueId((isGroup ? 'group_' : 'activity_') + slug(title), new Set(nodesOf(tree).map((n) => n.id)));
    const siblings = (section.nodes || []).filter((n) => (n.parentId || null) === (parentId || null));
    const order = siblings.reduce((max, n) => Math.max(max, n.order || 0), 0) + 1;
    const node = { id, title: String(title).trim(), type: isGroup ? 'group' : 'screen', parentId: parentId || null, order };
    if (!isGroup) node.fields = [];
    section.nodes.push(node);
    return node;
  }

  function descendantIds(tree, nodeId) {
    const nodes = nodesOf(tree);
    const found = new Set([nodeId]);
    for (let changed = true; changed;) {
      changed = false;
      for (const n of nodes) {
        if (!found.has(n.id) && n.parentId && found.has(n.parentId)) {
          found.add(n.id);
          changed = true;
        }
      }
    }
    return found;
  }

  function removeNode(tree, nodeId) {
    const gone = descendantIds(tree, nodeId);
    for (const section of tree.sections) section.nodes = section.nodes.filter((n) => !gone.has(n.id));
    return gone;
  }

  const splitOptions = (text) => String(text || '').split('\n').map((o) => o.trim()).filter(Boolean);

  /** The ids a condition such as "cb_a & !cb_b=true" reads. */
  function conditionKeys(expression) {
    return String(expression || '').split(/[|&]/)
      .map((token) => token.trim().replace('!', '').split('=')[0].trim())
      .filter(Boolean);
  }

  const placeholdersIn = (template) => [...String(template || '').matchAll(/\{([^}]+)\}/g)].map((m) => m[1]);

  /** Other fields on the screen that show or hide because of this one. */
  function dependentsOf(node, fieldId) {
    return (node.fields || []).filter((f) => f.id !== fieldId && conditionKeys(f.conditionalOn).includes(fieldId));
  }

  function fieldProblem(node, field) {
    if (!String(field.label || '').trim()) return 'The field needs a label.';
    if (!FIELD_TYPES.includes(field.type)) return 'Unknown field type "' + field.type + '".';
    const ids = new Map((node.fields || []).map((f) => [f.id, f]));
    ids.set(field.id, field);
    if (field.type === 'dropdown') {
      if (!field.options || field.options.length === 0) return 'A dropdown needs at least one option.';
      const words = TREE_LOWER(field.options);
      const twice = words.find((w, i) => words.indexOf(w) !== i);
      if (twice !== undefined) return 'Option "' + twice + '" is listed twice.';
      const wording = problemWith(field);
      if (wording) return wording;
    }
    for (const key of conditionKeys(field.conditionalOn)) {
      if (!ids.has(key)) return 'The condition reads "' + key + '", which is not on this screen.';
      if (key === field.id) return 'A field cannot depend on itself.';
    }
    if (field.conditionalMode && !['show', 'hide'].includes(field.conditionalMode)) return 'The condition must be show or hide.';
    const source = ids.get(field.conditionalOn);
    if (source && source.type === 'dropdown' && field.conditionalValue && !source.options.includes(field.conditionalValue)) {
      return 'The condition waits for "' + field.conditionalValue + '", which "' + source.label + '" does not offer.';
    }
    for (const key of placeholdersIn(field.phraseTemplate)) {
      if (!ids.has(key)) return 'The phrase template uses {' + key + '}, which is not on this screen.';
    }
    return null;
  }

  const TREE_LOWER = (list) => list.map((o) => String(o).trim().toLowerCase());

  /** Everything that would stop a publish, or break in the app, in plain words. */
  function treeProblems(tree) {
    const problems = [];
    const index = indexOf(tree);
    const seen = new Set();
    const parents = new Set();
    for (const node of nodesOf(tree)) {
      const where = pathOf(tree, node.id, index);
      if (seen.has(node.id)) problems.push({ nodeId: node.id, where, problem: 'Two nodes share the id "' + node.id + '".' });
      seen.add(node.id);
      if (!String(node.title || '').trim()) problems.push({ nodeId: node.id, where: where.replace(/( > )?$/, ' > (no title)').replace(/^ > /, ''), problem: 'A title is needed.' });
      if (node.parentId) {
        parents.add(node.parentId);
        if (!index.byId.has(node.parentId)) problems.push({ nodeId: node.id, where, problem: 'Its parent no longer exists.' });
      }
      const path = new Set([node.id]);
      for (let p = index.byId.get(node.parentId); p; p = index.byId.get(p.parentId)) {
        if (path.has(p.id)) {
          problems.push({ nodeId: node.id, where, problem: 'It is inside itself.' });
          break;
        }
        path.add(p.id);
      }
      const fieldIds = new Set();
      for (const field of node.fields || []) {
        if (fieldIds.has(field.id)) problems.push({ nodeId: node.id, where, problem: 'Two fields share the id "' + field.id + '".' });
        fieldIds.add(field.id);
        const problem = fieldProblem(node, field);
        if (problem) problems.push({ nodeId: node.id, where: where + ' > ' + field.label, problem });
      }
    }
    for (const node of nodesOf(tree)) {
      if (node.type === 'group' && !parents.has(node.id) && !HIDDEN_EMPTY_GROUPS.includes(node.id)) {
        problems.push({ nodeId: node.id, where: pathOf(tree, node.id, index), problem: 'This group is empty, so it would open blank. Add a screen to it or delete it.' });
      }
    }
    return problems;
  }

  /** Applies an edited field. Words for options no longer listed go with them. */
  function applyField(field, draft) {
    field.label = String(draft.label).trim();
    if (field.type === 'dropdown' && draft.options) {
      field.options = draft.options;
      if (field.optionLabels) {
        const kept = Object.fromEntries(Object.entries(field.optionLabels).filter(([k]) => draft.options.includes(k)));
        if (Object.keys(kept).length) field.optionLabels = kept;
        else delete field.optionLabels;
      }
      if (field.hiddenOptions) {
        const kept = field.hiddenOptions.filter((o) => draft.options.includes(o));
        if (kept.length) field.hiddenOptions = kept;
        else delete field.hiddenOptions;
      }
    }
    for (const key of ['conditionalOn', 'conditionalValue', 'conditionalMode', 'phraseTemplate']) {
      const value = String(draft[key] || '').trim();
      if (value) field[key] = value;
      else delete field[key];
    }
    if (!field.conditionalOn) {
      delete field.conditionalValue;
      delete field.conditionalMode;
    }
  }

  function newField(node, { label, type, options, phraseTemplate }) {
    const id = uniqueId(FIELD_PREFIX[type] + slug(label), new Set((node.fields || []).map((f) => f.id)));
    const field = { id, label: String(label).trim(), type };
    if (type === 'dropdown') field.options = options || [];
    const template = String(phraseTemplate || '').trim();
    if (template) field.phraseTemplate = template;
    return field;
  }

  /** Search across every section: screen and group names, ids and field labels. */
  function searchNodes(tree, query) {
    const q = String(query || '').trim().toLowerCase();
    if (!q) return [];
    const index = indexOf(tree);
    const found = [];
    for (const section of tree.sections || []) {
      for (const node of section.nodes || []) {
        const hit = String(node.title).toLowerCase().includes(q)
          || node.id.toLowerCase().includes(q)
          || (node.fields || []).some((f) => String(f.label).toLowerCase().includes(q) || f.id.toLowerCase().includes(q));
        if (hit) found.push({ node, sectionKey: section.key, path: pathOf(tree, node.id, index) });
      }
    }
    return found;
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
    TREE_TYPE, FIELD_TYPES, clone, nodesOf, pathOf, dropdowns, tickLists, matchesTicks, wordsOf, isHidden, matches, rename, setHidden,
    addOption, problemWith, problems, treeChanges, sameTree, pickedSentence, fieldPicksSentences,
    stats, rowsOf, addNode, descendantIds, removeNode, splitOptions, conditionKeys, placeholdersIn,
    dependentsOf, fieldProblem, treeProblems, applyField, newField, searchNodes,
  };
});

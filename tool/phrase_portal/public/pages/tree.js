'use strict';
/**
 * Survey Tree: what the mobile Survey Tree Manager does, on the web. Sections and
 * nodes, screen titles, fields, options, conditions, phrase templates, add and delete,
 * history and restore, back to the built-in tree, publish. The mobile page stays.
 */
(function () {
  const TL = window.TreeLogic;
  const TYPE_NAMES = { text: 'Text', number: 'Number', checkbox: 'Tick box', dropdown: 'Dropdown', label: 'Label' };
  // The new field has no id until its label is known.
  const THIS_FIELD = '{this field}';
  const view = { box: null, bar: null, list: null, detail: null, stats: null, picker: null, sectionKey: null, nodeId: null, query: '' };

  const data = () => SS.treeData.store;
  const isValuation = () => data().type === 'valuation';
  const section = () => data().tree.sections.find((s) => s.key === view.sectionKey);
  const nodeById = (id) => TL.nodesOf(data().tree).find((n) => n.id === id);
  const originalNode = (id) => TL.nodesOf(data().original).find((n) => n.id === id);

  function changed() {
    view.bar.update();
    renderStats();
  }

  function renderStats() {
    const s = TL.stats(data().tree);
    view.stats.replaceChildren(...[
      ['Sections', s.sections], ['Groups', s.groups], ['Screens', s.screens],
      ['Fields', s.fields], ['Dropdowns', s.dropdowns], ['Conditionals', s.conditionals],
    ].map(([label, n]) => SS.el('span', '', [SS.el('b', '', String(n)), SS.el('span', '', label)])));
  }

  function nodeButton(node, depth, sub, sectionKey) {
    const count = (node.fields || []).length;
    const b = SS.el('button', 'tree-node' + (node.id === view.nodeId ? ' active' : ''), [
      SS.el('span', 'kind', node.type === 'group' ? 'Group' : 'Screen'),
      SS.el('span', 'name', sub ? [SS.el('span', '', node.title), SS.el('small', '', sub)] : node.title),
      node.type === 'group' ? null : SS.el('span', 'count', String(count)),
    ]);
    b.type = 'button';
    b.style.paddingLeft = (8 + depth * 14) + 'px';
    b.title = node.title;
    b.addEventListener('click', () => {
      view.nodeId = node.id;
      if (sectionKey) {
        view.sectionKey = sectionKey;
        view.picker.value = sectionKey;
      }
      renderList();
      renderDetail();
    });
    return b;
  }

  function renderList() {
    if (view.query) {
      const found = TL.searchNodes(data().tree, view.query);
      view.list.replaceChildren(...(found.length
        ? found.slice(0, 100).map((r) => nodeButton(r.node, 0, r.path, r.sectionKey))
        : [SS.el('p', 'muted', 'Nothing matches. Try another word.')]));
      return;
    }
    const rows = TL.rowsOf(section());
    view.list.replaceChildren(...(rows.length
      ? rows.map((r) => nodeButton(r.node, r.depth))
      : [SS.el('p', 'muted', 'Nothing in this section yet.')]));
  }

  function fieldDetails(node, field) {
    const items = [];
    if (field.type === 'dropdown') items.push(SS.el('span', '', field.options.length + ' options'));
    if (field.conditionalOn) {
      const mode = field.conditionalMode === 'hide' ? 'Hidden when ' : 'Shows when ';
      items.push(SS.el('span', '', mode + field.conditionalOn + (field.conditionalValue ? ' = ' + field.conditionalValue : '')));
    }
    if (field.phraseTemplate) items.push(SS.el('span', '', 'Phrase template'));
    const before = originalNode(node.id);
    const isNew = !before || !(before.fields || []).some((f) => f.id === field.id);
    if (isNew && field.type !== 'label') items.push(SS.el('span', field.phraseTemplate && !isValuation() ? '' : 'warn', reportOutcome(field)));
    return SS.el('div', 'field-meta', items);
  }

  /** Measured in tree_new_field_report_test.dart. */
  function reportOutcome(field) {
    if (isValuation()) return 'Prints only as "label: answer", and only on a screen with no written sentences.';
    if (field.phraseTemplate) return 'Prints through its phrase template.';
    return 'No phrase template: prints nothing on a screen with written sentences.';
  }

  const TEMPLATE_HINT_HOME = 'What the report prints for this field. Use the buttons to put an answer into the sentence. Leave it empty and the field prints nothing on a screen with written sentences, or "label: answer" on a screen without.';
  const TEMPLATE_HINT_VALUATION = 'Valuation reports do not print phrase templates. A field shows as "label: answer" only on a screen with no written sentences.';

  async function addField(node) {
    const added = await SS.formBox({
      title: 'Add a field',
      intro: TL.pathOf(data().tree, node.id),
      okText: 'Add field',
      fields: [
        {
          name: 'type',
          label: 'Type',
          type: 'select',
          value: 'text',
          options: TL.FIELD_TYPES.map((t) => ({ value: t, label: TYPE_NAMES[t] })),
        },
        { name: 'label', label: 'Label', required: true, maxLength: 200 },
        {
          name: 'options',
          label: 'Options, one per line',
          type: 'textarea',
          rows: 5,
          showWhen: { name: 'type', values: ['dropdown'] },
        },
        {
          name: 'phraseTemplate',
          label: 'Phrase template',
          type: 'textarea',
          rows: 3,
          maxLength: 2000,
          hint: isValuation() ? TEMPLATE_HINT_VALUATION : TEMPLATE_HINT_HOME,
          tokens: [THIS_FIELD, ...(node.fields || []).filter((f) => f.type !== 'label').map((f) => '{' + f.id + '}')],
          showWhen: { name: 'type', values: ['text', 'number', 'checkbox', 'dropdown'] },
        },
      ],
      save: async (v) => {
        const field = TL.newField(node, { label: v.label, type: v.type, options: TL.splitOptions(v.options), phraseTemplate: v.phraseTemplate });
        if (field.phraseTemplate) field.phraseTemplate = field.phraseTemplate.split(THIS_FIELD).join('{' + field.id + '}');
        const problem = TL.fieldProblem(node, field);
        if (problem) return problem;
        node.fields = node.fields || [];
        node.fields.push(field);
        return null;
      },
    });
    if (added) {
      renderList();
      renderDetail();
      changed();
    }
  }

  async function editField(node, field) {
    const rules = (data().rules[node.id] || {})[field.id];
    const others = (node.fields || []).filter((f) => f.id !== field.id).map((f) => f.id);
    const saved = await SS.formBox({
      title: 'Edit field',
      intro: TYPE_NAMES[field.type] + ' · ' + field.id,
      okText: 'Save field',
      fields: [
        { name: 'label', label: 'Label', required: true, value: field.label, maxLength: 200 },
        ...(field.type === 'dropdown' ? [{
          name: 'options',
          label: 'Options, one per line',
          type: 'textarea',
          rows: 6,
          value: field.options.join('\n'),
          hint: 'These are the stored values. To reword an option without touching saved surveys, use Data Text Options.'
            + (rules ? ' Some of these choose a written sentence for the report: a removed one stops printing its sentence.' : ''),
        }] : []),
        {
          name: 'conditionalOn',
          label: 'Show this field when',
          value: field.conditionalOn,
          maxLength: 500,
          hint: others.length
            ? 'Leave empty to always show. A field on this screen, or an expression such as cb_a & !cb_b. On this screen: ' + others.join(', ')
            : 'Leave empty to always show. There are no other fields on this screen.',
        },
        { name: 'conditionalValue', label: 'Equals this answer', value: field.conditionalValue, maxLength: 200, hint: 'Leave empty to mean any answer.' },
        {
          name: 'conditionalMode',
          label: 'When that is true',
          type: 'select',
          value: field.conditionalMode || 'show',
          options: [{ value: 'show', label: 'Show the field' }, { value: 'hide', label: 'Hide the field' }],
        },
        ...(field.type === 'label' ? [] : [{
          name: 'phraseTemplate',
          label: 'Phrase template',
          type: 'textarea',
          rows: 3,
          value: field.phraseTemplate,
          maxLength: 2000,
          hint: isValuation() ? TEMPLATE_HINT_VALUATION : TEMPLATE_HINT_HOME,
          tokens: (node.fields || []).filter((f) => f.type !== 'label').map((f) => '{' + f.id + '}'),
        }]),
      ],
      save: async (v) => {
        const draft = TL.clone(field);
        const edit = {
          ...v,
          options: field.type === 'dropdown' ? TL.splitOptions(v.options) : undefined,
          // "Show" is what no mode means, so saying nothing stays saying nothing.
          conditionalMode: v.conditionalMode === 'show' && !field.conditionalMode ? '' : v.conditionalMode,
        };
        TL.applyField(draft, edit);
        const problem = TL.fieldProblem(node, draft);
        if (problem) return problem;
        TL.applyField(field, edit);
        return null;
      },
    });
    if (saved) {
      renderDetail();
      changed();
    }
  }

  async function removeField(node, field) {
    const dependents = TL.dependentsOf(node, field.id);
    const usedByReport = !!(data().rules[node.id] || {})[field.id];
    const parts = ['Answers already saved for it are kept, but it stops showing and printing.'];
    if (usedByReport) parts.push('The report uses this field to choose written sentences: those sentences stop printing.');
    if (dependents.length) parts.push('These fields depend on it and must be changed before publishing: ' + dependents.map((f) => f.label).join(', ') + '.');
    const yes = await SS.confirmBox({ title: 'Remove "' + field.label + '"?', body: parts.join(' '), okText: 'Remove field', danger: true });
    if (!yes) return;
    node.fields = node.fields.filter((f) => f.id !== field.id);
    renderList();
    renderDetail();
    changed();
  }

  async function deleteNode(node) {
    const ids = TL.descendantIds(data().tree, node.id);
    const inside = TL.nodesOf(data().tree).filter((n) => ids.has(n.id) && n.id !== node.id);
    const usedByReport = [...ids].filter((id) => data().reportNodes.has(id)).length;
    const parts = [];
    if (inside.length) parts.push('This also deletes the ' + inside.length + ' screens and groups inside it.');
    parts.push('Surveys keep their saved answers, but they stop showing and printing. Restoring an earlier version brings them back.');
    if (usedByReport) parts.push('The report has written sentences for ' + (usedByReport === 1 ? 'this' : usedByReport + ' of these') + ': they stop printing.');
    const parent = node.parentId ? nodeById(node.parentId) : null;
    if (parent && !TL.nodesOf(data().tree).some((n) => n.parentId === parent.id && n.id !== node.id)) {
      parts.push('"' + parent.title + '" would be left empty and must be deleted too before publishing.');
    }
    const yes = await SS.confirmBox({ title: 'Delete "' + node.title + '"?', body: parts.join(' '), okText: 'Delete', danger: true });
    if (!yes) return;
    TL.removeNode(data().tree, node.id);
    view.nodeId = null;
    renderList();
    renderDetail();
    changed();
  }

  async function addNode() {
    const groups = TL.rowsOf(section()).filter((r) => r.node.type === 'group');
    const current = view.nodeId ? nodeById(view.nodeId) : null;
    const startParent = current && groups.some((g) => g.node.id === current.id) ? current.id : '';
    let created = null;
    const added = await SS.formBox({
      title: 'Add to ' + section().title,
      okText: 'Add',
      fields: [
        { name: 'kind', label: 'Add a', type: 'select', value: 'screen', options: [{ value: 'screen', label: 'Screen' }, { value: 'group', label: 'Group' }] },
        { name: 'title', label: 'Title', required: true, maxLength: 200, hint: 'Shown in the app and in the report.' },
        {
          name: 'parent',
          label: 'Inside',
          type: 'select',
          value: startParent,
          options: [{ value: '', label: 'Top level of this section' },
            ...groups.map((g) => ({ value: g.node.id, label: ' '.repeat(g.depth * 3) + g.node.title }))],
        },
      ],
      save: async (v) => {
        if (!v.title) return 'Please type a title.';
        created = TL.addNode(data().tree, view.sectionKey, { title: v.title, isGroup: v.kind === 'group', parentId: v.parent || null });
        return null;
      },
    });
    if (added) {
      view.nodeId = created.id;
      renderList();
      renderDetail();
      changed();
    }
  }

  function renderDetail() {
    const node = view.nodeId ? nodeById(view.nodeId) : null;
    if (!node) {
      view.detail.replaceChildren(SS.emptyBox('Choose a screen or group', 'Pick one on the left to change it, or add a new one.'));
      return;
    }
    const titleInput = SS.el('input', 'node-title');
    titleInput.type = 'text';
    titleInput.value = node.title;
    titleInput.maxLength = 200;
    titleInput.setAttribute('aria-label', 'Title');
    const titleProblem = SS.el('div', 'alert err', 'A title is needed before publishing.');
    titleProblem.hidden = !!String(node.title).trim();
    titleInput.addEventListener('input', () => {
      node.title = titleInput.value.trim();
      titleProblem.hidden = !!node.title;
      renderList();
      changed();
    });

    const head = SS.el('div', 'card', [
      SS.el('div', 'detail-head', [
        SS.el('span', 'muted', (node.type === 'group' ? 'Group' : 'Screen') + ' in ' + TL.pathOf(data().tree, node.id)),
        SS.button('Delete', () => deleteNode(node), 'danger'),
      ]),
      titleInput,
      titleProblem,
      SS.el('div', 'id', node.id),
    ]);

    if (node.type === 'group') {
      const children = TL.nodesOf(data().tree).filter((n) => n.parentId === node.id);
      const blocked = TL.treeProblems(data().tree).some((p) => p.nodeId === node.id);
      view.detail.replaceChildren(head, SS.el('div', 'card', [
        SS.el('h3', '', 'Inside this group'),
        children.length
          ? SS.el('div', '', children.map((c) => nodeButton(c, 0)))
          : blocked
            ? SS.el('div', 'alert warn', 'Empty. Add a screen to it, or delete it, before publishing.')
            : SS.el('p', 'muted', 'Empty on purpose: the app does not show this group.'),
        SS.button('Add a screen or group here', addNode),
      ]));
      return;
    }

    const fields = node.fields || [];
    view.detail.replaceChildren(head, SS.el('div', 'card', [
      SS.el('div', 'detail-head', [
        SS.el('h3', '', fields.length + (fields.length === 1 ? ' field' : ' fields')),
        SS.button('Add a field', () => addField(node), 'primary'),
      ]),
      fields.length
        ? SS.table([
          {
            title: 'Field',
            cell: (f) => SS.el('div', '', [SS.el('div', '', f.label), SS.el('div', 'id', f.id), fieldDetails(node, f)]),
          },
          { title: 'Type', cell: (f) => TYPE_NAMES[f.type] || f.type },
          {
            title: '',
            cls: 'actions',
            cell: (f) => {
              const edit = SS.button('Edit', () => editField(node, f));
              edit.setAttribute('aria-label', 'Edit ' + f.label);
              const remove = SS.button('Remove', () => removeField(node, f));
              remove.setAttribute('aria-label', 'Remove ' + f.label);
              return SS.el('div', '', [edit, remove]);
            },
          },
        ], fields)
        : SS.emptyBox('No fields yet', 'Add the first field. A screen with no fields opens blank in the app.'),
    ]));
  }

  async function open(type) {
    view.box.replaceChildren(SS.loadingBox('Loading the survey tree…'));
    const error = await SS.treeData.load(type);
    if (error) {
      view.box.replaceChildren(SS.errorBox(error, () => open(type)));
      return;
    }
    build();
  }

  function build() {
    const keys = data().tree.sections.map((s) => s.key);
    if (!keys.includes(view.sectionKey)) view.sectionKey = keys[0];
    if (view.nodeId && !nodeById(view.nodeId)) view.nodeId = null;

    const reset = SS.button('Back to built-in tree', async () => {
      const yes = await SS.confirmBox({
        title: 'Go back to the tree built into the app?',
        body: 'Your unpublished changes and everything published so far are replaced here. Nothing goes live until you publish, and earlier versions stay in History.',
        okText: 'Use built-in tree',
        danger: true,
      });
      if (!yes) return;
      SS.treeData.resetToBuiltIn();
      view.nodeId = null;
      build();
    });
    view.bar = SS.treeData.statusBar(open, [reset]);
    view.stats = SS.el('div', 'tree-stats');
    view.list = SS.el('div', 'tree-nodes');
    view.detail = SS.el('div', 'tree-detail');

    const picker = SS.el('select', '', data().tree.sections.map((s) => {
      const o = SS.el('option', '', s.title);
      o.value = s.key;
      o.selected = s.key === view.sectionKey;
      return o;
    }));
    picker.setAttribute('aria-label', 'Section');
    view.picker = picker;
    picker.addEventListener('change', () => {
      view.sectionKey = picker.value;
      view.nodeId = null;
      renderList();
      renderDetail();
    });
    const search = SS.searchBox('Search every section', view.query, (q) => {
      view.query = q;
      renderList();
    });

    view.box.replaceChildren(
      view.bar,
      view.stats,
      SS.el('div', 'tree-layout', [
        SS.el('div', 'tree-nav', [picker, search, SS.button('Add a screen or group', addNode), view.list]),
        view.detail,
      ]),
    );
    renderStats();
    renderList();
    renderDetail();
  }

  window.SSPages.tree = {
    render(box) {
      view.box = box;
      view.query = '';
      open(data().type);
    },
    unsaved: () => SS.treeData.hasChanges(),
  };
})();

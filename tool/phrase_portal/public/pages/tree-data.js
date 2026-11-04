'use strict';
/**
 * The survey tree being edited, shared by Data Text Options and Survey Tree: both
 * change the same document, and one publish sends it to the phones.
 */
(function () {
  const TL = window.TreeLogic;

  const store = {
    type: 'inspection',     // inspection | valuation
    bundled: {},            // {inspection: {version, tree}, ...} from the app build
    published: null,        // {version, tree, publishedAt} as loaded
    tree: null,             // the working copy
    rules: {},              // options that choose a written sentence
    reportNodes: new Set(), // nodes the report's code asks for by id
    stale: false,           // published tree was made for an older app
  };

  async function assetJson(path) {
    const r = await fetch(path, { cache: 'no-store' });
    if (!r.ok) throw new Error('Could not load ' + path + ' (' + r.status + ')');
    return r.json();
  }

  /** Loads the latest published tree, or the app's own when none fits. Returns an error or null. */
  async function load(type) {
    store.type = type;
    store.tree = null;
    try {
      const [baseline, meta, rules, reportNodes] = await Promise.all([
        assetJson('assets/trees/' + type + '.json'),
        assetJson('assets/trees/meta.json'),
        assetJson('assets/trees/option_rules.json'),
        assetJson('assets/trees/report_nodes.json'),
      ]);
      store.bundled[type] = { version: meta[type], tree: baseline };
      store.rules = rules[type] || {};
      store.reportNodes = new Set(reportNodes[type] || []);
    } catch (e) {
      return e.message;
    }

    const r = await SS.apiJson('/admin/config/v2-tree/latest/' + TL.TREE_TYPE[type], { auth: true });
    const bundled = store.bundled[type];
    const start = (tree) => {
      const copy = TL.clone(tree);
      copy.baseBundledVersion = bundled.version;
      return copy;
    };

    store.stale = false;
    if (r.status === 200 && r.body.tree) {
      store.published = { version: r.body.version, publishedAt: r.body.publishedAt, tree: r.body.tree };
      if (r.body.tree.baseBundledVersion === bundled.version) {
        store.original = start(r.body.tree);
      } else {
        // Made for another version of the app, so phones ignore it. Work from the
        // tree in this version of the app.
        store.stale = true;
        store.original = start(bundled.tree);
      }
    } else if (r.status === 404) {
      store.published = null;
      store.original = start(bundled.tree);
    } else {
      return SS.messageOf(r, 'The survey tree could not be loaded.');
    }
    store.tree = TL.clone(store.original);
    return null;
  }

  function hasChanges() {
    return !!store.tree && !TL.sameTree(store.tree, store.original);
  }

  /** Returns an error message, or null when published. */
  async function publish() {
    const r = await SS.apiJson('/admin/config/v2-tree/upload', {
      method: 'POST',
      auth: true,
      body: {
        treeType: TL.TREE_TYPE[store.type],
        tree: store.tree,
        baseVersion: store.published ? store.published.version : 0,
      },
    });
    if (r.status !== 201) return SS.messageOf(r, 'The survey tree could not be published.');
    store.lastPublished = r.body;
    return null;
  }

  async function history() {
    return SS.apiJson('/admin/config/v2-tree/versions/' + TL.TREE_TYPE[store.type], { auth: true });
  }

  async function restore(version) {
    return SS.apiJson('/admin/config/v2-tree/rollback/' + TL.TREE_TYPE[store.type], {
      method: 'POST',
      auth: true,
      body: { version, baseVersion: store.published ? store.published.version : 0 },
    });
  }

  /** The line above both pages: what is live, and the buttons. */
  function statusBar(onReload, extraButtons) {
    const status = store.published
      ? 'Live: version ' + store.published.version + ', published ' + SS.fmtDate(store.published.publishedAt)
      : 'Nothing published yet: phones use the tree built into the app.';
    const typeSelect = SS.el('select', '', [['inspection', 'Home Survey'], ['valuation', 'Valuation']].map(([v, label]) => {
      const o = SS.el('option', '', label);
      o.value = v;
      o.selected = v === store.type;
      return o;
    }));
    typeSelect.setAttribute('aria-label', 'Survey type');
    typeSelect.addEventListener('change', async () => {
      if (hasChanges() && !confirm('Your unpublished changes will be lost. Continue?')) {
        typeSelect.value = store.type;
        return;
      }
      onReload(typeSelect.value);
    });

    const publishBtn = SS.button('Publish', () => review(onReload), 'primary');
    const discardBtn = SS.button('Discard changes', async () => {
      if (await SS.confirmBox({ title: 'Discard your changes?', body: 'Nothing has been published.', okText: 'Discard', danger: true })) {
        onReload(store.type);
      }
    });
    publishBtn.disabled = !hasChanges();
    discardBtn.disabled = !hasChanges();

    const bar = SS.el('div', 'toolbar tree-bar', [
      typeSelect,
      SS.el('span', 'muted tree-status', status),
      SS.el('span', 'spacer'),
      SS.button('History', () => showHistory(onReload)),
      ...(extraButtons || []),
      discardBtn,
      publishBtn,
    ]);
    const wrap = SS.el('div', '', [bar]);
    if (store.stale) {
      wrap.append(SS.el('div', 'alert warn',
        'The last publish (version ' + store.published.version + ') was made for an older version of the app, so phones on this version ignore it. '
        + 'You are working from the tree in this version of the app. Earlier changes need making again.'));
    }
    wrap.update = () => {
      publishBtn.disabled = !hasChanges();
      discardBtn.disabled = !hasChanges();
    };
    return wrap;
  }

  async function review(onReload) {
    const trouble = TL.treeProblems(store.tree);
    if (trouble.length) {
      const more = trouble.length > 1 ? ' (and ' + (trouble.length - 1) + ' more)' : '';
      SS.toast(trouble[0].where + ': ' + trouble[0].problem + more, 'err');
      return;
    }
    const items = TL.treeChanges(store.original, store.tree);
    const list = SS.el('ul', 'review-list', items.slice(0, 40).map((c) =>
      SS.el('li', '', [SS.el('b', '', c.what), SS.el('span', 'muted', c.where)])));
    const more = items.length > 40 ? SS.el('p', 'muted', 'And ' + (items.length - 40) + ' more.') : null;
    const dialogBody = [
      SS.el('h3', '', 'Publish to all phones?'),
      SS.el('p', 'muted', 'Phones pick this up the next time the app is opened with internet. Surveys already filled in keep their answers.'),
      list, more,
    ];
    let go = false;
    const cancel = SS.button('Cancel', () => dialog.close());
    const ok = SS.button('Publish', () => { go = true; dialog.close(); }, 'primary');
    const dialog = SS.openDialog([...dialogBody, SS.el('div', 'dialog-actions', [cancel, ok])], async () => {
      if (!go) return;
      SS.toast('Publishing…');
      const error = await publish();
      if (error) { SS.toast(error, 'err'); return; }
      SS.toast(store.lastPublished.unchanged ? 'Already live, nothing changed.' : 'Published: version ' + store.lastPublished.version, 'ok');
      onReload(store.type);
    });
    cancel.focus();
  }

  async function showHistory(onReload) {
    const r = await history();
    if (r.status !== 200) { SS.toast(SS.messageOf(r, 'The history could not be loaded.'), 'err'); return; }
    const body = r.body.length
      ? SS.table([
        { title: 'Version', cell: (v) => v.version },
        { title: 'Published', cell: (v) => SS.fmtDate(v.publishedAt) },
        { title: 'By', cell: (v) => v.publishedBy },
        {
          title: '',
          cls: 'actions',
          cell: (v) => (v.version === store.published.version
            ? SS.el('span', 'pill ok', 'Live')
            : SS.el('div', '', [SS.button('Restore', async () => {
              const yes = await SS.confirmBox({
                title: 'Restore version ' + v.version + '?',
                body: 'It goes live as a new version. Later versions stay in this history.',
                okText: 'Restore',
              });
              if (!yes) return;
              dialog.close();
              const res = await restore(v.version);
              if (res.status !== 201) { SS.toast(SS.messageOf(res, 'It could not be restored.'), 'err'); return; }
              SS.toast('Restored as version ' + res.body.version, 'ok');
              onReload(store.type);
            })])),
        },
      ], r.body)
      : SS.emptyBox('Nothing published yet', 'Phones use the tree built into the app.');
    const close = SS.button('Close', () => dialog.close());
    const dialog = SS.openDialog([
      SS.el('h3', '', 'Published versions'),
      body,
      SS.el('div', 'dialog-actions', [close]),
    ]);
    dialog.classList.add('wide');
  }

  /** Starts again from the tree built into the app. Nothing is live until published. */
  function resetToBuiltIn() {
    const copy = TL.clone(store.bundled[store.type].tree);
    copy.baseBundledVersion = store.bundled[store.type].version;
    store.tree = copy;
  }

  SS.treeData = { store, load, hasChanges, statusBar, resetToBuiltIn };
})();

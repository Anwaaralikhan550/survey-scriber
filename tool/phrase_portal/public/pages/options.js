'use strict';
/**
 * Data Text Options: the text of every dropdown in the survey. Publishes to the
 * phones without the developers. Surveys keep what they stored, so renaming an
 * option never breaks a survey already filled in.
 */
(function () {
  const TL = window.TreeLogic;
  const PAGE_SIZE = 20;
  const view = { box: null, list: null, bar: null, query: '', page: 1, changedOnly: false };

  const data = () => SS.treeData.store;

  function reviewItems() {
    return TL.optionChanges(data().original, data().tree);
  }

  function optionRow(entry, option) {
    const { field } = entry;
    const hidden = TL.isHidden(field, option);
    const words = TL.wordsOf(field, option);

    const input = SS.el('input', 'option-input');
    input.type = 'text';
    input.value = words;
    input.maxLength = 200;
    input.setAttribute('aria-label', 'Text for option ' + option);
    input.disabled = hidden;

    const notes = SS.el('div', 'option-notes');
    function showNotes() {
      const renamed = TL.wordsOf(field, option) !== option;
      const items = [];
      if (renamed) items.push(SS.el('span', 'muted', 'Original: ' + option));
      notes.replaceChildren(...items);
    }
    showNotes();

    input.addEventListener('input', () => {
      TL.rename(field, option, input.value);
      showNotes();
      refreshProblem(entry);
      view.bar.update();
    });

    const toggle = SS.button(hidden ? 'Bring back' : 'Hide', () => {
      TL.setHidden(field, option, !hidden);
      renderList();
      view.bar.update();
    });
    toggle.setAttribute('aria-label', (hidden ? 'Bring back ' : 'Hide ') + words);

    return SS.el('div', 'option-row' + (hidden ? ' hidden-option' : ''), [input, toggle, notes]);
  }

  function refreshProblem(entry) {
    const slot = view.list.querySelector('[data-problem="' + CSS.escape(entry.screenId + '/' + entry.field.id) + '"]');
    if (!slot) return;
    const problem = TL.problemWith(entry.field);
    slot.textContent = problem || '';
    slot.hidden = !problem;
  }

  async function addTo(entry) {
    const warn = TL.fieldPicksSentences(data().rules, entry.screenId, entry.field.id)
      ? 'This list chooses written sentences. A new option can be picked in the app, but no report sentence exists for it until one is written.'
      : 'The words are printed in the report as you type them.';
    const added = await SS.formBox({
      title: 'Add an option',
      intro: entry.path + ' > ' + entry.field.label,
      fields: [{ name: 'words', label: 'Option text', required: true, maxLength: 200, hint: warn }],
      okText: 'Add',
      save: async (v) => TL.addOption(entry.field, v.words),
    });
    if (added) {
      renderList();
      view.bar.update();
    }
  }

  /** Which options choose a sentence: renaming those changes the list, not the sentence. */
  function sentenceNote(entry) {
    const { field, screenId } = entry;
    const picking = field.options.filter((o) => TL.pickedSentence(data().rules, screenId, field.id, o));
    if (!picking.length) return null;
    const who = picking.length === field.options.length
      ? 'Every option here chooses'
      : picking.map((o) => '"' + TL.wordsOf(field, o) + '"').join(', ') + (picking.length === 1 ? ' chooses' : ' choose');
    return SS.el('div', 'option-note', who + ' a written sentence for the report. To change a sentence, use Phrases.');
  }

  function fieldCard(entry) {
    const problem = SS.el('div', 'alert err');
    problem.dataset.problem = entry.screenId + '/' + entry.field.id;
    const currentProblem = TL.problemWith(entry.field);
    problem.textContent = currentProblem || '';
    problem.hidden = !currentProblem;
    return SS.el('div', 'card option-card', [
      SS.el('div', 'option-path muted', entry.path),
      SS.el('h3', '', entry.field.label),
      sentenceNote(entry),
      ...entry.field.options.map((o) => optionRow(entry, o)),
      problem,
      SS.button('Add an option', () => addTo(entry)),
    ]);
  }

  function renderList() {
    const original = new Map(view.changedOnly
      ? TL.dropdowns(data().original).map((e) => [e.screenId + '/' + e.field.id, JSON.stringify(e.field)])
      : []);
    const all =TL.dropdowns(data().tree).filter((e) => TL.matches(e, view.query)
      && (!view.changedOnly || original.get(e.screenId + '/' + e.field.id) !== JSON.stringify(e.field)));
    const pages = Math.max(1, Math.ceil(all.length / PAGE_SIZE));
    if (view.page > pages) view.page = pages;
    const shown = all.slice((view.page - 1) * PAGE_SIZE, view.page * PAGE_SIZE);
    if (all.length === 0) {
      view.list.replaceChildren(SS.emptyBox(
        view.changedOnly ? 'No changes yet' : 'No list matches',
        view.changedOnly ? 'Lists you change will show here.' : 'Try another word.',
      ));
      return;
    }
    view.list.replaceChildren(
      ...shown.map(fieldCard),
      SS.pager(view.page, PAGE_SIZE, all.length, (p) => { view.page = p; renderList(); document.getElementById('pageView').scrollTop = 0; }),
    );
  }

  async function open(type) {
    view.box.replaceChildren(SS.loadingBox('Loading the survey lists…'));
    const error = await SS.treeData.load(type);
    if (error) {
      view.box.replaceChildren(SS.errorBox(error, () => open(type)));
      return;
    }
    view.page = 1;
    view.changedOnly = false; // a fresh load has no changes to show
    view.bar = SS.treeData.statusBar(open, reviewItems);
    view.list = SS.el('div', 'option-list');
    const search = SS.searchBox('Search a screen, list or option', view.query, (q) => {
      view.query = q;
      view.page = 1;
      renderList();
    });
    const changed = SS.el('input');
    changed.type = 'checkbox';
    changed.checked = view.changedOnly;
    changed.addEventListener('change', () => { view.changedOnly = changed.checked; view.page = 1; renderList(); });
    view.box.replaceChildren(
      view.bar,
      SS.el('p', 'muted page-intro', 'The text people pick from in the survey. New words also print in the report. Surveys already filled in keep their answers and show the new words.'),
      SS.el('div', 'toolbar', [search, SS.el('label', 'check-label', [changed, SS.el('span', '', 'Show only what I changed')])]),
      view.list,
    );
    renderList();
  }

  window.SSPages.options = {
    render(box) {
      view.box = box;
      view.query = '';
      view.changedOnly = false;
      open(data().type);
    },
    unsaved: () => SS.treeData.hasChanges(),
  };
})();

'use strict';
/**
 * Field Users and Sub Admins: the same page over two groups of accounts.
 * Users are deactivated, never deleted, because their surveys belong to them.
 */
(function () {
  const LIMIT = 20;

  function page(group) {
    const isStaff = group === 'staff';
    const noun = isStaff ? 'sub admin' : 'field user';
    const view = { q: '', status: '', page: 1, box: null, list: null };

    const isAdmin = () => SS.state.session.role === 'ADMIN';
    const roleChoices = () => (isStaff
      ? [{ value: 'MANAGER', label: 'Sub Admin' }, { value: 'ADMIN', label: 'Administrator' }]
      : [{ value: 'SURVEYOR', label: 'Field User' }, { value: 'VIEWER', label: 'Viewer' }]);

    function fullName(u) {
      return [u.firstName, u.lastName].filter(Boolean).join(' ');
    }

    async function load() {
      view.list.replaceChildren(SS.loadingBox());
      const params = new URLSearchParams({ group, page: view.page, limit: LIMIT });
      if (view.q) params.set('q', view.q);
      if (view.status) params.set('isActive', view.status === 'active');
      const r = await SS.apiJson('/admin/users?' + params, { auth: true });
      if (r.status !== 200) {
        view.list.replaceChildren(SS.errorBox(SS.messageOf(r, 'The users could not be loaded.'), load));
        return;
      }
      const { data, meta } = r.body;
      // Deleting or filtering can leave us past the last page.
      if (data.length === 0 && view.page > 1 && meta.total > 0) { view.page = 1; load(); return; }
      if (data.length === 0) {
        view.list.replaceChildren(view.q || view.status
          ? SS.emptyBox('No user matches', 'Try another search or status.')
          : SS.emptyBox('No ' + noun + 's yet', 'Add the first one with the button above.'));
        return;
      }
      view.list.replaceChildren(
        SS.table([
          { title: 'Name', cell: fullName },
          { title: 'Email', cell: (u) => u.email },
          { title: 'Phone', cell: (u) => u.phone },
          { title: 'Role', cell: (u) => AdminLogic.roleLabel(u.role) },
          { title: 'Status', cell: (u) => SS.el('span', 'pill ' + (u.isActive ? 'ok' : 'off'), u.isActive ? 'Active' : 'Deactivated') },
          { title: 'Last login', cell: (u) => (u.lastLoginAt ? SS.fmtDay(u.lastLoginAt) : 'Never') },
          { title: '', cls: 'actions', cell: actions },
        ], data),
        SS.pager(meta.page, meta.limit, meta.total, (p) => { view.page = p; load(); }),
      );
    }

    function actions(u) {
      const me = u.email === SS.state.session.email;
      const box = SS.el('div', '', [
        SS.button('Edit', () => edit(u)),
        u.isActive ? SS.button('Send password', () => passwordEmail(u)) : null,
        me ? null : (u.isActive
          ? SS.button('Deactivate', () => deactivate(u))
          : SS.button('Activate', () => activate(u))),
      ]);
      return box;
    }

    async function add() {
      await SS.formBox({
        title: 'Add ' + noun,
        fields: [
          { name: 'firstName', label: 'First name', required: true, maxLength: 100 },
          { name: 'lastName', label: 'Last name', maxLength: 100 },
          { name: 'email', label: 'Email', type: 'email', required: true, maxLength: 255, autocomplete: 'off' },
          { name: 'phone', label: 'Phone', type: 'tel', maxLength: 50 },
          { name: 'role', label: 'Role', type: 'select', options: roleChoices(), value: roleChoices()[0].value },
          {
            name: 'password', label: 'Password', type: 'password', autocomplete: 'new-password', maxLength: 128,
            hint: 'Leave empty to email them a link to set their own. Otherwise: at least 8 characters with upper case, lower case, a number and a symbol.',
          },
        ],
        okText: 'Add',
        save: async (v) => {
          const body = { firstName: v.firstName, email: v.email, role: v.role };
          if (v.lastName) body.lastName = v.lastName;
          if (v.phone) body.phone = v.phone;
          if (v.password) body.password = v.password;
          const r = await SS.apiJson('/admin/users', { method: 'POST', auth: true, body });
          if (r.status !== 201) return SS.messageOf(r, 'The user could not be added.');
          if (r.body.emailSent === false) {
            SS.toast('User added, but the email could not be sent. Use Send password to try again.', 'err');
          } else if (r.body.emailSent) {
            SS.toast('User added. A link to set their password was emailed to them.', 'ok');
          } else {
            SS.toast('User added.', 'ok');
          }
          return null;
        },
      }) && load();
    }

    async function edit(u) {
      const fields = [
        { name: 'firstName', label: 'First name', value: u.firstName, required: true, maxLength: 100 },
        { name: 'lastName', label: 'Last name', value: u.lastName, maxLength: 100 },
        { name: 'phone', label: 'Phone', type: 'tel', value: u.phone, maxLength: 50 },
      ];
      const canChangeRole = isAdmin() && u.email !== SS.state.session.email;
      if (canChangeRole) {
        fields.push({
          name: 'role', label: 'Role', type: 'select', value: u.role,
          options: [
            { value: 'SURVEYOR', label: 'Field User' },
            { value: 'VIEWER', label: 'Viewer' },
            { value: 'MANAGER', label: 'Sub Admin' },
            { value: 'ADMIN', label: 'Administrator' },
          ],
        });
      }
      await SS.formBox({
        title: 'Edit ' + (fullName(u) || u.email),
        intro: u.email,
        fields,
        save: async (v) => {
          const body = { firstName: v.firstName, lastName: v.lastName || null, phone: v.phone || null };
          if (canChangeRole) body.role = v.role;
          const r = await SS.apiJson('/admin/users/' + u.id, { method: 'PATCH', auth: true, body });
          if (r.status !== 200) return SS.messageOf(r, 'The changes could not be saved.');
          SS.toast('Saved.', 'ok');
          return null;
        },
      }) && load();
    }

    async function passwordEmail(u) {
      const yes = await SS.confirmBox({
        title: 'Send password email?',
        body: u.email + ' will get a link to set a new password.',
        okText: 'Send',
      });
      if (!yes) return;
      const r = await SS.apiJson('/admin/users/' + u.id + '/send-password-email', { method: 'POST', auth: true });
      if (r.status !== 200) { SS.toast(SS.messageOf(r, 'The email could not be sent.'), 'err'); return; }
      if (r.body.emailSent) SS.toast('Password email sent to ' + u.email, 'ok');
      else SS.toast('The email could not be sent. Please check the mail settings.', 'err');
    }

    async function setActive(u, action) {
      const r = await SS.apiJson('/admin/users/' + u.id + '/' + action, { method: 'POST', auth: true });
      if (r.status !== 200) { SS.toast(SS.messageOf(r), 'err'); return; }
      SS.toast(action === 'activate' ? 'Account activated.' : 'Account deactivated.', 'ok');
      load();
    }

    async function deactivate(u) {
      const yes = await SS.confirmBox({
        title: 'Deactivate this account?',
        body: (fullName(u) || u.email) + ' will be signed out at once and cannot sign in. Their surveys stay safe. You can activate the account again.',
        okText: 'Deactivate',
        danger: true,
      });
      if (yes) setActive(u, 'deactivate');
    }

    function activate(u) {
      setActive(u, 'activate');
    }

    return {
      render(box) {
        view.box = box;
        view.page = 1;
        view.q = '';
        view.status = '';
        const status = SS.el('select', '', [['', 'All statuses'], ['active', 'Active'], ['inactive', 'Deactivated']].map(([value, label]) => {
          const o = SS.el('option', '', label);
          o.value = value;
          return o;
        }));
        status.setAttribute('aria-label', 'Status');
        status.addEventListener('change', () => { view.status = status.value; view.page = 1; load(); });
        const search = SS.searchBox('Search name, email or phone', '', (q) => { view.q = q; view.page = 1; load(); });
        view.list = SS.el('div');
        box.append(
          SS.el('div', 'toolbar', [search, status, SS.el('span', 'spacer'), SS.button('Add ' + noun, add, 'primary')]),
          view.list,
        );
        load();
      },
    };
  }

  window.SSPages.fieldUsers = page('field');
  window.SSPages.subAdmins = page('staff');
})();

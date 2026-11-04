'use strict';
/** The numbers at the top of the Dashboard, and the same tiles as the mobile Admin Dashboard. */
(function () {
  const SURVEY_LABELS = {
    DRAFT: 'Live',
    IN_PROGRESS: 'In Progress',
    PAUSED: 'Paused',
    COMPLETED: 'Completed',
    PENDING_REVIEW: 'Pending Review',
    APPROVED: 'Approved',
    REJECTED: 'Rejected',
  };
  const BOOKING_LABELS = { PENDING: 'Pending', CONFIRMED: 'Confirmed', COMPLETED: 'Completed', CANCELLED: 'Cancelled' };
  const ACTIVITY = {
    'user.created': 'User added',
    'user.updated': 'User edited',
    'user.role_changed': 'User role changed',
    'user.activated': 'User activated',
    'user.deactivated': 'User deactivated',
    'user.password_email_sent': 'Password email sent',
    'staff.login': 'Signed in',
    'staff.logout': 'Signed out',
  };

  function statCard(title, big, rows) {
    return SS.el('div', 'card', [
      SS.el('div', 'k', title),
      SS.el('div', 'v', String(big)),
      SS.el('dl', 'stat-rows', rows.flatMap(([label, value]) => [SS.el('dt', '', label), SS.el('dd', '', String(value))])),
    ]);
  }

  function sum(counts) {
    return Object.values(counts).reduce((a, b) => a + b, 0);
  }

  function tile(title, note, view) {
    const box = SS.el(view ? 'button' : 'div', 'tile' + (view ? '' : ' off'), [
      SS.el('b', '', title),
      SS.el('span', '', note),
    ]);
    if (view) {
      box.type = 'button';
      box.addEventListener('click', () => SS.go(view));
    }
    return box;
  }

  async function load(box) {
    box.replaceChildren(SS.loadingBox('Loading the numbers…'));
    const r = await SS.apiJson('/admin/users/summary', { auth: true });
    if (r.status !== 200) {
      box.replaceChildren(SS.errorBox(SS.messageOf(r, 'The numbers could not be loaded.'), () => load(box)));
      return;
    }
    const s = r.body;
    const isAdmin = SS.state.session.role === 'ADMIN';

    const content = [
      SS.el('div', 'cards', [
        statCard('Users', s.users.total, [
          ['Field users', s.users.fieldUsers],
          ['Sub admins', s.users.subAdmins],
          ['Administrators', s.users.administrators],
          ['Viewers', s.users.viewers],
          ['Deactivated', s.users.inactive],
        ]),
        statCard('Surveys', sum(s.surveys), Object.entries(SURVEY_LABELS).map(([k, label]) => [label, s.surveys[k]])),
        statCard('Bookings', sum(s.bookings), Object.entries(BOOKING_LABELS).map(([k, label]) => [label, s.bookings[k]])),
      ]),
      SS.el('h3', 'section-title', 'Administration'),
      SS.el('div', 'tiles', [
        tile('Field Users', 'Add, edit and deactivate surveyors', 'fieldUsers'),
        isAdmin ? tile('Sub Admins', 'Staff who help run the app', 'subAdmins') : null,
        tile('Survey Tree', 'Screens and fields of the survey', 'tree'),
        tile('Data Text Options', 'The text in the dropdown lists', 'options'),
        isAdmin ? tile('Email Templates', 'What the app sends by email', 'email') : null,
        isAdmin ? tile('Settings', 'Company details and app settings', 'settings') : null,
        tile('Client Management', 'In the mobile app'),
        tile('Data Export', 'In the mobile app'),
        tile('Integrations', 'In the mobile app'),
        tile('Billing & Invoices', 'In the mobile app'),
        tile('Audit Logs', 'In the mobile app'),
      ]),
    ];

    if (isAdmin) {
      content.push(SS.el('h3', 'section-title', 'Recent activity'));
      content.push(s.recentActivity.length
        ? SS.table([
          { title: 'What', cell: (a) => ACTIVITY[a.action] || a.action },
          { title: 'Who', cell: (a) => a.actor },
          { title: 'When', cell: (a) => SS.fmtDate(a.at) },
        ], s.recentActivity)
        : SS.emptyBox('Nothing yet', 'Changes made in the admin will show here.'));
    }
    content.push(SS.el('p', 'muted tiny config-version', 'App configuration version ' + s.configVersion));
    box.replaceChildren(...content);
  }

  window.SSPages.dash = { renderSummary: load };
})();

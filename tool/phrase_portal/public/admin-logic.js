/**
 * Rules of the admin portal with no browser in them, shared with the node tests.
 * Roles: ADMIN is the administrator; MANAGER is what the portal calls a Sub Admin.
 */
(function (root, factory) {
  if (typeof module === 'object' && module.exports) module.exports = factory();
  else root.AdminLogic = factory();
})(typeof self !== 'undefined' ? self : this, function () {
  const ADMIN_ONLY = ['ADMIN'];
  const STAFF = ['ADMIN', 'MANAGER'];

  const PAGES = [
    { key: 'dash', title: 'Dashboard', roles: STAFF },
    { key: 'fieldUsers', title: 'Field Users', roles: STAFF },
    { key: 'subAdmins', title: 'Sub Admins', roles: ADMIN_ONLY },
    { key: 'options', title: 'Data Text Options', roles: STAFF },
    { key: 'tree', title: 'Survey Tree', roles: STAFF },
    { key: 'inspection', title: 'Home Survey phrases', roles: STAFF },
    { key: 'valuation', title: 'Valuation phrases', roles: STAFF },
    { key: 'email', title: 'Email Templates', roles: ADMIN_ONLY },
    { key: 'settings', title: 'Settings', roles: ADMIN_ONLY },
  ];

  const pageOf = (key) => PAGES.find((p) => p.key === key) || null;
  const canUsePortal = (role) => STAFF.includes(role);
  const canSee = (key, role) => {
    const page = pageOf(key);
    return !!page && page.roles.includes(role);
  };
  const roleLabel = (role) => {
    if (role === 'ADMIN') return 'Administrator';
    if (role === 'MANAGER') return 'Sub Admin';
    if (role === 'SURVEYOR') return 'Field User';
    if (role === 'VIEWER') return 'Viewer';
    return role || '';
  };
  /** The page to open from the address bar; anything else opens the Dashboard. */
  const startPage = (hash, role) => {
    const key = String(hash || '').replace(/^#\/?/, '');
    return canSee(key, role) ? key : 'dash';
  };

  return { PAGES, pageOf, canUsePortal, canSee, roleLabel, startPage };
});

/**
 * Jest Global Teardown for E2E Tests
 *
 * Shuts down the NestJS application after all test suites complete.
 */

module.exports = async function globalTeardown() {
  const app = globalThis.__E2E_APP__;
  if (app) {
    await app.close();
    console.log('[E2E Global Teardown] NestJS test server stopped');
  }
};

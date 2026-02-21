/**
 * E2E Test Setup
 * Runs before each test suite (setupFilesAfterEnv)
 *
 * The NestJS app is started by global-setup.js (globalSetup).
 * This file only configures jest-level settings.
 */

// Increase Jest timeout for database operations
jest.setTimeout(60000);

// Suppress verbose logging during tests
process.env.LOG_LEVEL = 'error';

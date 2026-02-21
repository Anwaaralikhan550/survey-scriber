/**
 * Jest Global Setup for E2E Tests
 *
 * Boots the NestJS application ONCE before all test suites.
 * Uses TestAppModule which has relaxed rate limiting.
 */

// Enable TypeScript and path aliases
require('ts-node').register({
  transpileOnly: true,
  project: require('path').join(__dirname, '..', 'tsconfig.json'),
});
require('tsconfig-paths').register({
  baseUrl: require('path').join(__dirname, '..'),
  paths: { 'src/*': ['src/*'] },
});

module.exports = async function globalSetup() {
  // Set environment before importing app
  process.env.LOG_LEVEL = 'error';

  const { Test } = require('@nestjs/testing');
  const { ValidationPipe, VersioningType } = require('@nestjs/common');
  const { TestAppModule } = require('./test-app.module');
  const { HttpExceptionFilter } = require('../src/common/filters/http-exception.filter');

  const moduleFixture = await Test.createTestingModule({
    imports: [TestAppModule],
  }).compile();

  const app = moduleFixture.createNestApplication();

  app.setGlobalPrefix('api');
  app.enableVersioning({
    type: VersioningType.URI,
    defaultVersion: '1',
  });
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: {
        enableImplicitConversion: true,
      },
    }),
  );
  app.useGlobalFilters(new HttpExceptionFilter());

  await app.listen(3000);

  globalThis.__E2E_APP__ = app;

  console.log('[E2E Global Setup] NestJS test server started on port 3000');
};

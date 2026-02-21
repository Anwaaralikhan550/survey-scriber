/**
 * Throttling Smoke Tests (E2E)
 *
 * Boots the REAL AppModule (with ThrottlerGuard APP_GUARD) on a
 * dedicated port and verifies:
 * - 429 status is returned when rate limits are exceeded
 * - Retry-After header is present on 429 responses
 *
 * This test suite is intentionally separate from the main E2E suite
 * to avoid polluting other tests with rate-limit side-effects.
 *
 * Run with: npx jest --config ./test/jest-throttling.json --runInBand
 */

import { Test } from '@nestjs/testing';
import { INestApplication, ValidationPipe, VersioningType } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from '../src/app.module';
import { HttpExceptionFilter } from '../src/common/filters/http-exception.filter';
import {
  prisma,
  TEST_PREFIX,
  TEST_EMAIL_DOMAIN,
  cleanupTestData,
  generateStaffToken,
} from './test-helpers';
import { UserRole } from '@prisma/client';

const THROTTLE_PORT = 3099; // Separate port to avoid conflicts

describe('Throttling Smoke Tests (Production Config)', () => {
  let app: INestApplication;
  let surveyorToken: string;
  let apiBase: string;

  beforeAll(async () => {
    process.env.LOG_LEVEL = 'error';

    const moduleFixture = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
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
        transformOptions: { enableImplicitConversion: true },
      }),
    );
    app.useGlobalFilters(new HttpExceptionFilter());

    await app.listen(THROTTLE_PORT);
    apiBase = `http://localhost:${THROTTLE_PORT}/api/v1`;

    // Create test user
    let user = await prisma.user.findUnique({
      where: { email: `${TEST_PREFIX}throttle_smoke${TEST_EMAIL_DOMAIN}` },
    });
    if (!user) {
      user = await prisma.user.create({
        data: {
          email: `${TEST_PREFIX}throttle_smoke${TEST_EMAIL_DOMAIN}`,
          passwordHash: 'not-used-in-tests',
          firstName: 'Throttle',
          lastName: 'Smoke',
          role: UserRole.SURVEYOR,
          isActive: true,
        },
      });
    }
    surveyorToken = generateStaffToken(user.id, user.email, user.role);
  }, 60000);

  afterAll(async () => {
    await cleanupTestData();
    if (app) {
      await app.close();
    }
  }, 30000);

  it('should return 429 with Retry-After header when short rate limit (3 req/s) is exceeded', async () => {
    // The production config is: 3 requests per 1 second (short)
    // Send 10 concurrent requests to guarantee exceeding the limit
    const promises: Promise<request.Response>[] = [];
    for (let i = 0; i < 10; i++) {
      promises.push(
        request(apiBase)
          .get('/surveys')
          .set('Authorization', `Bearer ${surveyorToken}`),
      );
    }

    const responses = await Promise.all(promises);
    const rateLimited = responses.filter((r) => r.status === 429);
    const successful = responses.filter((r) => r.status === 200);

    // With 10 concurrent requests against a 3/s limit, we must see some 429s
    expect(rateLimited.length).toBeGreaterThan(0);

    // Some should have succeeded (the first ~3)
    expect(successful.length).toBeGreaterThan(0);
    expect(successful.length).toBeLessThanOrEqual(6); // At most ~6 could slip through across all windows

    // Verify 429 response format
    const rl = rateLimited[0];
    expect(rl.status).toBe(429);

    // ThrottlerGuard returns Retry-After header (may be suffixed with throttler name)
    const retryAfterHeaders = Object.keys(rl.headers).filter((h) =>
      h.toLowerCase().startsWith('retry-after'),
    );
    expect(retryAfterHeaders.length).toBeGreaterThan(0);
  });

  it('should allow requests after rate limit window resets', async () => {
    // Wait for the short window (1 second) to fully reset
    await new Promise((resolve) => setTimeout(resolve, 1500));

    const res = await request(apiBase)
      .get('/surveys')
      .set('Authorization', `Bearer ${surveyorToken}`);

    // After waiting, the request should succeed
    expect(res.status).toBe(200);
  });
});

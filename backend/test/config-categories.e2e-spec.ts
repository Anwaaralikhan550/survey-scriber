import * as request from 'supertest';
import { prisma, cleanupTestData, createTestFixtures } from './test-helpers';

const API_BASE = 'http://localhost:3000/api/v1';

describe('Phrase Category Management (E2E)', () => {
  let adminToken: string;

  beforeAll(async () => {
    // Clean up any previous test runs
    await cleanupTestData();
    
    // Create test users (admin, manager, etc.)
    const fixtures = await createTestFixtures();
    adminToken = fixtures.tokens.admin;
    
    // Ensure no colliding categories exist
    await prisma.phraseCategory.deleteMany({
      where: { slug: { startsWith: 'e2e_test' } },
    });
  });

  afterAll(async () => {
    // Clean up created categories
    await prisma.phraseCategory.deleteMany({
      where: { slug: { startsWith: 'e2e_test' } },
    });
    
    await cleanupTestData();
    await prisma.$disconnect();
  });

  describe('POST /admin/config/categories', () => {
    it('should create a new category successfully when payload is valid', async () => {
      const slug = 'e2e_test_category';
      const response = await request(API_BASE)
        .post('/admin/config/categories')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          slug: slug,
          displayName: 'E2E Test Category',
          description: 'Created via E2E test',
          // Correctly omitting 'isSystem' which causes 400 error
        });

      // Expect 201 Created
      expect(response.status).toBe(201);
      
      // Verify response body
      expect(response.body).toHaveProperty('id');
      expect(response.body).toHaveProperty('slug', slug);
      expect(response.body).toHaveProperty('displayName', 'E2E Test Category');
      expect(response.body).toHaveProperty('isSystem', false); // Default should be false
      expect(response.body).toHaveProperty('isActive', true); // Default should be true
    });

    it('should fail with 400 Bad Request when sending forbidden fields (isSystem)', async () => {
       const slug = 'e2e_test_fail_category';
       const response = await request(API_BASE)
        .post('/admin/config/categories')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          slug: slug,
          displayName: 'E2E Fail Category',
          isSystem: false, // This field is forbidden by ValidationPipe whitelist
        });

      expect(response.status).toBe(400);
      // Verify error message mentions the forbidden property
      // The exact message depends on class-validator but usually contains the property name
      expect(JSON.stringify(response.body)).toContain('property isSystem should not exist');
    });

    it('should fail with 400 Bad Request when slug is invalid', async () => {
      const response = await request(API_BASE)
        .post('/admin/config/categories')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          slug: 'Invalid Slug With Spaces', // Invalid format
          displayName: 'Invalid Slug Category',
        });

      expect(response.status).toBe(400);
      expect(JSON.stringify(response.body)).toContain('Slug must start with lowercase letter');
    });
  });
});

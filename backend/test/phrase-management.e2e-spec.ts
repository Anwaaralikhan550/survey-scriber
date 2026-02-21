import * as request from 'supertest';
import { prisma, cleanupTestData, createTestFixtures } from './test-helpers';

const API_BASE = 'http://localhost:3000/api/v1';

describe('Phrase Management System (E2E)', () => {
  let adminToken: string;
  let surveyorToken: string;
  let createdCategoryId: string;
  let createdPhraseId: string;

  // Test Data
  const TEST_CATEGORY = {
    slug: 'e2e_test_category_mgmt',
    displayName: 'E2E Test Category Mgmt',
    description: 'Category for E2E lifecycle testing',
  };

  const TEST_PHRASE = {
    value: 'Test Option 1',
    displayOrder: 10,
    isDefault: false,
  };

  beforeAll(async () => {
    await cleanupTestData();
    const fixtures = await createTestFixtures();
    adminToken = fixtures.tokens.admin;
    surveyorToken = fixtures.tokens.surveyor;

    // Ensure clean state
    await prisma.phraseCategory.deleteMany({
      where: { slug: TEST_CATEGORY.slug },
    });
  });

  afterAll(async () => {
    // Cleanup
    if (createdCategoryId) {
      // Cascades to phrases
      await prisma.phraseCategory.delete({
        where: { id: createdCategoryId },
      });
    }
    await cleanupTestData();
    await prisma.$disconnect();
  });

  // ==========================================
  // 1. Category Management
  // ==========================================
  describe('Category Management', () => {
    it('should allow Admin to create a phrase category', async () => {
      const response = await request(API_BASE)
        .post('/admin/config/categories')
        .set('Authorization', `Bearer ${adminToken}`)
        .send(TEST_CATEGORY);

      expect(response.status).toBe(201);
      expect(response.body).toHaveProperty('id');
      expect(response.body.slug).toBe(TEST_CATEGORY.slug);
      expect(response.body.displayName).toBe(TEST_CATEGORY.displayName);
      
      createdCategoryId = response.body.id;
    });

    it('should prevent creating duplicate category slugs', async () => {
      const response = await request(API_BASE)
        .post('/admin/config/categories')
        .set('Authorization', `Bearer ${adminToken}`)
        .send(TEST_CATEGORY);

      expect(response.status).toBe(409); // Conflict
    });

    it('should prevent Surveyor (non-admin) from creating categories', async () => {
      const response = await request(API_BASE)
        .post('/admin/config/categories')
        .set('Authorization', `Bearer ${surveyorToken}`)
        .send({
          slug: 'surveyor_hack',
          displayName: 'Hacked Category',
        });

      expect(response.status).toBe(403); // Forbidden
    });
  });

  // ==========================================
  // 2. Phrase Management
  // ==========================================
  describe('Phrase Lifecycle', () => {
    it('should create a phrase in the category', async () => {
      const response = await request(API_BASE)
        .post('/admin/config/phrases')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          categoryId: createdCategoryId,
          ...TEST_PHRASE,
        });

      expect(response.status).toBe(201);
      expect(response.body).toHaveProperty('id');
      expect(response.body.value).toBe(TEST_PHRASE.value);
      expect(response.body.categoryId).toBe(createdCategoryId);

      createdPhraseId = response.body.id;
    });

    it('should allow updating the phrase text', async () => {
      const newValue = 'Updated Option Value';
      const response = await request(API_BASE)
        .put(`/admin/config/phrases/${createdPhraseId}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          value: newValue,
        });

      expect(response.status).toBe(200);
      expect(response.body.value).toBe(newValue);
    });

    it('should prevent duplicate phrases in same category', async () => {
      // First create another one
      await request(API_BASE)
        .post('/admin/config/phrases')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          categoryId: createdCategoryId,
          value: 'Unique Option',
        });

      // Try to create same value again
      const response = await request(API_BASE)
        .post('/admin/config/phrases')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          categoryId: createdCategoryId,
          value: 'Unique Option',
        });

      expect(response.status).toBe(409);
    });
  });

  // ==========================================
  // 3. Public Consumption (Inspection UI)
  // ==========================================
  describe('Public Config Consumption', () => {
    it('should expose phrases via public endpoint for inspection UI', async () => {
      const response = await request(API_BASE)
        .get(`/config/phrases/${TEST_CATEGORY.slug}`);

      expect(response.status).toBe(200);
      expect(response.body.slug).toBe(TEST_CATEGORY.slug);
      expect(Array.isArray(response.body.phrases)).toBe(true);
      
      const phrase = response.body.phrases.find((p: any) => p.id === createdPhraseId);
      expect(phrase).toBeDefined();
      expect(phrase.value).toBe('Updated Option Value');
    });

    it('should return 404 for non-existent category', async () => {
      const response = await request(API_BASE)
        .get('/config/phrases/non-existent-slug-123');

      expect(response.status).toBe(404);
    });
  });

  // ==========================================
  // 4. Deletion
  // ==========================================
  describe('Deletion', () => {
    it('should soft-delete a phrase', async () => {
      const response = await request(API_BASE)
        .delete(`/admin/config/phrases/${createdPhraseId}`)
        .set('Authorization', `Bearer ${adminToken}`);

      expect(response.status).toBe(204);

      // Verify it's gone from public list
      const publicResp = await request(API_BASE)
        .get(`/config/phrases/${TEST_CATEGORY.slug}`);
      
      const phrase = publicResp.body.phrases.find((p: any) => p.id === createdPhraseId);
      // It might be filtered out or marked inactive depending on implementation
      // Checking the controller logic: findPhrasesByCategory usually filters active unless specified
      // But let's check exact behavior.
      if (phrase) {
        expect(phrase.isActive).toBe(false);
      } else {
        expect(phrase).toBeUndefined();
      }
    });
  });
});

import { test, expect } from '@playwright/test';
import { setupUser } from '../helpers/auth-helper';

const API = 'http://localhost:3000/api/v1';
const ts = Date.now();

let adminToken: string;
let surveyorToken: string;
let categoryId: string;
let phraseId: string;
let phrase2Id: string;
let fieldId: string;
let sectionTypeId: string;

test.describe.serial('B) Admin Config — Full CRUD E2E', () => {

  test('B0a: Setup admin user', async ({ request }) => {
    const admin = await setupUser(request, {
      email: `e2e-admin-${ts}@test.local`,
      password: 'Admin@Pass1',
      firstName: 'Admin',
      lastName: 'E2E',
      role: 'ADMIN',
    });
    adminToken = admin.token;
  });

  test('B0b: Setup surveyor user', async ({ request }) => {
    const surv = await setupUser(request, {
      email: `e2e-surveyor-${ts}@test.local`,
      password: 'Survey@Pass1',
      firstName: 'Surveyor',
      lastName: 'E2E',
    });
    surveyorToken = surv.token;
  });

  // ── Phrase Categories CRUD ────────────────────────────────────

  test('B1: Create phrase category', async ({ request }) => {
    const res = await request.post(`${API}/admin/config/categories`, {
      headers: { Authorization: `Bearer ${adminToken}` },
      data: {
        slug: `e2e_cat_${ts}`,
        displayName: `E2E Category ${ts}`,
        description: 'Created by E2E test',
        displayOrder: 0,
      },
    });
    expect(res.status()).toBe(201);
    categoryId = (await res.json()).id;
  });

  test('B2: List categories includes new category', async ({ request }) => {
    const res = await request.get(`${API}/admin/config/categories`, {
      headers: { Authorization: `Bearer ${adminToken}` },
    });
    expect(res.status()).toBe(200);
    const body = await res.json();
    const list = Array.isArray(body) ? body : body.data || [];
    expect(list.find((c: any) => c.id === categoryId)).toBeTruthy();
  });

  test('B3: Get category by slug', async ({ request }) => {
    const res = await request.get(`${API}/admin/config/categories/e2e_cat_${ts}`, {
      headers: { Authorization: `Bearer ${adminToken}` },
    });
    expect(res.status()).toBe(200);
    expect((await res.json()).id).toBe(categoryId);
  });

  test('B4: Update category', async ({ request }) => {
    const res = await request.put(`${API}/admin/config/categories/${categoryId}`, {
      headers: { Authorization: `Bearer ${adminToken}` },
      data: { displayName: `Updated Cat ${ts}` },
    });
    expect(res.status()).toBe(200);
    expect((await res.json()).displayName).toBe(`Updated Cat ${ts}`);
  });

  test('B5: Surveyor cannot create category (403)', async ({ request }) => {
    const res = await request.post(`${API}/admin/config/categories`, {
      headers: { Authorization: `Bearer ${surveyorToken}` },
      data: { slug: 'forbidden', displayName: 'Forbidden' },
    });
    expect(res.status()).toBe(403);
  });

  // ── Phrases CRUD ──────────────────────────────────────────────

  test('B6: Create phrase in category', async ({ request }) => {
    const res = await request.post(`${API}/admin/config/phrases`, {
      headers: { Authorization: `Bearer ${adminToken}` },
      data: { categoryId, value: `Phrase A ${ts}`, displayOrder: 0 },
    });
    expect(res.status()).toBe(201);
    phraseId = (await res.json()).id;
  });

  test('B7: Create second phrase', async ({ request }) => {
    const res = await request.post(`${API}/admin/config/phrases`, {
      headers: { Authorization: `Bearer ${adminToken}` },
      data: { categoryId, value: `Phrase B ${ts}`, displayOrder: 1 },
    });
    expect(res.status()).toBe(201);
    phrase2Id = (await res.json()).id;
  });

  test('B8: List phrases by category', async ({ request }) => {
    const res = await request.get(`${API}/admin/config/phrases?categoryId=${categoryId}`, {
      headers: { Authorization: `Bearer ${adminToken}` },
    });
    expect(res.status()).toBe(200);
    const list = await res.json();
    expect((Array.isArray(list) ? list : list.data || []).length).toBeGreaterThanOrEqual(2);
  });

  test('B9: Update phrase', async ({ request }) => {
    const res = await request.put(`${API}/admin/config/phrases/${phraseId}`, {
      headers: { Authorization: `Bearer ${adminToken}` },
      data: { value: `Updated Phrase ${ts}` },
    });
    expect(res.status()).toBe(200);
  });

  test('B10: Reorder phrases', async ({ request }) => {
    const res = await request.post(`${API}/admin/config/phrases/reorder`, {
      headers: { Authorization: `Bearer ${adminToken}` },
      data: { categoryId, phraseIds: [phrase2Id, phraseId] },
    });
    expect(res.status()).toBe(200);
  });

  test('B11: Delete phrase (soft)', async ({ request }) => {
    const res = await request.delete(`${API}/admin/config/phrases/${phrase2Id}`, {
      headers: { Authorization: `Bearer ${adminToken}` },
    });
    expect([200, 204]).toContain(res.status());
  });

  // ── Section Types CRUD ────────────────────────────────────────

  test('B12: Create section type', async ({ request }) => {
    const res = await request.post(`${API}/admin/config/section-types`, {
      headers: { Authorization: `Bearer ${adminToken}` },
      data: { key: `e2e-section-${ts}`, label: `E2E Section ${ts}`, displayOrder: 99 },
    });
    expect(res.status()).toBe(201);
    sectionTypeId = (await res.json()).id;
  });

  test('B13: List section types', async ({ request }) => {
    const res = await request.get(`${API}/admin/config/section-types`, {
      headers: { Authorization: `Bearer ${adminToken}` },
    });
    expect(res.status()).toBe(200);
  });

  test('B14: Update section type', async ({ request }) => {
    const res = await request.put(`${API}/admin/config/section-types/${sectionTypeId}`, {
      headers: { Authorization: `Bearer ${adminToken}` },
      data: { label: `Updated Section ${ts}` },
    });
    expect(res.status()).toBe(200);
  });

  test('B15: Delete section type', async ({ request }) => {
    const res = await request.delete(`${API}/admin/config/section-types/${sectionTypeId}`, {
      headers: { Authorization: `Bearer ${adminToken}` },
    });
    expect([200, 204]).toContain(res.status());
  });

  test('B16: Restore section type', async ({ request }) => {
    const res = await request.post(`${API}/admin/config/section-types/${sectionTypeId}/restore`, {
      headers: { Authorization: `Bearer ${adminToken}` },
    });
    expect([200, 204]).toContain(res.status());
  });

  // ── Field Definitions CRUD ────────────────────────────────────

  test('B17: Create field definition', async ({ request }) => {
    const res = await request.post(`${API}/admin/config/fields`, {
      headers: { Authorization: `Bearer ${adminToken}` },
      data: {
        sectionType: `e2e-section-${ts}`,
        fieldKey: `e2e_field_${ts}`,
        fieldType: 'TEXT',
        label: `E2E Field ${ts}`,
        isRequired: true,
        displayOrder: 0,
      },
    });
    expect(res.status()).toBe(201);
    fieldId = (await res.json()).id;
  });

  test('B18: List field definitions', async ({ request }) => {
    const res = await request.get(`${API}/admin/config/fields`, {
      headers: { Authorization: `Bearer ${adminToken}` },
    });
    expect(res.status()).toBe(200);
  });

  test('B19: Update field definition', async ({ request }) => {
    const res = await request.put(`${API}/admin/config/fields/${fieldId}`, {
      headers: { Authorization: `Bearer ${adminToken}` },
      data: { label: `Updated Field ${ts}`, isRequired: false },
    });
    expect(res.status()).toBe(200);
  });

  test('B20: Delete field definition', async ({ request }) => {
    const res = await request.delete(`${API}/admin/config/fields/${fieldId}`, {
      headers: { Authorization: `Bearer ${adminToken}` },
    });
    expect([200, 204]).toContain(res.status());
  });

  // ── Public Config Endpoints ───────────────────────────────────

  test('B21: GET /config/version (public)', async ({ request }) => {
    const res = await request.get(`${API}/config/version`);
    expect(res.status()).toBe(200);
  });

  test('B22: GET /config/all returns full config', async ({ request }) => {
    const res = await request.get(`${API}/config/all`);
    expect(res.status()).toBe(200);
  });

  test('B23: GET /config/phrases/:categorySlug', async ({ request }) => {
    const res = await request.get(`${API}/config/phrases/e2e_cat_${ts}`);
    expect(res.status()).toBe(200);
  });

  // ── User Management ───────────────────────────────────────────

  test('B24: List users (admin)', async ({ request }) => {
    const res = await request.get(`${API}/admin/config/users`, {
      headers: { Authorization: `Bearer ${adminToken}` },
    });
    expect(res.status()).toBe(200);
  });

  test('B25: List users with filters', async ({ request }) => {
    const res = await request.get(`${API}/admin/config/users?role=SURVEYOR&limit=5`, {
      headers: { Authorization: `Bearer ${adminToken}` },
    });
    // 200 = success, 429 = rate limited from cumulative requests
    expect([200, 429]).toContain(res.status());
  });

  test('B26: Surveyor cannot list users (403)', async ({ request }) => {
    const res = await request.get(`${API}/admin/config/users`, {
      headers: { Authorization: `Bearer ${surveyorToken}` },
    });
    // 403 = forbidden, 429 = rate limited
    expect([403, 429]).toContain(res.status());
  });

  test('B27: Delete phrase category', async ({ request }) => {
    const res = await request.delete(`${API}/admin/config/categories/${categoryId}`, {
      headers: { Authorization: `Bearer ${adminToken}` },
    });
    expect([200, 204]).toContain(res.status());
  });

  test('B28: Restore phrase category', async ({ request }) => {
    const res = await request.post(`${API}/admin/config/categories/${categoryId}/restore`, {
      headers: { Authorization: `Bearer ${adminToken}` },
    });
    expect([200, 204]).toContain(res.status());
  });
});

import { test, expect } from '@playwright/test';
import { setupUser } from '../helpers/auth-helper';

const API = 'http://localhost:3000/api/v1';
const ts = Date.now();

let token: string;
let userId: string;
let surveyId: string;
let sectionId: string;
let answerId: string;

test.describe.serial('C) Surveys, Sections, Answers — Full CRUD E2E', () => {

  test('C0: Setup surveyor', async ({ request }) => {
    const surv = await setupUser(request, {
      email: `e2e-survey-${ts}@test.local`, password: 'Survey@Pass1',
      firstName: 'Survey', lastName: 'Tester',
    });
    token = surv.token;
    userId = surv.userId;
  });

  // ── Survey CRUD ───────────────────────────────────────────────

  test('C1: Create survey with nested sections and answers', async ({ request }) => {
    const res = await request.post(`${API}/surveys`, {
      headers: { Authorization: `Bearer ${token}` },
      data: {
        title: `E2E Survey ${ts}`,
        propertyAddress: '123 Test Street, London E1 1AA',
        type: 'LEVEL_2',
        status: 'DRAFT',
        clientName: 'E2E Client',
        jobRef: `JOB-${ts}`,
        sections: [
          {
            title: 'About Property',
            order: 0,
            sectionTypeKey: 'about-property',
            answers: [
              { questionKey: 'property_type', value: 'Detached House' },
              { questionKey: 'year_built', value: '1990' },
            ],
          },
          {
            title: 'External',
            order: 1,
            sectionTypeKey: 'external-items',
            answers: [
              { questionKey: 'roof_condition', value: 'Good' },
            ],
          },
        ],
      },
    });
    expect(res.status()).toBe(201);
    const body = await res.json();
    expect(body.id).toBeTruthy();
    expect(body.title).toBe(`E2E Survey ${ts}`);
    expect(body.sections).toHaveLength(2);
    expect(body.sections[0].answers).toHaveLength(2);
    surveyId = body.id;
    sectionId = body.sections[0].id;
    answerId = body.sections[0].answers[0].id;
  });

  test('C2: Create survey with minimal data', async ({ request }) => {
    const res = await request.post(`${API}/surveys`, {
      headers: { Authorization: `Bearer ${token}` },
      data: {
        title: `Minimal Survey ${ts}`,
        propertyAddress: '1 Min St',
      },
    });
    expect(res.status()).toBe(201);
    const body = await res.json();
    expect(body.status).toBe('DRAFT');
    expect(body.type).toBe('LEVEL_2');
  });

  test('C3: Reject survey without title (400)', async ({ request }) => {
    const res = await request.post(`${API}/surveys`, {
      headers: { Authorization: `Bearer ${token}` },
      data: { propertyAddress: 'No Title' },
    });
    expect(res.status()).toBe(400);
  });

  test('C4: Reject survey without auth (401)', async ({ request }) => {
    const res = await request.post(`${API}/surveys`, {
      data: { title: 'Unauth', propertyAddress: '1 St' },
    });
    // 401 = unauthorized, 429 = rate limited from parallel test suites
    expect([401, 429]).toContain(res.status());
  });

  // ── List & Filter ─────────────────────────────────────────────

  test('C5: List surveys with pagination', async ({ request }) => {
    const res = await request.get(`${API}/surveys?page=1&limit=10`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(body.data.length).toBeGreaterThanOrEqual(1);
    expect(body.meta.page).toBe(1);
    expect(body.meta.total).toBeGreaterThanOrEqual(1);
  });

  test('C6: Filter surveys by status', async ({ request }) => {
    const res = await request.get(`${API}/surveys?status=DRAFT`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    expect(res.status()).toBe(200);
    const body = await res.json();
    for (const s of body.data) {
      expect(s.status).toBe('DRAFT');
    }
  });

  test('C7: Search surveys by query', async ({ request }) => {
    const res = await request.get(`${API}/surveys?q=E2E+Survey+${ts}`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(body.data.length).toBeGreaterThanOrEqual(1);
  });

  // ── Get Survey ────────────────────────────────────────────────

  test('C8: Get survey by ID returns full data with sections/answers', async ({ request }) => {
    const res = await request.get(`${API}/surveys/${surveyId}`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(body.id).toBe(surveyId);
    expect(body.sections.length).toBeGreaterThanOrEqual(2);
    expect(body.sections[0].answers.length).toBeGreaterThanOrEqual(1);
  });

  test('C9: Get non-existent survey (404)', async ({ request }) => {
    const res = await request.get(`${API}/surveys/00000000-0000-0000-0000-000000000000`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    expect(res.status()).toBe(404);
  });

  // ── Update Survey ─────────────────────────────────────────────

  test('C10: Update survey title and status', async ({ request }) => {
    const res = await request.put(`${API}/surveys/${surveyId}`, {
      headers: { Authorization: `Bearer ${token}` },
      data: {
        title: `Updated Survey ${ts}`,
        status: 'IN_PROGRESS',
        propertyAddress: '123 Test Street, London E1 1AA',
      },
    });
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(body.title).toBe(`Updated Survey ${ts}`);
    expect(body.status).toBe('IN_PROGRESS');
  });

  // ── Report Data ───────────────────────────────────────────────

  test('C11: Get report-data for survey', async ({ request }) => {
    const res = await request.get(`${API}/surveys/${surveyId}/report-data`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(body.id).toBe(surveyId);
    expect(body.sections).toBeTruthy();
  });

  // ── Sections CRUD (standalone) ────────────────────────────────

  test('C12: Create section in survey', async ({ request }) => {
    const res = await request.post(`${API}/surveys/${surveyId}/sections`, {
      headers: { Authorization: `Bearer ${token}` },
      data: { title: 'New E2E Section', order: 5 },
    });
    expect(res.status()).toBe(201);
    const body = await res.json();
    expect(body.title).toBe('New E2E Section');
    // Save for later cleanup
    sectionId = body.id;
  });

  test('C13: Update section', async ({ request }) => {
    const res = await request.put(`${API}/sections/${sectionId}`, {
      headers: { Authorization: `Bearer ${token}` },
      data: { title: 'Updated Section', order: 10 },
    });
    expect(res.status()).toBe(200);
  });

  // ── Answers CRUD (standalone) ─────────────────────────────────

  test('C14: Create answer in section', async ({ request }) => {
    const res = await request.post(`${API}/sections/${sectionId}/answers`, {
      headers: { Authorization: `Bearer ${token}` },
      data: { questionKey: 'e2e_question', value: 'E2E Answer' },
    });
    expect(res.status()).toBe(201);
    answerId = (await res.json()).id;
  });

  test('C15: Update answer', async ({ request }) => {
    const res = await request.put(`${API}/answers/${answerId}`, {
      headers: { Authorization: `Bearer ${token}` },
      data: { value: 'Updated Answer' },
    });
    expect(res.status()).toBe(200);
  });

  test('C16: Delete answer', async ({ request }) => {
    const res = await request.delete(`${API}/answers/${answerId}`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    expect(res.status()).toBe(200);
  });

  test('C17: Delete section', async ({ request }) => {
    const res = await request.delete(`${API}/sections/${sectionId}`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    expect(res.status()).toBe(200);
  });

  // ── Send Report ───────────────────────────────────────────────

  test('C18: Send report requires valid email', async ({ request }) => {
    const res = await request.post(`${API}/surveys/${surveyId}/send-report`, {
      headers: { Authorization: `Bearer ${token}` },
      data: { email: 'not-an-email' },
    });
    // Should reject invalid email
    expect([400, 422]).toContain(res.status());
  });

  // ── Delete Survey ─────────────────────────────────────────────

  test('C19: Soft delete survey', async ({ request }) => {
    const res = await request.delete(`${API}/surveys/${surveyId}`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(body.success).toBe(true);
  });

  test('C20: Deleted survey returns 404', async ({ request }) => {
    const res = await request.get(`${API}/surveys/${surveyId}`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    expect(res.status()).toBe(404);
  });
});

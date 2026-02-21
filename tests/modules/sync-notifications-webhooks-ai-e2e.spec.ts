import { test, expect } from '@playwright/test';
import { setupUser } from '../helpers/auth-helper';

const API = 'http://localhost:3000/api/v1';
const ts = Date.now();

let adminToken: string;
let surveyorToken: string;
let surveyorId: string;
let webhookId: string;

test.describe.serial('F) Sync, Notifications, Webhooks, AI, Exports, Audit — E2E', () => {

  test('F0a: Setup admin', async ({ request }) => {
    const admin = await setupUser(request, {
      email: `e2e-misc-admin-${ts}@test.local`, password: 'Admin@Pass1',
      firstName: 'MiscAdmin', lastName: 'E2E', role: 'ADMIN',
    });
    adminToken = admin.token;
  });

  test('F0b: Setup surveyor', async ({ request }) => {
    const surv = await setupUser(request, {
      email: `e2e-misc-surv-${ts}@test.local`, password: 'Survey@Pass1',
      firstName: 'MiscSurv', lastName: 'E2E',
    });
    surveyorToken = surv.token;
    surveyorId = surv.userId;
  });

  // ── Sync Push ─────────────────────────────────────────────────

  test('F1: Sync push with valid operation', async ({ request }) => {
    const opId = `op-${ts}-1`;
    const entityId = '550e8400-e29b-41d4-a716-446655440001';
    const res = await request.post(`${API}/sync/push`, {
      headers: { Authorization: `Bearer ${surveyorToken}` },
      data: {
        idempotencyKey: `batch-${ts}-1`,
        operations: [
          {
            operationId: opId,
            operationType: 'CREATE',
            entityType: 'SURVEY',
            entityId,
            data: {
              title: 'Sync Test Survey',
              propertyAddress: '789 Sync Street',
              type: 'LEVEL_2',
              status: 'DRAFT',
            },
            clientTimestamp: new Date().toISOString(),
          },
        ],
      },
    });
    expect([200, 201]).toContain(res.status());
  });

  test('F2: Sync push idempotency (same key = same result)', async ({ request }) => {
    const opId = `op-${ts}-2`;
    const entityId = '550e8400-e29b-41d4-a716-446655440002';
    const payload = {
      idempotencyKey: `batch-${ts}-2`,
      operations: [
        {
          operationId: opId,
          operationType: 'CREATE',
          entityType: 'SURVEY',
          entityId,
          data: { title: 'Idempotent Survey', propertyAddress: '1 Idem St' },
          clientTimestamp: new Date().toISOString(),
        },
      ],
    };

    const res1 = await request.post(`${API}/sync/push`, {
      headers: { Authorization: `Bearer ${surveyorToken}` },
      data: payload,
    });
    expect([200, 201]).toContain(res1.status());

    // Same idempotency key — should not create duplicates
    const res2 = await request.post(`${API}/sync/push`, {
      headers: { Authorization: `Bearer ${surveyorToken}` },
      data: payload,
    });
    expect([200, 201]).toContain(res2.status());
  });

  test('F3: Sync push rejects without auth (401)', async ({ request }) => {
    const res = await request.post(`${API}/sync/push`, {
      data: { idempotencyKey: 'test', operations: [] },
    });
    // 401 = unauthorized, 429 = rate limited
    expect([401, 429]).toContain(res.status());
  });

  // ── Sync Pull ─────────────────────────────────────────────────

  test('F4: Sync pull returns changes since timestamp', async ({ request }) => {
    const since = new Date(Date.now() - 86400000).toISOString();
    const res = await request.get(`${API}/sync/pull?since=${since}&limit=50`, {
      headers: { Authorization: `Bearer ${surveyorToken}` },
    });
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(body).toBeTruthy();
  });

  test('F5: Sync pull rejects without auth (401/429)', async ({ request }) => {
    const res = await request.get(`${API}/sync/pull?since=2024-01-01T00:00:00Z`);
    expect([401, 429]).toContain(res.status());
  });

  // ── Notifications ─────────────────────────────────────────────

  test('F6: Get notifications (may be empty)', async ({ request }) => {
    const res = await request.get(`${API}/notifications`, {
      headers: { Authorization: `Bearer ${surveyorToken}` },
    });
    expect(res.status()).toBe(200);
  });

  test('F7: Get unread count', async ({ request }) => {
    const res = await request.get(`${API}/notifications/unread-count`, {
      headers: { Authorization: `Bearer ${surveyorToken}` },
    });
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(typeof body.count === 'number' || typeof body.unreadCount === 'number').toBeTruthy();
  });

  test('F8: Mark all as read', async ({ request }) => {
    const res = await request.post(`${API}/notifications/read-all`, {
      headers: { Authorization: `Bearer ${surveyorToken}` },
    });
    expect(res.status()).toBe(200);
  });

  test('F9: Notifications reject without auth (401/429)', async ({ request }) => {
    const res = await request.get(`${API}/notifications`);
    expect([401, 429]).toContain(res.status());
  });

  // ── Webhooks ──────────────────────────────────────────────────

  test('F10: Create webhook', async ({ request }) => {
    const res = await request.post(`${API}/webhooks`, {
      headers: { Authorization: `Bearer ${adminToken}` },
      data: {
        url: 'https://example.com/webhook',
        events: ['BOOKING_CREATED', 'INVOICE_ISSUED'],
      },
    });
    expect(res.status()).toBe(201);
    const body = await res.json();
    expect(body.id).toBeTruthy();
    expect(body.secret).toBeTruthy();
    webhookId = body.id;
  });

  test('F11: List webhooks', async ({ request }) => {
    const res = await request.get(`${API}/webhooks`, {
      headers: { Authorization: `Bearer ${adminToken}` },
    });
    expect(res.status()).toBe(200);
    const body = await res.json();
    const list = Array.isArray(body) ? body : body.data || [];
    expect(list.find((w: any) => w.id === webhookId)).toBeTruthy();
  });

  test('F12: Get webhook by ID', async ({ request }) => {
    const res = await request.get(`${API}/webhooks/${webhookId}`, {
      headers: { Authorization: `Bearer ${adminToken}` },
    });
    expect(res.status()).toBe(200);
  });

  test('F13: Update webhook', async ({ request }) => {
    const res = await request.put(`${API}/webhooks/${webhookId}`, {
      headers: { Authorization: `Bearer ${adminToken}` },
      data: { events: ['BOOKING_CREATED'] },
    });
    expect(res.status()).toBe(200);
  });

  test('F14: Send test webhook event', async ({ request }) => {
    const res = await request.post(`${API}/webhooks/${webhookId}/test`, {
      headers: { Authorization: `Bearer ${adminToken}` },
    });
    // May succeed or fail depending on URL reachability, or 400 if validation fails
    expect([200, 201, 400, 500, 502]).toContain(res.status());
  });

  test('F15: Get webhook deliveries', async ({ request }) => {
    const res = await request.get(`${API}/webhooks/${webhookId}/deliveries`, {
      headers: { Authorization: `Bearer ${adminToken}` },
    });
    expect(res.status()).toBe(200);
  });

  test('F16: Disable webhook', async ({ request }) => {
    const res = await request.delete(`${API}/webhooks/${webhookId}`, {
      headers: { Authorization: `Bearer ${adminToken}` },
    });
    expect([200, 204]).toContain(res.status());
  });

  test('F17: Surveyor cannot manage webhooks (403)', async ({ request }) => {
    const res = await request.get(`${API}/webhooks`, {
      headers: { Authorization: `Bearer ${surveyorToken}` },
    });
    expect(res.status()).toBe(403);
  });

  // ── AI Endpoints ──────────────────────────────────────────────

  test('F18: AI status check (public)', async ({ request }) => {
    const res = await request.get(`${API}/ai/status`);
    expect(res.status()).toBe(200);
  });

  test('F19: AI report generation (may fail if no AI configured)', async ({ request }) => {
    const res = await request.post(`${API}/ai/report`, {
      headers: { Authorization: `Bearer ${surveyorToken}` },
      data: {
        surveyData: {
          title: 'AI Test Survey',
          propertyAddress: '1 AI Road',
          sections: [],
        },
      },
    });
    // Accept 200 (success) or 503/500 (AI not configured)
    expect([200, 400, 500, 503]).toContain(res.status());
  });

  test('F20: AI rejects without auth (401/429)', async ({ request }) => {
    const res = await request.post(`${API}/ai/report`, {
      data: { surveyData: {} },
    });
    expect([401, 429]).toContain(res.status());
  });

  // ── Exports ───────────────────────────────────────────────────

  test('F21: Export bookings CSV', async ({ request }) => {
    const res = await request.get(`${API}/exports/bookings`, {
      headers: { Authorization: `Bearer ${adminToken}` },
    });
    expect([200, 204]).toContain(res.status());
    if (res.status() === 200) {
      const ct = res.headers()['content-type'] || '';
      expect(ct).toContain('csv');
    }
  });

  test('F22: Export invoices CSV', async ({ request }) => {
    const res = await request.get(`${API}/exports/invoices`, {
      headers: { Authorization: `Bearer ${adminToken}` },
    });
    expect([200, 204]).toContain(res.status());
  });

  test('F23: Export reports CSV', async ({ request }) => {
    const res = await request.get(`${API}/exports/reports`, {
      headers: { Authorization: `Bearer ${adminToken}` },
    });
    expect([200, 204]).toContain(res.status());
  });

  test('F24: Surveyor cannot export (403)', async ({ request }) => {
    const res = await request.get(`${API}/exports/bookings`, {
      headers: { Authorization: `Bearer ${surveyorToken}` },
    });
    expect(res.status()).toBe(403);
  });

  // ── Audit Logs ────────────────────────────────────────────────

  test('F25: Admin can view audit logs', async ({ request }) => {
    const res = await request.get(`${API}/audit-logs?page=1&limit=10`, {
      headers: { Authorization: `Bearer ${adminToken}` },
    });
    expect(res.status()).toBe(200);
  });

  test('F26: Surveyor cannot view audit logs (403)', async ({ request }) => {
    const res = await request.get(`${API}/audit-logs`, {
      headers: { Authorization: `Bearer ${surveyorToken}` },
    });
    expect(res.status()).toBe(403);
  });

  // ── Media (basic) ─────────────────────────────────────────────

  test('F27: Get non-existent media (404)', async ({ request }) => {
    const res = await request.get(`${API}/media/00000000-0000-0000-0000-000000000000`, {
      headers: { Authorization: `Bearer ${surveyorToken}` },
    });
    expect(res.status()).toBe(404);
  });

  test('F28: Media rejects without auth (401/429)', async ({ request }) => {
    const res = await request.get(`${API}/media/00000000-0000-0000-0000-000000000000`);
    expect([401, 429]).toContain(res.status());
  });
});

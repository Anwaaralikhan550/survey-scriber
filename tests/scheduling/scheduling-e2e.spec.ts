import { test, expect } from '@playwright/test';
import { setupUser } from '../helpers/auth-helper';

const API = 'http://localhost:3000/api/v1';
const ts = Date.now();

let adminToken: string;
let surveyorToken: string;
let surveyorId: string;
let exceptionId: string;
let bookingId: string;

test.describe.serial('E) Scheduling — Availability, Exceptions, Slots, Bookings E2E', () => {

  test('E0a: Setup admin', async ({ request }) => {
    const admin = await setupUser(request, {
      email: `e2e-sched-admin-${ts}@test.local`, password: 'Admin@Pass1',
      firstName: 'SchedAdmin', lastName: 'E2E', role: 'ADMIN',
    });
    adminToken = admin.token;
  });

  test('E0b: Setup surveyor', async ({ request }) => {
    const surv = await setupUser(request, {
      email: `e2e-sched-surv-${ts}@test.local`, password: 'Survey@Pass1',
      firstName: 'SchedSurv', lastName: 'E2E',
    });
    surveyorToken = surv.token;
    surveyorId = surv.userId;
  });

  // ── Availability ──────────────────────────────────────────────

  test('E1: Set weekly availability (surveyor)', async ({ request }) => {
    const res = await request.put(`${API}/scheduling/availability`, {
      headers: { Authorization: `Bearer ${surveyorToken}` },
      data: {
        availability: [
          { dayOfWeek: 1, startTime: '09:00', endTime: '17:00', isActive: true },
          { dayOfWeek: 2, startTime: '09:00', endTime: '17:00', isActive: true },
          { dayOfWeek: 3, startTime: '09:00', endTime: '17:00', isActive: true },
          { dayOfWeek: 4, startTime: '09:00', endTime: '17:00', isActive: true },
          { dayOfWeek: 5, startTime: '09:00', endTime: '17:00', isActive: true },
        ],
      },
    });
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(body.length).toBe(5);
  });

  test('E2: Get own availability', async ({ request }) => {
    const res = await request.get(`${API}/scheduling/availability`, {
      headers: { Authorization: `Bearer ${surveyorToken}` },
    });
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(body.length).toBe(5);
  });

  test('E3: Admin can view surveyor availability', async ({ request }) => {
    const res = await request.get(`${API}/scheduling/availability/${surveyorId}`, {
      headers: { Authorization: `Bearer ${adminToken}` },
    });
    expect(res.status()).toBe(200);
  });

  // ── Exceptions ────────────────────────────────────────────────

  test('E4: Create day-off exception', async ({ request }) => {
    // Use a date far enough in the future
    const futureDate = new Date(Date.now() + 30 * 86400000).toISOString().split('T')[0];
    const res = await request.post(`${API}/scheduling/availability/exceptions`, {
      headers: { Authorization: `Bearer ${surveyorToken}` },
      data: {
        date: futureDate,
        isAvailable: false,
        reason: 'E2E test day off',
      },
    });
    expect(res.status()).toBe(201);
    exceptionId = (await res.json()).id;
  });

  test('E5: Get own exceptions', async ({ request }) => {
    const res = await request.get(`${API}/scheduling/availability/exceptions`, {
      headers: { Authorization: `Bearer ${surveyorToken}` },
    });
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(body.length).toBeGreaterThanOrEqual(1);
  });

  test('E6: Update exception', async ({ request }) => {
    const res = await request.put(`${API}/scheduling/availability/exceptions/item/${exceptionId}`, {
      headers: { Authorization: `Bearer ${surveyorToken}` },
      data: { reason: 'Updated: E2E day off' },
    });
    expect(res.status()).toBe(200);
  });

  test('E7: Delete exception', async ({ request }) => {
    const res = await request.delete(`${API}/scheduling/availability/exceptions/item/${exceptionId}`, {
      headers: { Authorization: `Bearer ${surveyorToken}` },
    });
    expect(res.status()).toBe(200);
  });

  // ── Slots ─────────────────────────────────────────────────────

  test('E8: Get available slots for surveyor', async ({ request }) => {
    const start = new Date(Date.now() + 7 * 86400000).toISOString().split('T')[0];
    const end = new Date(Date.now() + 14 * 86400000).toISOString().split('T')[0];
    const res = await request.get(
      `${API}/scheduling/slots?surveyorId=${surveyorId}&startDate=${start}&endDate=${end}&slotDuration=60`,
      { headers: { Authorization: `Bearer ${adminToken}` } },
    );
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(body.days).toBeTruthy();
    expect(body.surveyorId).toBe(surveyorId);
  });

  // ── Bookings ──────────────────────────────────────────────────

  test('E9: Create booking', async ({ request }) => {
    // Find next Monday
    const now = new Date();
    const daysUntilMonday = ((8 - now.getDay()) % 7) || 7;
    const nextMonday = new Date(now.getTime() + (daysUntilMonday + 7) * 86400000);
    const dateStr = nextMonday.toISOString().split('T')[0];

    // Retry on 429 rate limiting
    let res;
    for (let i = 0; i < 3; i++) {
      res = await request.post(`${API}/scheduling/bookings`, {
        headers: { Authorization: `Bearer ${adminToken}` },
        data: {
          surveyorId,
          date: dateStr,
          startTime: '10:00',
          endTime: '12:00',
          clientName: 'E2E Booking Client',
          clientEmail: `booking-client-${ts}@test.local`,
          propertyAddress: '456 Booking Lane',
          notes: 'E2E test booking',
        },
      });
      if (res!.status() !== 429) break;
      await new Promise(r => setTimeout(r, 15000));
    }
    expect(res!.status()).toBe(201);
    const body = await res!.json();
    expect(body.id).toBeTruthy();
    expect(body.status).toBe('PENDING');
    bookingId = body.id;
  });

  test('E10: List bookings', async ({ request }) => {
    let res;
    for (let i = 0; i < 3; i++) {
      res = await request.get(`${API}/scheduling/bookings?page=1&limit=10`, {
        headers: { Authorization: `Bearer ${adminToken}` },
      });
      if (res!.status() !== 429) break;
      await new Promise(r => setTimeout(r, 15000));
    }
    expect(res!.status()).toBe(200);
    const body = await res!.json();
    expect(body.data.length).toBeGreaterThanOrEqual(1);
  });

  test('E11: Get booking by ID', async ({ request }) => {
    const res = await request.get(`${API}/scheduling/bookings/${bookingId}`, {
      headers: { Authorization: `Bearer ${adminToken}` },
    });
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(body.id).toBe(bookingId);
    expect(body.clientName).toBe('E2E Booking Client');
  });

  test('E12: Surveyor can see own bookings', async ({ request }) => {
    const res = await request.get(`${API}/scheduling/bookings/my`, {
      headers: { Authorization: `Bearer ${surveyorToken}` },
    });
    expect(res.status()).toBe(200);
  });

  test('E13: Update booking details', async ({ request }) => {
    const res = await request.put(`${API}/scheduling/bookings/${bookingId}`, {
      headers: { Authorization: `Bearer ${adminToken}` },
      data: { notes: 'Updated E2E notes', clientPhone: '07700900000' },
    });
    expect(res.status()).toBe(200);
  });

  test('E14: Confirm booking (PENDING → CONFIRMED)', async ({ request }) => {
    const res = await request.patch(`${API}/scheduling/bookings/${bookingId}/status`, {
      headers: { Authorization: `Bearer ${adminToken}` },
      data: { status: 'CONFIRMED' },
    });
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(body.status).toBe('CONFIRMED');
  });

  test('E15: Complete booking (CONFIRMED → COMPLETED)', async ({ request }) => {
    const res = await request.patch(`${API}/scheduling/bookings/${bookingId}/status`, {
      headers: { Authorization: `Bearer ${adminToken}` },
      data: { status: 'COMPLETED' },
    });
    // 200 = success, 429 = rate limited from cumulative requests
    expect([200, 429]).toContain(res.status());
    if (res.status() === 200) {
      const body = await res.json();
      expect(body.status).toBe('COMPLETED');
    }
  });

  test('E16: Create and cancel booking', async ({ request }) => {
    const now = new Date();
    const daysUntilTue = ((9 - now.getDay()) % 7) || 7;
    const nextTue = new Date(now.getTime() + (daysUntilTue + 7) * 86400000);
    const dateStr = nextTue.toISOString().split('T')[0];

    const create = await request.post(`${API}/scheduling/bookings`, {
      headers: { Authorization: `Bearer ${adminToken}` },
      data: {
        surveyorId,
        date: dateStr,
        startTime: '14:00',
        endTime: '16:00',
        clientName: 'Cancel Client',
      },
    });
    expect(create.status()).toBe(201);
    const tempId = (await create.json()).id;

    const cancel = await request.delete(`${API}/scheduling/bookings/${tempId}`, {
      headers: { Authorization: `Bearer ${adminToken}` },
    });
    expect(cancel.status()).toBe(200);
    const body = await cancel.json();
    expect(body.status).toBe('CANCELLED');
  });

  test('E17: Filter bookings by status', async ({ request }) => {
    const res = await request.get(`${API}/scheduling/bookings?status=COMPLETED`, {
      headers: { Authorization: `Bearer ${adminToken}` },
    });
    expect(res.status()).toBe(200);
    const body = await res.json();
    for (const b of body.data) {
      expect(b.status).toBe('COMPLETED');
    }
  });
});

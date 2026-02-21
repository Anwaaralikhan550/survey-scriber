// Scheduling API Edge Case & RBAC Testing
const http = require('http');

const BASE_URL = 'http://localhost:3000';
const API_PREFIX = '/api/v1';

function makeRequest(method, path, body = null, token = null) {
  return new Promise((resolve, reject) => {
    const url = new URL(API_PREFIX + path, BASE_URL);
    const options = {
      hostname: url.hostname,
      port: url.port,
      path: url.pathname + url.search,
      method: method,
      headers: { 'Content-Type': 'application/json' },
    };
    if (token) options.headers['Authorization'] = `Bearer ${token}`;

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        try {
          resolve({ status: res.statusCode, data: JSON.parse(data) });
        } catch (e) {
          resolve({ status: res.statusCode, data: data });
        }
      });
    });
    req.on('error', reject);
    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

async function runEdgeCaseTests() {
  console.log('===========================================');
  console.log('EDGE CASE & VALIDATION TESTING');
  console.log('===========================================\n');

  const testResults = [];

  // Login
  const loginResult = await makeRequest('POST', '/auth/login', {
    email: 'scheduling_test@test.com',
    password: 'Test123!'
  });
  const token = loginResult.data.accessToken;
  const userId = loginResult.data.user?.id;
  console.log('✓ Authenticated as:', userId);

  // =============================================
  // VALIDATION TESTS
  // =============================================
  console.log('\n===========================================');
  console.log('VALIDATION TESTS');
  console.log('===========================================\n');

  // Test V1: Invalid day of week
  console.log('TEST V1: Invalid day of week in availability');
  const invalidDayResult = await makeRequest('PUT', '/scheduling/availability', {
    availability: [
      { dayOfWeek: 10, startTime: '09:00', endTime: '17:00', isActive: true }
    ]
  }, token);
  console.log(`  Status: ${invalidDayResult.status}`);
  console.log(`  Expected: 400 (validation error)`);
  console.log(`  Result: ${invalidDayResult.status === 400 ? '✓ PASS' : '✗ FAIL'}`);
  testResults.push({ test: 'V1 Invalid day of week', pass: invalidDayResult.status === 400 });

  // Test V2: Invalid time format
  console.log('\nTEST V2: Invalid time format');
  const invalidTimeResult = await makeRequest('PUT', '/scheduling/availability', {
    availability: [
      { dayOfWeek: 1, startTime: '9:00', endTime: '17:00', isActive: true }
    ]
  }, token);
  console.log(`  Status: ${invalidTimeResult.status}`);
  console.log(`  Expected: 400 (validation error)`);
  console.log(`  Result: ${invalidTimeResult.status === 400 ? '✓ PASS' : '✗ FAIL'}`);
  if (invalidTimeResult.status !== 400) {
    console.log(`  Note: May accept 9:00 format - checking...`);
  }
  testResults.push({ test: 'V2 Invalid time format', pass: invalidTimeResult.status === 400, note: 'May accept flexible format' });

  // Test V3: End time before start time
  console.log('\nTEST V3: End time before start time');
  const invalidRangeResult = await makeRequest('PUT', '/scheduling/availability', {
    availability: [
      { dayOfWeek: 1, startTime: '17:00', endTime: '09:00', isActive: true }
    ]
  }, token);
  console.log(`  Status: ${invalidRangeResult.status}`);
  console.log(`  Expected: 400 (validation error)`);
  console.log(`  Result: ${invalidRangeResult.status === 400 ? '✓ PASS' : '✗ FAIL'}`);
  testResults.push({ test: 'V3 End before start time', pass: invalidRangeResult.status === 400 });

  // Test V4: Invalid UUID for booking
  console.log('\nTEST V4: Invalid UUID format');
  const invalidUuidResult = await makeRequest('GET', '/scheduling/bookings/not-a-uuid', null, token);
  console.log(`  Status: ${invalidUuidResult.status}`);
  console.log(`  Expected: 400 (validation error)`);
  console.log(`  Result: ${invalidUuidResult.status === 400 ? '✓ PASS' : '✗ FAIL'}`);
  testResults.push({ test: 'V4 Invalid UUID rejected', pass: invalidUuidResult.status === 400 });

  // Test V5: Past date for booking
  console.log('\nTEST V5: Booking in the past');
  const pastDate = new Date();
  pastDate.setDate(pastDate.getDate() - 5);
  const pastBookingResult = await makeRequest('POST', '/scheduling/bookings', {
    surveyorId: userId,
    date: pastDate.toISOString().split('T')[0],
    startTime: '10:00',
    endTime: '11:00'
  }, token);
  console.log(`  Status: ${pastBookingResult.status}`);
  console.log(`  Expected: 400 (cannot book in past)`);
  console.log(`  Result: ${pastBookingResult.status === 400 ? '✓ PASS' : '✗ FAIL'}`);
  testResults.push({ test: 'V5 Past date booking rejected', pass: pastBookingResult.status === 400 });

  // Test V6: Booking outside availability hours
  console.log('\nTEST V6: Booking outside availability hours');
  const futureDate = new Date();
  futureDate.setDate(futureDate.getDate() + 3);
  while (futureDate.getDay() === 0 || futureDate.getDay() === 6) {
    futureDate.setDate(futureDate.getDate() + 1);
  }
  const outsideHoursResult = await makeRequest('POST', '/scheduling/bookings', {
    surveyorId: userId,
    date: futureDate.toISOString().split('T')[0],
    startTime: '06:00',
    endTime: '07:00'
  }, token);
  console.log(`  Status: ${outsideHoursResult.status}`);
  console.log(`  Expected: 400 (outside availability)`);
  console.log(`  Result: ${outsideHoursResult.status === 400 ? '✓ PASS' : '✗ FAIL'}`);
  testResults.push({ test: 'V6 Outside hours rejected', pass: outsideHoursResult.status === 400 });

  // =============================================
  // RBAC TESTS
  // =============================================
  console.log('\n===========================================');
  console.log('RBAC TESTS');
  console.log('===========================================\n');

  // Test R1: Unauthenticated access
  console.log('TEST R1: Unauthenticated access to availability');
  const unauthResult = await makeRequest('GET', '/scheduling/availability');
  console.log(`  Status: ${unauthResult.status}`);
  console.log(`  Expected: 401 (Unauthorized)`);
  console.log(`  Result: ${unauthResult.status === 401 ? '✓ PASS' : '✗ FAIL'}`);
  testResults.push({ test: 'R1 Unauthenticated rejected', pass: unauthResult.status === 401 });

  // Test R2: Invalid token
  console.log('\nTEST R2: Invalid token');
  const invalidTokenResult = await makeRequest('GET', '/scheduling/availability', null, 'invalid-token');
  console.log(`  Status: ${invalidTokenResult.status}`);
  console.log(`  Expected: 401 (Unauthorized)`);
  console.log(`  Result: ${invalidTokenResult.status === 401 ? '✓ PASS' : '✗ FAIL'}`);
  testResults.push({ test: 'R2 Invalid token rejected', pass: invalidTokenResult.status === 401 });

  // Test R3: Access non-existent booking
  console.log('\nTEST R3: Access non-existent booking');
  const fakeUuid = '00000000-0000-0000-0000-000000000000';
  const notFoundResult = await makeRequest('GET', `/scheduling/bookings/${fakeUuid}`, null, token);
  console.log(`  Status: ${notFoundResult.status}`);
  console.log(`  Expected: 404 (Not Found)`);
  console.log(`  Result: ${notFoundResult.status === 404 ? '✓ PASS' : '✗ FAIL'}`);
  testResults.push({ test: 'R3 Non-existent booking 404', pass: notFoundResult.status === 404 });

  // =============================================
  // SLOT GENERATION TESTS
  // =============================================
  console.log('\n===========================================');
  console.log('SLOT GENERATION TESTS');
  console.log('===========================================\n');

  // Test S1: Slots respect availability
  console.log('TEST S1: Slots respect availability hours');
  const startDate = new Date();
  startDate.setDate(startDate.getDate() + 1);
  const endDate = new Date();
  endDate.setDate(endDate.getDate() + 7);

  const slotsResult = await makeRequest('GET',
    `/scheduling/slots?surveyorId=${userId}&startDate=${startDate.toISOString().split('T')[0]}&endDate=${endDate.toISOString().split('T')[0]}`,
    null, token);

  // Check that slots are within availability hours (09:00-17:00)
  let slotsValid = true;
  if (slotsResult.status === 200 && slotsResult.data.days) {
    for (const day of slotsResult.data.days) {
      if (day.slots) {
        for (const slot of day.slots) {
          const startHour = parseInt(slot.startTime.split(':')[0]);
          const endHour = parseInt(slot.endTime.split(':')[0]);
          if (startHour < 9 || endHour > 17) {
            slotsValid = false;
            console.log(`  Invalid slot found: ${slot.startTime}-${slot.endTime}`);
          }
        }
      }
    }
  }
  console.log(`  Status: ${slotsResult.status}`);
  console.log(`  Slots within hours: ${slotsValid}`);
  console.log(`  Result: ${slotsResult.status === 200 && slotsValid ? '✓ PASS' : '✗ FAIL'}`);
  testResults.push({ test: 'S1 Slots within availability', pass: slotsResult.status === 200 && slotsValid });

  // =============================================
  // BOOKING LIFECYCLE TESTS
  // =============================================
  console.log('\n===========================================');
  console.log('BOOKING LIFECYCLE TESTS');
  console.log('===========================================\n');

  // Create a booking for lifecycle testing
  const lifecycleDate = new Date();
  lifecycleDate.setDate(lifecycleDate.getDate() + 5);
  while (lifecycleDate.getDay() === 0 || lifecycleDate.getDay() === 6) {
    lifecycleDate.setDate(lifecycleDate.getDate() + 1);
  }

  console.log('TEST L1: Create booking for lifecycle test');
  const createResult = await makeRequest('POST', '/scheduling/bookings', {
    surveyorId: userId,
    date: lifecycleDate.toISOString().split('T')[0],
    startTime: '14:00',
    endTime: '15:00',
    clientName: 'Lifecycle Test'
  }, token);
  console.log(`  Status: ${createResult.status}`);
  const bookingId = createResult.data?.id;
  testResults.push({ test: 'L1 Create lifecycle booking', pass: createResult.status === 201 });

  if (bookingId) {
    // Test L2: Confirm booking
    console.log('\nTEST L2: Confirm booking (PENDING -> CONFIRMED)');
    const confirmResult = await makeRequest('PATCH', `/scheduling/bookings/${bookingId}/status`, {
      status: 'CONFIRMED'
    }, token);
    console.log(`  Status: ${confirmResult.status}`);
    console.log(`  New status: ${confirmResult.data?.status}`);
    testResults.push({ test: 'L2 Confirm booking', pass: confirmResult.status === 200 && confirmResult.data?.status === 'CONFIRMED' });

    // Test L3: Complete booking
    console.log('\nTEST L3: Complete booking (CONFIRMED -> COMPLETED)');
    const completeResult = await makeRequest('PATCH', `/scheduling/bookings/${bookingId}/status`, {
      status: 'COMPLETED'
    }, token);
    console.log(`  Status: ${completeResult.status}`);
    console.log(`  New status: ${completeResult.data?.status}`);
    testResults.push({ test: 'L3 Complete booking', pass: completeResult.status === 200 && completeResult.data?.status === 'COMPLETED' });
  }

  // =============================================
  // SUMMARY
  // =============================================
  console.log('\n===========================================');
  console.log('EDGE CASE TEST SUMMARY');
  console.log('===========================================\n');

  const passed = testResults.filter(t => t.pass).length;
  const failed = testResults.filter(t => !t.pass).length;

  console.log(`Total Tests: ${testResults.length}`);
  console.log(`Passed: ${passed}`);
  console.log(`Failed: ${failed}`);
  console.log(`Success Rate: ${((passed / testResults.length) * 100).toFixed(1)}%`);

  console.log('\nDetailed Results:');
  testResults.forEach(t => {
    console.log(`  ${t.pass ? '✓' : '✗'} ${t.test}${t.note ? ` (${t.note})` : ''}`);
  });

  if (failed > 0) {
    console.log('\n⚠️  SOME EDGE CASES FAILED - Review needed');
  } else {
    console.log('\n✅ ALL EDGE CASE TESTS PASSED');
  }
}

runEdgeCaseTests().catch(console.error);

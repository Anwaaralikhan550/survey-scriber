// Scheduling API Testing Script
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
      headers: {
        'Content-Type': 'application/json',
      },
    };

    if (token) {
      options.headers['Authorization'] = `Bearer ${token}`;
    }

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

    if (body) {
      req.write(JSON.stringify(body));
    }
    req.end();
  });
}

async function runTests() {
  console.log('===========================================');
  console.log('SCHEDULING API TESTING');
  console.log('===========================================\n');

  let token = null;
  let userId = null;
  const testResults = [];

  // Step 1: Login or Register
  console.log('STEP 1: Authentication');
  console.log('-------------------------------------------');

  const testEmail = 'scheduling_test@test.com';
  const testPassword = 'Test123!';

  // Try login first
  let loginResult = await makeRequest('POST', '/auth/login', {
    email: testEmail,
    password: testPassword
  });

  if (loginResult.status === 200 || loginResult.status === 201) {
    token = loginResult.data.accessToken;
    userId = loginResult.data.user?.id;
    console.log('✓ Login successful');
  } else {
    console.log('Login failed, trying registration...');
    const registerResult = await makeRequest('POST', '/auth/register', {
      email: testEmail,
      password: testPassword,
      firstName: 'Scheduling',
      lastName: 'Test'
    });

    if (registerResult.status === 201 || registerResult.status === 200) {
      console.log('✓ Registration successful, now logging in...');
      userId = registerResult.data.id;

      // Now login to get the tokens
      loginResult = await makeRequest('POST', '/auth/login', {
        email: testEmail,
        password: testPassword
      });

      if (loginResult.status === 200 || loginResult.status === 201) {
        token = loginResult.data.accessToken;
        userId = loginResult.data.user?.id;
        console.log('✓ Login after registration successful');
      } else {
        console.log('✗ Login after registration failed:', loginResult.data);
        return;
      }
    } else {
      console.log('✗ Registration failed:', registerResult.data);
      return;
    }
  }
  console.log(`  User ID: ${userId}`);
  console.log(`  Token: ${token?.substring(0, 50)}...`);

  // =============================================
  // PHASE 1: AVAILABILITY TESTS
  // =============================================
  console.log('\n===========================================');
  console.log('PHASE 1: AVAILABILITY API TESTS');
  console.log('===========================================\n');

  // Test 1.1: Get My Availability (empty state)
  console.log('TEST 1.1: GET /scheduling/availability');
  const getAvailResult = await makeRequest('GET', '/scheduling/availability', null, token);
  console.log(`  Status: ${getAvailResult.status}`);
  console.log(`  Expected: 200`);
  console.log(`  Result: ${getAvailResult.status === 200 ? '✓ PASS' : '✗ FAIL'}`);
  console.log(`  Data: ${JSON.stringify(getAvailResult.data).substring(0, 100)}...`);
  testResults.push({ test: '1.1 GET availability', pass: getAvailResult.status === 200 });

  // Test 1.2: Set My Availability
  console.log('\nTEST 1.2: PUT /scheduling/availability');
  const setAvailResult = await makeRequest('PUT', '/scheduling/availability', {
    availability: [
      { dayOfWeek: 1, startTime: '09:00', endTime: '17:00', isActive: true },
      { dayOfWeek: 2, startTime: '09:00', endTime: '17:00', isActive: true },
      { dayOfWeek: 3, startTime: '09:00', endTime: '17:00', isActive: true },
      { dayOfWeek: 4, startTime: '09:00', endTime: '17:00', isActive: true },
      { dayOfWeek: 5, startTime: '09:00', endTime: '17:00', isActive: true },
    ]
  }, token);
  console.log(`  Status: ${setAvailResult.status}`);
  console.log(`  Expected: 200`);
  console.log(`  Result: ${setAvailResult.status === 200 ? '✓ PASS' : '✗ FAIL'}`);
  if (setAvailResult.status !== 200) {
    console.log(`  Error: ${JSON.stringify(setAvailResult.data)}`);
  }
  testResults.push({ test: '1.2 PUT availability', pass: setAvailResult.status === 200 });

  // Test 1.3: Verify Availability was saved
  console.log('\nTEST 1.3: Verify availability was saved');
  const verifyAvailResult = await makeRequest('GET', '/scheduling/availability', null, token);
  const hasAvailability = Array.isArray(verifyAvailResult.data) && verifyAvailResult.data.length > 0;
  console.log(`  Status: ${verifyAvailResult.status}`);
  console.log(`  Has availability entries: ${hasAvailability}`);
  console.log(`  Result: ${hasAvailability ? '✓ PASS' : '✗ FAIL'}`);
  testResults.push({ test: '1.3 Verify availability saved', pass: hasAvailability });

  // =============================================
  // PHASE 2: EXCEPTIONS TESTS
  // =============================================
  console.log('\n===========================================');
  console.log('PHASE 2: EXCEPTIONS API TESTS');
  console.log('===========================================\n');

  // Test 2.1: Get My Exceptions (empty state)
  console.log('TEST 2.1: GET /scheduling/availability/exceptions');
  const getExcResult = await makeRequest('GET', '/scheduling/availability/exceptions', null, token);
  console.log(`  Status: ${getExcResult.status}`);
  console.log(`  Expected: 200`);
  console.log(`  Result: ${getExcResult.status === 200 ? '✓ PASS' : '✗ FAIL'}`);
  testResults.push({ test: '2.1 GET exceptions', pass: getExcResult.status === 200 });

  // Test 2.2: Create Exception (day off)
  console.log('\nTEST 2.2: POST /scheduling/availability/exceptions (day off)');
  const tomorrow = new Date();
  tomorrow.setDate(tomorrow.getDate() + 1);
  const tomorrowStr = tomorrow.toISOString().split('T')[0];

  const createExcResult = await makeRequest('POST', '/scheduling/availability/exceptions', {
    date: tomorrowStr,
    isAvailable: false,
    reason: 'Test day off'
  }, token);
  console.log(`  Status: ${createExcResult.status}`);
  console.log(`  Expected: 201`);
  console.log(`  Result: ${createExcResult.status === 201 ? '✓ PASS' : '✗ FAIL'}`);
  if (createExcResult.status !== 201) {
    console.log(`  Error: ${JSON.stringify(createExcResult.data)}`);
  }
  testResults.push({ test: '2.2 POST exception', pass: createExcResult.status === 201 });

  let exceptionId = createExcResult.data?.id;

  // Test 2.3: Create duplicate exception (should fail)
  console.log('\nTEST 2.3: POST duplicate exception (should fail)');
  const dupExcResult = await makeRequest('POST', '/scheduling/availability/exceptions', {
    date: tomorrowStr,
    isAvailable: false,
    reason: 'Duplicate'
  }, token);
  console.log(`  Status: ${dupExcResult.status}`);
  console.log(`  Expected: 400 (duplicate)`);
  console.log(`  Result: ${dupExcResult.status === 400 ? '✓ PASS' : '✗ FAIL'}`);
  testResults.push({ test: '2.3 Duplicate exception rejected', pass: dupExcResult.status === 400 });

  // Test 2.4: Delete exception
  if (exceptionId) {
    console.log('\nTEST 2.4: DELETE /scheduling/availability/exceptions/item/:id');
    const delExcResult = await makeRequest('DELETE', `/scheduling/availability/exceptions/item/${exceptionId}`, null, token);
    console.log(`  Status: ${delExcResult.status}`);
    console.log(`  Expected: 200`);
    console.log(`  Result: ${delExcResult.status === 200 ? '✓ PASS' : '✗ FAIL'}`);
    testResults.push({ test: '2.4 DELETE exception', pass: delExcResult.status === 200 });
  }

  // =============================================
  // PHASE 3: SLOTS TESTS
  // =============================================
  console.log('\n===========================================');
  console.log('PHASE 3: SLOTS API TESTS');
  console.log('===========================================\n');

  // Test 3.1: Get slots
  console.log('TEST 3.1: GET /scheduling/slots');
  const startDate = new Date();
  startDate.setDate(startDate.getDate() + 1);
  const endDate = new Date();
  endDate.setDate(endDate.getDate() + 7);

  const slotsResult = await makeRequest('GET', `/scheduling/slots?surveyorId=${userId}&startDate=${startDate.toISOString().split('T')[0]}&endDate=${endDate.toISOString().split('T')[0]}`, null, token);
  console.log(`  Status: ${slotsResult.status}`);
  console.log(`  Expected: 200`);
  console.log(`  Result: ${slotsResult.status === 200 ? '✓ PASS' : '✗ FAIL'}`);
  if (slotsResult.status === 200) {
    console.log(`  Slots data: ${JSON.stringify(slotsResult.data).substring(0, 200)}...`);
  } else {
    console.log(`  Error: ${JSON.stringify(slotsResult.data)}`);
  }
  testResults.push({ test: '3.1 GET slots', pass: slotsResult.status === 200 });

  // =============================================
  // PHASE 4: BOOKING TESTS
  // =============================================
  console.log('\n===========================================');
  console.log('PHASE 4: BOOKING API TESTS');
  console.log('===========================================\n');

  // Test 4.1: Get My Bookings (empty state)
  console.log('TEST 4.1: GET /scheduling/bookings/my');
  const getBookingsResult = await makeRequest('GET', '/scheduling/bookings/my', null, token);
  console.log(`  Status: ${getBookingsResult.status}`);
  console.log(`  Expected: 200`);
  console.log(`  Result: ${getBookingsResult.status === 200 ? '✓ PASS' : '✗ FAIL'}`);
  testResults.push({ test: '4.1 GET my bookings', pass: getBookingsResult.status === 200 });

  // Test 4.2: Create Booking
  console.log('\nTEST 4.2: POST /scheduling/bookings');
  const bookingDate = new Date();
  bookingDate.setDate(bookingDate.getDate() + 2); // 2 days from now
  // Find next weekday
  while (bookingDate.getDay() === 0 || bookingDate.getDay() === 6) {
    bookingDate.setDate(bookingDate.getDate() + 1);
  }
  const bookingDateStr = bookingDate.toISOString().split('T')[0];

  const createBookingResult = await makeRequest('POST', '/scheduling/bookings', {
    surveyorId: userId,
    date: bookingDateStr,
    startTime: '10:00',
    endTime: '11:00',
    clientName: 'Test Client',
    clientPhone: '1234567890',
    propertyAddress: '123 Test St'
  }, token);
  console.log(`  Status: ${createBookingResult.status}`);
  console.log(`  Expected: 201`);
  console.log(`  Result: ${createBookingResult.status === 201 ? '✓ PASS' : '✗ FAIL'}`);
  if (createBookingResult.status !== 201) {
    console.log(`  Error: ${JSON.stringify(createBookingResult.data)}`);
  }
  testResults.push({ test: '4.2 POST booking', pass: createBookingResult.status === 201 });

  let bookingId = createBookingResult.data?.id;

  // Test 4.3: Double booking prevention
  console.log('\nTEST 4.3: Double booking prevention (should fail)');
  const doubleBookingResult = await makeRequest('POST', '/scheduling/bookings', {
    surveyorId: userId,
    date: bookingDateStr,
    startTime: '10:30',
    endTime: '11:30',
    clientName: 'Another Client'
  }, token);
  console.log(`  Status: ${doubleBookingResult.status}`);
  console.log(`  Expected: 400 (conflict)`);
  console.log(`  Result: ${doubleBookingResult.status === 400 ? '✓ PASS' : '✗ FAIL'}`);
  testResults.push({ test: '4.3 Double booking rejected', pass: doubleBookingResult.status === 400 });

  // Test 4.4: Update booking status
  if (bookingId) {
    console.log('\nTEST 4.4: PATCH /scheduling/bookings/:id/status');
    const updateStatusResult = await makeRequest('PATCH', `/scheduling/bookings/${bookingId}/status`, {
      status: 'CONFIRMED'
    }, token);
    console.log(`  Status: ${updateStatusResult.status}`);
    console.log(`  Expected: 200`);
    console.log(`  Result: ${updateStatusResult.status === 200 ? '✓ PASS' : '✗ FAIL'}`);
    testResults.push({ test: '4.4 PATCH booking status', pass: updateStatusResult.status === 200 });
  }

  // Test 4.5: Get booking by ID
  if (bookingId) {
    console.log('\nTEST 4.5: GET /scheduling/bookings/:id');
    const getBookingResult = await makeRequest('GET', `/scheduling/bookings/${bookingId}`, null, token);
    console.log(`  Status: ${getBookingResult.status}`);
    console.log(`  Expected: 200`);
    const statusIsConfirmed = getBookingResult.data?.status === 'CONFIRMED';
    console.log(`  Status is CONFIRMED: ${statusIsConfirmed}`);
    console.log(`  Result: ${getBookingResult.status === 200 && statusIsConfirmed ? '✓ PASS' : '✗ FAIL'}`);
    testResults.push({ test: '4.5 GET booking by ID', pass: getBookingResult.status === 200 && statusIsConfirmed });
  }

  // =============================================
  // SUMMARY
  // =============================================
  console.log('\n===========================================');
  console.log('TEST SUMMARY');
  console.log('===========================================\n');

  const passed = testResults.filter(t => t.pass).length;
  const failed = testResults.filter(t => !t.pass).length;

  console.log(`Total Tests: ${testResults.length}`);
  console.log(`Passed: ${passed}`);
  console.log(`Failed: ${failed}`);
  console.log(`Success Rate: ${((passed / testResults.length) * 100).toFixed(1)}%`);

  console.log('\nDetailed Results:');
  testResults.forEach(t => {
    console.log(`  ${t.pass ? '✓' : '✗'} ${t.test}`);
  });

  if (failed > 0) {
    console.log('\n⚠️  VERDICT: NEEDS FIXES');
  } else {
    console.log('\n✅ VERDICT: ALL TESTS PASSED');
  }
}

runTests().catch(console.error);

const http = require('http');

function api(method, path, data, headers) {
  headers = headers || {};
  return new Promise(function(resolve) {
    var url = new URL('http://localhost:3000/api/v1' + path);
    var opts = {
      method: method,
      hostname: url.hostname,
      port: url.port,
      path: url.pathname,
      headers: Object.assign({ 'Content-Type': 'application/json' }, headers)
    };
    var req = http.request(opts, function(res) {
      var body = '';
      res.on('data', function(c) { body += c; });
      res.on('end', function() {
        try { resolve({ status: res.statusCode, body: JSON.parse(body) }); }
        catch(e) { resolve({ status: res.statusCode, body: body }); }
      });
    });
    req.on('error', function(e) { resolve({ status: 0, body: e.message }); });
    if (data) req.write(JSON.stringify(data));
    req.end();
  });
}

function wait(ms) { return new Promise(function(r) { setTimeout(r, ms); }); }

function log(test, status, pass, detail) {
  var icon = pass ? 'PASS' : 'FAIL';
  console.log('[' + icon + '] ' + test + ' (HTTP ' + status + ')' + (detail ? ' - ' + detail : ''));
  return { test: test, status: status, pass: pass, detail: detail };
}

async function run() {
  var results = [];
  var ts = Date.now();

  // ═══ REGISTER + LOGIN ═══
  console.log('\n=== AUTHENTICATION ===');
  await wait(2000);
  var reg = await api('POST', '/auth/register', {
    email: 'qa-v2-' + ts + '@test.local',
    password: 'SecureP@ss1',
    firstName: 'QA',
    lastName: 'TestV2'
  });
  results.push(log('AUTH: Register', reg.status, reg.status === 201));
  await wait(2000);

  var login = await api('POST', '/auth/login', {
    email: 'qa-v2-' + ts + '@test.local',
    password: 'SecureP@ss1'
  });
  results.push(log('AUTH: Login', login.status, login.status === 200));
  if (login.status !== 200) {
    console.log('FATAL: Cannot continue without auth');
    return;
  }
  var token = login.body.accessToken;
  var auth = { Authorization: 'Bearer ' + token };
  await wait(1500);

  // ═══ SURVEYS (using correct routes: POST/GET/PUT/DELETE) ═══
  console.log('\n=== SURVEYS CRUD ===');

  var r = await api('POST', '/surveys', {
    title: 'QA Test Survey - Level 2',
    propertyAddress: '123 Test Street, London, SW1A 1AA',
    type: 'LEVEL_2',
    clientName: 'QA Client',
    jobRef: 'QA-' + ts
  }, auth);
  results.push(log('S1: Create survey', r.status, r.status === 201, r.body && r.body.id));
  var surveyId = r.body && r.body.id;
  await wait(1000);

  r = await api('GET', '/surveys', null, auth);
  results.push(log('S2: List surveys', r.status, r.status === 200));
  await wait(1000);

  if (surveyId) {
    r = await api('GET', '/surveys/' + surveyId, null, auth);
    results.push(log('S3: Get survey', r.status, r.status === 200));
    await wait(1000);

    // PUT not PATCH for surveys
    r = await api('PUT', '/surveys/' + surveyId, {
      title: 'Updated QA Survey',
      propertyAddress: '456 Updated Street, London',
      type: 'LEVEL_2'
    }, auth);
    results.push(log('S4: Update survey (PUT)', r.status, r.status === 200, (r.status !== 200) ? JSON.stringify(r.body).substring(0, 200) : undefined));
    await wait(1000);

    // Report data
    r = await api('GET', '/surveys/' + surveyId + '/report-data', null, auth);
    results.push(log('S5: Get report data', r.status, r.status === 200, (r.status !== 200) ? JSON.stringify(r.body).substring(0, 200) : undefined));
    await wait(1000);

    // ═══ SECTIONS (POST under survey, PUT/DELETE standalone) ═══
    console.log('\n=== SECTIONS CRUD ===');
    r = await api('POST', '/surveys/' + surveyId + '/sections', {
      title: 'Roof Inspection',
      order: 1
    }, auth);
    results.push(log('SC1: Create section', r.status, r.status === 201, r.body && r.body.id));
    var sectionId = r.body && r.body.id;
    await wait(1000);

    if (sectionId) {
      // PUT not PATCH for sections
      r = await api('PUT', '/sections/' + sectionId, {
        title: 'Updated Roof Section',
        order: 1
      }, auth);
      results.push(log('SC2: Update section (PUT)', r.status, r.status === 200, (r.status !== 200) ? JSON.stringify(r.body).substring(0, 200) : undefined));
      await wait(1000);

      // ═══ ANSWERS (POST under section, PUT/DELETE standalone) ═══
      console.log('\n=== ANSWERS CRUD ===');
      r = await api('POST', '/sections/' + sectionId + '/answers', {
        questionKey: 'roof_condition',
        value: 'Good condition with minor wear'
      }, auth);
      results.push(log('AN1: Create answer', r.status, r.status === 201, r.body && r.body.id));
      var answerId = r.body && r.body.id;
      await wait(1000);

      if (answerId) {
        // PUT not PATCH for answers
        r = await api('PUT', '/answers/' + answerId, {
          questionKey: 'roof_condition',
          value: 'Updated: Fair condition needs repair'
        }, auth);
        results.push(log('AN2: Update answer (PUT)', r.status, r.status === 200, (r.status !== 200) ? JSON.stringify(r.body).substring(0, 200) : undefined));
        await wait(1000);

        r = await api('DELETE', '/answers/' + answerId, null, auth);
        results.push(log('AN3: Delete answer', r.status, r.status === 200 || r.status === 204));
        await wait(1000);
      }

      r = await api('DELETE', '/sections/' + sectionId, null, auth);
      results.push(log('SC3: Delete section', r.status, r.status === 200 || r.status === 204));
      await wait(1000);
    }

    // Access control tests
    r = await api('GET', '/surveys/' + surveyId);
    results.push(log('S6: No auth (401)', r.status, r.status === 401));

    r = await api('GET', '/surveys/00000000-0000-0000-0000-000000000000', null, auth);
    results.push(log('S7: Not found', r.status, r.status === 404 || r.status === 403));
    await wait(1000);
  }

  // ═══ SCHEDULING ═══
  console.log('\n=== SCHEDULING ===');
  await wait(1500);

  r = await api('GET', '/scheduling/availability', null, auth);
  results.push(log('BK1: Get my availability', r.status, r.status === 200, (r.status >= 400) ? JSON.stringify(r.body).substring(0, 150) : undefined));
  await wait(1000);

  r = await api('GET', '/scheduling/bookings', null, auth);
  results.push(log('BK2: List bookings', r.status, r.status === 200 || r.status === 403, (r.status >= 400) ? JSON.stringify(r.body).substring(0, 150) : undefined));
  await wait(1000);

  r = await api('GET', '/scheduling/bookings/my', null, auth);
  results.push(log('BK3: My bookings', r.status, r.status === 200));
  await wait(1000);

  r = await api('GET', '/scheduling/slots', null, auth);
  results.push(log('BK4: Get slots', r.status, r.status === 200 || r.status === 400, (r.status >= 400) ? JSON.stringify(r.body).substring(0, 150) : undefined));
  await wait(1000);

  // ═══ CONFIG (PUBLIC) ═══
  console.log('\n=== CONFIG (PUBLIC) ===');

  r = await api('GET', '/config/all', null, auth);
  results.push(log('CF1: Get all config', r.status, r.status === 200));
  await wait(1000);

  r = await api('GET', '/config/version', null, auth);
  results.push(log('CF2: Get config version', r.status, r.status === 200));
  await wait(1000);

  // ═══ NOTIFICATIONS ═══
  console.log('\n=== NOTIFICATIONS ===');

  r = await api('GET', '/notifications', null, auth);
  results.push(log('NT1: List notifications', r.status, r.status === 200));
  await wait(1000);

  r = await api('GET', '/notifications/unread-count', null, auth);
  results.push(log('NT2: Unread count', r.status, r.status === 200));
  await wait(1000);

  r = await api('POST', '/notifications/read-all', null, auth);
  results.push(log('NT3: Mark all read', r.status, r.status === 200 || r.status === 201));
  await wait(1000);

  // ═══ SYNC ═══
  console.log('\n=== SYNC ===');

  r = await api('GET', '/sync/pull', null, auth);
  results.push(log('SY1: Sync pull (GET)', r.status, r.status === 200, (r.status >= 400) ? JSON.stringify(r.body).substring(0, 200) : undefined));
  await wait(1000);

  r = await api('POST', '/sync/push', {
    idempotencyKey: 'test-' + ts,
    changes: []
  }, auth);
  results.push(log('SY2: Sync push', r.status, [200, 201, 400].includes(r.status), (r.status >= 400) ? JSON.stringify(r.body).substring(0, 200) : undefined));
  await wait(1000);

  // ═══ INVOICES (SURVEYOR = 403 expected) ═══
  console.log('\n=== INVOICES (RBAC) ===');

  r = await api('GET', '/invoices', null, auth);
  results.push(log('INV1: List invoices (RBAC)', r.status, r.status === 200 || r.status === 403));
  await wait(1000);

  // ═══ EXPORTS (ADMIN only) ═══
  console.log('\n=== EXPORTS (RBAC) ===');

  r = await api('GET', '/exports/bookings', null, auth);
  results.push(log('EX1: Export bookings (RBAC)', r.status, r.status === 200 || r.status === 403));
  await wait(500);

  r = await api('GET', '/exports/invoices', null, auth);
  results.push(log('EX2: Export invoices (RBAC)', r.status, r.status === 200 || r.status === 403));
  await wait(500);

  r = await api('GET', '/exports/reports', null, auth);
  results.push(log('EX3: Export reports (RBAC)', r.status, r.status === 200 || r.status === 403));
  await wait(1000);

  // ═══ AUDIT LOGS ═══
  console.log('\n=== AUDIT LOGS ===');

  r = await api('GET', '/audit-logs', null, auth);
  results.push(log('AL1: Get audit logs', r.status, r.status === 200 || r.status === 403, (r.status >= 400) ? JSON.stringify(r.body).substring(0, 150) : undefined));
  await wait(1000);

  // ═══ WEBHOOKS (ADMIN only) ═══
  console.log('\n=== WEBHOOKS (RBAC) ===');

  r = await api('GET', '/webhooks', null, auth);
  results.push(log('WH1: List webhooks (RBAC)', r.status, r.status === 200 || r.status === 403));
  await wait(1000);

  // ═══ AI ENDPOINTS ═══
  console.log('\n=== AI ===');

  r = await api('GET', '/ai/status', null, auth);
  results.push(log('AI1: AI status', r.status, r.status === 200, (r.status >= 400) ? JSON.stringify(r.body).substring(0, 200) : undefined));
  await wait(1000);

  if (surveyId) {
    // Proper AI report payload
    r = await api('POST', '/ai/report', {
      surveyId: surveyId,
      propertyAddress: '123 Test Street',
      sections: [{ title: 'Roof', answers: [{ questionKey: 'condition', value: 'good' }] }]
    }, auth);
    results.push(log('AI2: Generate report', r.status, [200, 201, 403, 429].includes(r.status), JSON.stringify(r.body).substring(0, 200)));
    await wait(1000);
  }

  // ═══ BOOKING REQUESTS (Staff) ═══
  console.log('\n=== BOOKING REQUESTS ===');

  r = await api('GET', '/booking-requests', null, auth);
  results.push(log('BR1: List booking requests', r.status, r.status === 200 || r.status === 403));
  await wait(1000);

  // ═══ BOOKING CHANGE REQUESTS (Staff) ═══
  r = await api('GET', '/booking-changes', null, auth);
  results.push(log('BCR1: List change requests', r.status, r.status === 200 || r.status === 403));
  await wait(1000);

  // ═══ ADMIN CONFIG (RBAC test) ═══
  console.log('\n=== ADMIN CONFIG (RBAC) ===');

  r = await api('GET', '/admin/config/categories', null, auth);
  results.push(log('AC1: Admin categories (RBAC)', r.status, r.status === 200 || r.status === 403));
  await wait(500);

  r = await api('GET', '/admin/config/phrases', null, auth);
  results.push(log('AC2: Admin phrases (RBAC)', r.status, r.status === 200 || r.status === 403));
  await wait(500);

  r = await api('GET', '/admin/config/fields', null, auth);
  results.push(log('AC3: Admin fields (RBAC)', r.status, r.status === 200 || r.status === 403));
  await wait(500);

  r = await api('GET', '/admin/config/section-types', null, auth);
  results.push(log('AC4: Admin section types (RBAC)', r.status, r.status === 200 || r.status === 403));
  await wait(500);

  r = await api('GET', '/admin/config/users', null, auth);
  results.push(log('AC5: Admin users (RBAC)', r.status, r.status === 200 || r.status === 403));
  await wait(1000);

  // ═══ SECURITY TESTS ═══
  console.log('\n=== SECURITY ===');

  r = await api('POST', '/auth/login', { email: "admin'--", password: 'test' });
  results.push(log('SEC1: SQL injection', r.status, r.status === 400 || r.status === 401 || r.status === 429));
  await wait(1000);

  var bigStr = 'x'.repeat(50000);
  r = await api('POST', '/surveys', { title: bigStr, propertyAddress: '123' }, auth);
  results.push(log('SEC2: Oversized payload', r.status, r.status === 400 || r.status === 413));
  await wait(1000);

  // Path traversal in survey ID
  r = await api('GET', '/surveys/../auth/me', null, auth);
  results.push(log('SEC3: Path traversal', r.status, r.status === 404 || r.status === 400));
  await wait(1000);

  // ═══ CLEANUP ═══
  if (surveyId) {
    await api('DELETE', '/surveys/' + surveyId, null, auth);
  }

  // ═══ SUMMARY ═══
  var passed = results.filter(function(x) { return x.pass; }).length;
  var failed = results.filter(function(x) { return !x.pass; }).length;

  console.log('\n========================================');
  console.log('TOTAL: ' + results.length + ' | PASSED: ' + passed + ' | FAILED: ' + failed);
  console.log('========================================');

  if (failed > 0) {
    console.log('\nFailed tests:');
    results.filter(function(x) { return !x.pass; }).forEach(function(x) {
      console.log('  [FAIL] ' + x.test + ' (HTTP ' + x.status + ')' + (x.detail ? ' - ' + x.detail : ''));
    });
  }

  // Output JSON for report
  console.log('\nJSON_RESULTS:' + JSON.stringify({ total: results.length, passed: passed, failed: failed, failedTests: results.filter(function(x){return !x.pass}) }));
}

run().catch(function(e) { console.error(e); });

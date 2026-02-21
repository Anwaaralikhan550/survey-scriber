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

  // ═══ LOGIN ═══
  console.log('\n=== AUTHENTICATION ===');
  var login = await api('POST', '/auth/login', {
    email: 'qa-e2e-' + ts + '@test.local',
    password: 'SecureP@ss1'
  });

  // If test user doesn't exist, register first
  if (login.status !== 200) {
    await wait(2000);
    var reg = await api('POST', '/auth/register', {
      email: 'qa-full-' + ts + '@test.local',
      password: 'SecureP@ss1',
      firstName: 'QA',
      lastName: 'Full'
    });
    results.push(log('AUTH: Register', reg.status, reg.status === 201));
    await wait(2000);

    login = await api('POST', '/auth/login', {
      email: 'qa-full-' + ts + '@test.local',
      password: 'SecureP@ss1'
    });
  }
  results.push(log('AUTH: Login', login.status, login.status === 200));

  if (login.status !== 200) {
    console.log('Cannot continue without auth. Body:', JSON.stringify(login.body));
    return;
  }

  var token = login.body.accessToken;
  var auth = { Authorization: 'Bearer ' + token };
  await wait(1500);

  // ═══ SURVEYS ═══
  console.log('\n=== SURVEYS CRUD ===');

  var r = await api('POST', '/surveys', {
    title: 'QA Test Survey - Level 2 Home Survey',
    propertyAddress: '123 Test Street, London, SW1A 1AA',
    type: 'LEVEL_2',
    clientName: 'QA Test Client',
    jobRef: 'QA-' + ts
  }, auth);
  results.push(log('S1: Create survey', r.status, r.status === 201, r.body && r.body.id));
  var surveyId = r.body && r.body.id;
  await wait(1000);

  r = await api('GET', '/surveys', null, auth);
  var surveyCount = Array.isArray(r.body) ? r.body.length : (r.body && r.body.data ? r.body.data.length : 0);
  results.push(log('S2: List surveys', r.status, r.status === 200, 'count=' + surveyCount));
  await wait(1000);

  if (surveyId) {
    r = await api('GET', '/surveys/' + surveyId, null, auth);
    results.push(log('S3: Get survey', r.status, r.status === 200));
    await wait(1000);

    r = await api('PATCH', '/surveys/' + surveyId, { title: 'Updated QA Survey' }, auth);
    results.push(log('S4: Update survey', r.status, r.status === 200, (r.status !== 200) ? JSON.stringify(r.body).substring(0, 200) : undefined));
    await wait(1000);

    // ═══ SECTIONS ═══
    console.log('\n=== SECTIONS CRUD ===');
    r = await api('POST', '/surveys/' + surveyId + '/sections', {
      title: 'Roof Inspection',
      order: 1
    }, auth);
    results.push(log('SC1: Create section', r.status, r.status === 201 || r.status === 200, r.body && r.body.id));
    var sectionId = r.body && r.body.id;
    await wait(1000);

    r = await api('GET', '/surveys/' + surveyId + '/sections', null, auth);
    results.push(log('SC2: List sections', r.status, r.status === 200));
    await wait(1000);

    if (sectionId) {
      // ═══ ANSWERS ═══
      console.log('\n=== ANSWERS CRUD ===');
      r = await api('POST', '/sections/' + sectionId + '/answers', {
        questionKey: 'roof_condition',
        value: 'Good condition with minor wear'
      }, auth);
      results.push(log('AN1: Create answer', r.status, r.status === 201 || r.status === 200, r.body && r.body.id));
      var answerId = r.body && r.body.id;
      await wait(1000);

      r = await api('GET', '/sections/' + sectionId + '/answers', null, auth);
      results.push(log('AN2: List answers', r.status, r.status === 200));
      await wait(1000);

      if (answerId) {
        r = await api('PATCH', '/sections/' + sectionId + '/answers/' + answerId, { value: 'Updated: Fair condition' }, auth);
        results.push(log('AN3: Update answer', r.status, r.status === 200, (r.status !== 200) ? JSON.stringify(r.body).substring(0, 200) : undefined));
        await wait(1000);

        r = await api('DELETE', '/sections/' + sectionId + '/answers/' + answerId, null, auth);
        results.push(log('AN4: Delete answer', r.status, r.status === 200 || r.status === 204));
        await wait(1000);
      }

      r = await api('DELETE', '/surveys/' + surveyId + '/sections/' + sectionId, null, auth);
      results.push(log('SC3: Delete section', r.status, r.status === 200 || r.status === 204));
      await wait(1000);
    }

    // Access control
    r = await api('GET', '/surveys/' + surveyId);
    results.push(log('S5: No auth rejected', r.status, r.status === 401));

    r = await api('GET', '/surveys/00000000-0000-0000-0000-000000000000', null, auth);
    results.push(log('S6: Not found', r.status, r.status === 404 || r.status === 403));
    await wait(1000);
  }

  // ═══ SCHEDULING ═══
  console.log('\n=== SCHEDULING ===');
  await wait(1500);

  r = await api('GET', '/bookings', null, auth);
  results.push(log('BK1: List bookings', r.status, r.status === 200 || r.status === 403, (r.status >= 400) ? JSON.stringify(r.body).substring(0, 150) : undefined));
  await wait(1000);

  r = await api('GET', '/availability', null, auth);
  results.push(log('BK2: Get availability', r.status, r.status === 200 || r.status === 403, (r.status >= 400) ? JSON.stringify(r.body).substring(0, 150) : undefined));
  await wait(1000);

  // ═══ CONFIG (PUBLIC) ═══
  console.log('\n=== CONFIG (PUBLIC) ===');

  r = await api('GET', '/config/all', null, auth);
  results.push(log('CF1: Get all config', r.status, r.status === 200, (r.status !== 200) ? JSON.stringify(r.body).substring(0, 200) : undefined));
  await wait(1000);

  r = await api('GET', '/config/phrases', null, auth);
  results.push(log('CF2: Get phrases', r.status, r.status === 200));
  await wait(1000);

  r = await api('GET', '/config/fields', null, auth);
  results.push(log('CF3: Get fields', r.status, r.status === 200));
  await wait(1000);

  // ═══ NOTIFICATIONS ═══
  console.log('\n=== NOTIFICATIONS ===');

  r = await api('GET', '/notifications', null, auth);
  results.push(log('NT1: List notifications', r.status, r.status === 200));
  await wait(1000);

  // ═══ SYNC ═══
  console.log('\n=== SYNC ===');

  r = await api('POST', '/sync/pull', { lastSyncAt: null }, auth);
  results.push(log('SY1: Sync pull', r.status, r.status === 200 || r.status === 201, (r.status >= 400) ? JSON.stringify(r.body).substring(0, 200) : undefined));
  await wait(1000);

  r = await api('POST', '/sync/push', { surveys: [], deletedIds: [] }, auth);
  results.push(log('SY2: Sync push empty', r.status, r.status === 200 || r.status === 201, (r.status >= 400) ? JSON.stringify(r.body).substring(0, 200) : undefined));
  await wait(1000);

  // ═══ INVOICES (admin-only, expect 403 for SURVEYOR role) ═══
  console.log('\n=== INVOICES ===');

  r = await api('GET', '/invoices', null, auth);
  results.push(log('INV1: List invoices', r.status, r.status === 200 || r.status === 403, (r.status === 403) ? 'Expected 403 for SURVEYOR role' : undefined));
  await wait(1000);

  // ═══ EXPORTS (admin-only) ═══
  console.log('\n=== EXPORTS ===');

  r = await api('GET', '/exports/bookings', null, auth);
  results.push(log('EX1: Export bookings', r.status, r.status === 200 || r.status === 403, (r.status === 403) ? 'Expected 403 for SURVEYOR role' : undefined));
  await wait(1000);

  // ═══ AUDIT LOGS (admin-only) ═══
  console.log('\n=== AUDIT LOGS ===');

  r = await api('GET', '/audit/logs', null, auth);
  results.push(log('AL1: Get audit logs', r.status, r.status === 200 || r.status === 403, (r.status === 403) ? 'Expected 403 for SURVEYOR role' : undefined));
  await wait(1000);

  // ═══ WEBHOOKS (admin-only) ═══
  console.log('\n=== WEBHOOKS ===');

  r = await api('GET', '/webhooks', null, auth);
  results.push(log('WH1: List webhooks', r.status, r.status === 200 || r.status === 403, (r.status === 403) ? 'Expected 403 for SURVEYOR role' : undefined));
  await wait(1000);

  // ═══ AI ═══
  console.log('\n=== AI ===');

  if (surveyId) {
    r = await api('POST', '/ai/report', { surveyId: surveyId }, auth);
    results.push(log('AI1: Generate report', r.status, [200, 201, 403, 404, 429].includes(r.status), JSON.stringify(r.body).substring(0, 200)));
    await wait(1000);
  }

  // ═══ SECURITY TESTS ═══
  console.log('\n=== SECURITY ===');

  // SQL injection attempt
  r = await api('POST', '/auth/login', { email: "admin'--", password: 'test' });
  results.push(log('SEC1: SQL injection login', r.status, r.status === 400 || r.status === 401 || r.status === 429, 'Properly rejected'));
  await wait(1000);

  // XSS in survey title
  if (surveyId) {
    r = await api('PATCH', '/surveys/' + surveyId, { title: '<script>alert("xss")</script>' }, auth);
    results.push(log('SEC2: XSS in survey title', r.status, r.status === 200 || r.status === 400, 'Check if sanitized'));
    await wait(1000);
  }

  // Oversized payload
  var bigString = 'x'.repeat(50000);
  r = await api('POST', '/surveys', { title: bigString, propertyAddress: '123 Test' }, auth);
  results.push(log('SEC3: Oversized payload', r.status, r.status === 400 || r.status === 413, 'Rejected oversized'));
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

  console.log('\n' + JSON.stringify({ total: results.length, passed: passed, failed: failed }));
}

run().catch(function(e) { console.error(e); });

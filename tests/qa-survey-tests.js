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

async function run() {
  var results = [];

  // Login
  var login = await api('POST', '/auth/login', {
    email: 'qa-e2e-1769921908195@test.local',
    password: 'NewSecure@1'
  });
  if (login.status !== 200) {
    console.log('Login failed:', JSON.stringify(login));
    return;
  }
  var token = login.body.accessToken;
  var auth = { Authorization: 'Bearer ' + token };
  await wait(1500);

  // S1: Create survey
  var r = await api('POST', '/surveys', {
    address: '123 Test Street, London, SW1A 1AA',
    clientName: 'QA Test Client',
    surveyType: 'LEVEL_2',
    inspectionDate: new Date().toISOString()
  }, auth);
  results.push({ test: 'S1: Create survey', status: r.status, pass: r.status === 201 || r.status === 200, id: r.body && r.body.id, detail: (r.status > 201) ? JSON.stringify(r.body).substring(0, 300) : undefined });
  var surveyId = r.body && r.body.id;
  await wait(1000);

  // S2: List surveys
  r = await api('GET', '/surveys', null, auth);
  results.push({ test: 'S2: List surveys', status: r.status, pass: r.status === 200, count: Array.isArray(r.body) ? r.body.length : (r.body && r.body.data ? r.body.data.length : 'unknown') });
  await wait(1000);

  if (surveyId) {
    // S3: Get survey by ID
    r = await api('GET', '/surveys/' + surveyId, null, auth);
    results.push({ test: 'S3: Get survey', status: r.status, pass: r.status === 200 });
    await wait(1000);

    // S4: Update survey
    r = await api('PATCH', '/surveys/' + surveyId, { address: '456 Updated Street' }, auth);
    results.push({ test: 'S4: Update survey', status: r.status, pass: r.status === 200, detail: (r.status !== 200) ? JSON.stringify(r.body).substring(0, 300) : undefined });
    await wait(1000);

    // S5: Create section
    r = await api('POST', '/surveys/' + surveyId + '/sections', {
      title: 'Test Section',
      sectionType: 'GENERAL',
      order: 1
    }, auth);
    results.push({ test: 'S5: Create section', status: r.status, pass: r.status === 201 || r.status === 200, id: r.body && r.body.id, detail: (r.status > 201) ? JSON.stringify(r.body).substring(0, 300) : undefined });
    var sectionId = r.body && r.body.id;
    await wait(1000);

    // S6: List sections
    r = await api('GET', '/surveys/' + surveyId + '/sections', null, auth);
    results.push({ test: 'S6: List sections', status: r.status, pass: r.status === 200 });
    await wait(1000);

    if (sectionId) {
      // S7: Create answer
      r = await api('POST', '/sections/' + sectionId + '/answers', {
        questionKey: 'test_question_1',
        value: 'Test answer value'
      }, auth);
      results.push({ test: 'S7: Create answer', status: r.status, pass: r.status === 201 || r.status === 200, id: r.body && r.body.id, detail: (r.status > 201) ? JSON.stringify(r.body).substring(0, 300) : undefined });
      var answerId = r.body && r.body.id;
      await wait(1000);

      // S8: List answers
      r = await api('GET', '/sections/' + sectionId + '/answers', null, auth);
      results.push({ test: 'S8: List answers', status: r.status, pass: r.status === 200 });
      await wait(1000);

      if (answerId) {
        // S9: Update answer
        r = await api('PATCH', '/sections/' + sectionId + '/answers/' + answerId, { value: 'Updated answer' }, auth);
        results.push({ test: 'S9: Update answer', status: r.status, pass: r.status === 200, detail: (r.status !== 200) ? JSON.stringify(r.body).substring(0, 300) : undefined });
        await wait(1000);

        // S10: Delete answer
        r = await api('DELETE', '/sections/' + sectionId + '/answers/' + answerId, null, auth);
        results.push({ test: 'S10: Delete answer', status: r.status, pass: r.status === 200 || r.status === 204 });
        await wait(1000);
      }

      // S11: Delete section
      r = await api('DELETE', '/surveys/' + surveyId + '/sections/' + sectionId, null, auth);
      results.push({ test: 'S11: Delete section', status: r.status, pass: r.status === 200 || r.status === 204 });
      await wait(1000);
    }

    // S12: No auth
    r = await api('GET', '/surveys/' + surveyId);
    results.push({ test: 'S12: No auth (401)', status: r.status, pass: r.status === 401 });

    // S13: Not found
    r = await api('GET', '/surveys/00000000-0000-0000-0000-000000000000', null, auth);
    results.push({ test: 'S13: Not found (404)', status: r.status, pass: r.status === 404 || r.status === 403 });
    await wait(1000);

    // S14: Delete survey
    r = await api('DELETE', '/surveys/' + surveyId, null, auth);
    results.push({ test: 'S14: Delete survey', status: r.status, pass: r.status === 200 || r.status === 204 });
  }

  console.log(JSON.stringify({
    total: results.length,
    passed: results.filter(function(x) { return x.pass; }).length,
    failed: results.filter(function(x) { return !x.pass; }).length,
    results: results
  }, null, 2));
}

run().catch(function(e) { console.error(e); });

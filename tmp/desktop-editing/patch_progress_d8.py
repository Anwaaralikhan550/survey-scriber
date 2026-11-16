p = 'E:/survey-scriber/docs/DESKTOP-EDITING-PROGRESS.md'
t = open(p, encoding='utf-8', newline='').read()
nl = '\r\n' if '\r\n' in t else '\n'
lines = t.split(nl)
out = []
i = 0
while i < len(lines):
    l = lines[i]
    if l.startswith('| D8 QA/security | TODO'):
        l = ("| D8 QA/security | DONE 16 Nov | see git log | All 14 spec section 21 tests are named automated tests (`backend/test/report-acceptance.e2e-spec.ts` AT-01..AT-14 + phone `final_export_test.dart`), map in `docs/desktop-editing/ACCEPTANCE.md`. "
             "Security: `report-security.e2e-spec.ts` (XSS payloads, CSRF on every write route, cross-report access, token/cookie/header checks, upload attacks, mass assignment, limits), `p25_security_live.js` 19/19 (production rate limits, headers, CORS, no secret in server log), `p26_xss.js` 17/17 (hostile text shown as text in Chrome, nothing runs). "
             "Load: `report-load.e2e-spec.ts` (30 parallel readers, 20 racing writers with no lost update, 480 KB report, 30x3 simultaneous links, parallel uploads). "
             "Deployment: `tool/desktop_editor/deploy/*.conf` + `docs/desktop-editing/DEPLOYMENT.md`; `p27_nginx.js` 33/33 against real nginx 1.27 in docker (headers, HSTS, caching, hidden files, token masked in access log, rate limit, clickjacking blocked, uploads, full edit), TLS variant validated with `nginx -t` and served. "
             "Final run 16 Nov: backend unit 104, backend e2e 169 (8 suites), Flutter 287 pass / 2 skipped (need live backend), Chrome p20 65, p21 49, p22 39, p23 46, p24 20, p26 17. Screenshots `tmp/desktop-editing/proof/d8_*.png`, viewed. "
             "Real defects found and fixed: guard errors lacked no-store/no-referrer headers; oversize or malformed request bodies gave 500 (now 413/400); fields not belonging to a block type (rating on a paragraph) were accepted; request bodies (report text) were written to the dev log on 4xx; nginx: reload at /editor was 404, HSTS missing on locations with own headers, backend HSTS doubled.")
    if l.startswith('## NEXT ACTION'):
        out.append(l)
        out.append("ALL STEPS D1-D8 DONE and verified locally. Nothing is pushed, deployed, built as APK or published. Wait for the user: (1) push to GitHub; (2) deploy backend + editor per `docs/desktop-editing/DEPLOYMENT.md`; (3) APK build; (4) Track A: ask the user to attach the client's returned valuation docx (13 answers). Open decisions for the owner: pruning of old report versions, telling clients the AI sees masked wording.")
        i += 2
        continue
    out.append(l)
    if l.startswith('## Log'):
        out.append("- 16 Nov: D8 done (see table). All eight steps complete; handover docs in docs/desktop-editing/.")
    i += 1
open(p, 'w', encoding='utf-8', newline='').write(nl.join(out))
print('ok')

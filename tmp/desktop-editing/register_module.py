for p, prefix in [(r'E:/survey-scriber/backend/src/app.module.ts', './modules'), (r'E:/survey-scriber/backend/test/test-app.module.ts', '../src/modules')]:
    raw = open(p, encoding='utf-8', newline='').read()
    crlf = '\r\n' in raw
    t = raw.replace('\r\n', '\n')
    imp_anchor = "import { AiModule } from '%s/ai/ai.module';\n" % prefix
    assert imp_anchor in t
    t = t.replace(imp_anchor, imp_anchor + "import { ReportEditingModule } from '%s/report-editing/report-editing.module';\n" % prefix, 1)
    # add to imports list after AiModule entry
    i = t.index('    AiModule,\n')
    t = t[:i] + '    AiModule,\n    ReportEditingModule,\n' + t[i + len('    AiModule,\n'):]
    open(p, 'w', encoding='utf-8', newline='').write(t.replace('\n', '\r\n') if crlf else t)
    print('ok', p)

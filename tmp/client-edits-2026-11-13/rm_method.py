# usage: python rm_method.py "<method signature prefix>" ...   removes the method (brace matched) from the valuation engine
import sys
P = 'E:/survey-scriber/lib/features/property_valuation/domain/valuation_phrase_engine.dart'
s = open(P, encoding='utf8', newline='').read()
for sig in sys.argv[1:]:
    i = s.index(sig)
    b = s.index('{', i)
    depth = 0; k = b
    while True:
        c = s[k]
        if c == '{': depth += 1
        elif c == '}':
            depth -= 1
            if depth == 0: break
        k += 1
    end = k + 1
    # swallow the following newline(s)
    while s[end] in '\r\n': end += 1
    s = s[:i] + s[end:]
    print('removed method', sig)
open(P, 'w', encoding='utf8', newline='').write(s)

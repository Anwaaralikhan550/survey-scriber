# usage: python append_test.py <chunk file>  -> appends a group before the final '}' of the Nov-13 valuation test file
import sys
p = 'E:/survey-scriber/test/features/property_valuation/domain/client_edits_2026_11_13_valuation_test.dart'
s = open(p, encoding='utf8').read()
t = open(sys.argv[1], encoding='utf8').read()
k = s.rindex('}')
open(p, 'w', encoding='utf8').write(s[:k] + t + s[k:])
print('appended')

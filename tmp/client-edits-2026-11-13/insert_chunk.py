# usage: python insert_chunk.py <chunk file> <marker line prefix> [rename_from rename_to]
# Inserts the chunk before the marker (first match) in the valuation engine; optional rename of the marker's method.
import sys
P = 'E:/survey-scriber/lib/features/property_valuation/domain/valuation_phrase_engine.dart'
s = open(P, encoding='utf8', newline='').read()
nl = '\r\n' if '\r\n' in s else '\n'
chunk = open(sys.argv[1], encoding='utf8').read().replace('\r\n', '\n').replace('\n', nl)
marker = sys.argv[2]
assert s.count(marker) == 1, s.count(marker)
repl = marker
if len(sys.argv) > 4: repl = marker.replace(sys.argv[3], sys.argv[4])
s = s.replace(marker, chunk + repl)
open(P, 'w', encoding='utf8', newline='').write(s)
print('inserted')

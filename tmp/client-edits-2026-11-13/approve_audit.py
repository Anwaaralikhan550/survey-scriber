# Adds the valuation audit's unapproved condition sentences to the bank (only the standard condition wording).
import json,re,sys
sys.path.insert(0,'E:/survey-scriber/tmp/client-edits-2026-11-13')
from add_templates import add
d=json.load(open('E:/survey-scriber/tool/phrase_audit/output/valuation_audit.json',encoding='utf8'))
sc=d['screens']; it=sc.items() if isinstance(sc,dict) else enumerate(sc)
pat=re.compile(r'(are|is) considered (good|reasonable) |(have|has) been assessed as (fair|very poor)\.$')
tot=set()
for k,s in it:
    for x in s.get('unapprovedSamples',[]) or []: tot.add(x)
cond=[x for x in tot if pat.search(x)]
print('unapproved',len(tot),'condition-pattern',len(cond),'other',[x[:100] for x in tot if x not in cond])
if cond: add(sorted(cond),sys.argv[1] if len(sys.argv)>1 else 'VAL_N13_V10b')

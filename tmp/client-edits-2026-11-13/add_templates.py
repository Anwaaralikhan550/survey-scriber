# Adds approved sentences to assets/property_valuation/phrase_texts.json (templates), skipping ones already there.
# usage in python: from add_templates import add; add(['sentence', ...], prefix='VAL_N13_V2')
import json
P = 'E:/survey-scriber/assets/property_valuation/phrase_texts.json'
def _norm(t): return ' '.join(t.replace('[free text]', '{FREE_TEXT}').replace('[number]', '{NUMBER}').split()).lower()
def load(): return json.load(open(P, encoding='utf8'))
def save(d): open(P, 'w', encoding='utf8', newline='\n').write(json.dumps(d, indent=2, ensure_ascii=False) + '\n')
def add(texts, prefix, screen='*'):
    d = load(); t = d['templates']
    have = {_norm(v['text']) for v in t.values()}
    n = 0
    for x in texts:
        if _norm(x) in have: continue
        tokens = []
        if '[free text]' in x: tokens.append('FREE_TEXT')
        if '[number]' in x: tokens.append('NUMBER')
        n += 1
        t[f'{prefix}_{n:04d}'] = {'screenId': screen, 'text': x, 'allowedTokens': tokens}
        have.add(_norm(x))
    save(d); print('added', n, 'templates; total', len(t))
if __name__ == '__main__':
    d = load(); save(d)

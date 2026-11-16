p = r'E:/survey-scriber/backend/prisma/schema.prisma'
t = open(p, encoding='utf-8', newline='').read().replace('\r\n', '\n')
assert 'model Report ' not in t
anchor = "  surveys                       Survey[]\n"
assert anchor in t
t = t.replace(anchor, anchor + "  reports                       Report[]\n", 1)
add = open(r'E:/survey-scriber/tmp/desktop-editing/schema_add.prisma', encoding='utf-8').read().replace('\r\n', '\n')
t = t.rstrip('\n') + '\n' + add
open(p, 'w', encoding='utf-8', newline='').write(t.replace('\n', '\r\n'))
print('ok')

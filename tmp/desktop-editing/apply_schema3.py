p = r'E:/survey-scriber/backend/prisma/schema.prisma'
t = open(p, encoding='utf-8', newline='').read().replace('\r\n', '\n')
old = "  reason    String   @db.VarChar(20) // SNAPSHOT | SAVE | RESTORE | FINALISE\n  createdAt DateTime @default(now()) @map(\"created_at\")\n\n  report Report @relation(fields: [reportId], references: [id], onDelete: Cascade)\n\n  @@unique([reportId, version])\n"
new = "  reason    String   @db.VarChar(20) // SNAPSHOT | SAVE | RESTORE | FINALISE\n  // Client retry key: the same key on the same report returns the already committed save\n  idempotencyKey String? @map(\"idempotency_key\") @db.VarChar(80)\n  createdAt DateTime @default(now()) @map(\"created_at\")\n\n  report Report @relation(fields: [reportId], references: [id], onDelete: Cascade)\n\n  @@unique([reportId, version])\n  @@unique([reportId, idempotencyKey])\n"
assert old in t
t = t.replace(old, new, 1)
open(p, 'w', encoding='utf-8', newline='').write(t.replace('\n', '\r\n'))
print('ok')

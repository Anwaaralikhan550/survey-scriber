import re
p = r'E:/survey-scriber/backend/prisma/schema.prisma'
s = open(p, encoding='utf-8', newline='').read()
assert '\r\n' in s
t = s.replace('\r\n', '\n')

# Survey relation
t = t.replace("  booking      Booking?\n\n  @@index([userId])\n  @@index([status])\n  @@index([type])",
              "  booking      Booking?\n  report       Report?\n\n  @@index([userId])\n  @@index([status])\n  @@index([type])", 1)
assert 'report       Report?' in t

# Media photo manager fields (spec section 9)
old = "  storagePath String    @map(\"storage_path\") @db.VarChar(500)\n  createdAt   DateTime  @default(now()) @map(\"created_at\")"
new = ("  storagePath String    @map(\"storage_path\") @db.VarChar(500)\n"
       "  // Photo manager (desktop editing): caption, order and report section of the photo\n"
       "  caption     String?   @db.VarChar(1000)\n"
       "  sortOrder   Int       @default(0) @map(\"sort_order\")\n"
       "  sectionKey  String?   @map(\"section_key\") @db.VarChar(100)\n"
       "  createdAt   DateTime  @default(now()) @map(\"created_at\")")
assert old in t
t = t.replace(old, new, 1)

# Audit entity types
t = t.replace("  REPORT_PDF\n  AUTH\n  WEBHOOK\n}", "  REPORT_PDF\n  AUTH\n  WEBHOOK\n  REPORT\n  EDIT_LINK\n}", 1)
assert 'EDIT_LINK' in t

open(p, 'w', encoding='utf-8', newline='').write(t.replace('\n', '\r\n'))
print('ok')

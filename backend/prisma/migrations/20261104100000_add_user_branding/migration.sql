-- The surveyor's own company, printed on their reports.
CREATE TABLE "user_branding" (
    "user_id" UUID NOT NULL,
    "company_name" VARCHAR(255),
    "company_logo" TEXT,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "user_branding_pkey" PRIMARY KEY ("user_id")
);

ALTER TABLE "user_branding" ADD CONSTRAINT "user_branding_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

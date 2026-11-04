-- Admins' edits to the emails. No row means the email goes out with its original wording.
CREATE TABLE "email_templates" (
    "key" VARCHAR(64) NOT NULL,
    "subject" VARCHAR(300) NOT NULL,
    "html" TEXT NOT NULL,
    "text" TEXT NOT NULL,
    "updated_by" VARCHAR(255),
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "email_templates_pkey" PRIMARY KEY ("key")
);

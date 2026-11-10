-- Sign-up now needs the emailed activation link. Everyone who already has an account keeps working.
ALTER TABLE "users" ADD COLUMN "activation_token_hash" VARCHAR(255);
ALTER TABLE "users" ADD COLUMN "activation_expires_at" TIMESTAMP(3);
UPDATE "users" SET "email_verified" = true WHERE "email_verified" = false;

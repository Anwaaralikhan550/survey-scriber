-- Settings changed by an admin. No row means the server's own value is used.
CREATE TABLE "app_settings" (
    "key" VARCHAR(64) NOT NULL,
    "value" VARCHAR(200) NOT NULL,
    "updated_by" VARCHAR(255),
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "app_settings_pkey" PRIMARY KEY ("key")
);

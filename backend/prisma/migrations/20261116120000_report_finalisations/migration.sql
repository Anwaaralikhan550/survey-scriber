-- Desktop editing D7: one row per edit cycle that ended in a final version; reopening keeps it and starts the next cycle.
CREATE TABLE "report_finalisations" (
    "id" UUID NOT NULL,
    "report_id" UUID NOT NULL,
    "cycle" INTEGER NOT NULL,
    "version" INTEGER NOT NULL,
    "finalised_by" UUID NOT NULL,
    "finalised_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "reopened_by" UUID,
    "reopened_at" TIMESTAMP(3),
    "reopen_reason" VARCHAR(500),

    CONSTRAINT "report_finalisations_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "report_finalisations_report_id_idx" ON "report_finalisations"("report_id");

CREATE UNIQUE INDEX "report_finalisations_report_id_cycle_key" ON "report_finalisations"("report_id", "cycle");

ALTER TABLE "report_finalisations" ADD CONSTRAINT "report_finalisations_report_id_fkey" FOREIGN KEY ("report_id") REFERENCES "reports"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- A cancelled booking no longer holds its time slot, so the same slot can be booked again.
DROP INDEX IF EXISTS "bookings_surveyor_id_date_start_time_key";

CREATE UNIQUE INDEX "bookings_surveyor_id_date_start_time_key"
  ON "bookings" ("surveyor_id", "date", "start_time")
  WHERE "status" <> 'CANCELLED';

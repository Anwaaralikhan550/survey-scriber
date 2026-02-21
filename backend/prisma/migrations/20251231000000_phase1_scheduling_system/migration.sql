-- Phase 1: Scheduling System
-- CreateEnum
CREATE TYPE "BookingStatus" AS ENUM ('PENDING', 'CONFIRMED', 'CANCELLED', 'COMPLETED');

-- CreateTable: SurveyorAvailability
CREATE TABLE "surveyor_availability" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "day_of_week" INTEGER NOT NULL,
    "start_time" VARCHAR(5) NOT NULL,
    "end_time" VARCHAR(5) NOT NULL,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "surveyor_availability_pkey" PRIMARY KEY ("id")
);

-- CreateTable: AvailabilityException
CREATE TABLE "availability_exceptions" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "date" DATE NOT NULL,
    "is_available" BOOLEAN NOT NULL DEFAULT false,
    "start_time" VARCHAR(5),
    "end_time" VARCHAR(5),
    "reason" VARCHAR(255),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "availability_exceptions_pkey" PRIMARY KEY ("id")
);

-- CreateTable: Booking
CREATE TABLE "bookings" (
    "id" UUID NOT NULL,
    "surveyor_id" UUID NOT NULL,
    "date" DATE NOT NULL,
    "start_time" VARCHAR(5) NOT NULL,
    "end_time" VARCHAR(5) NOT NULL,
    "status" "BookingStatus" NOT NULL DEFAULT 'PENDING',
    "client_name" VARCHAR(255),
    "client_phone" VARCHAR(50),
    "client_email" VARCHAR(255),
    "property_address" VARCHAR(500),
    "notes" TEXT,
    "created_by_id" UUID NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "bookings_pkey" PRIMARY KEY ("id")
);

-- CreateIndex: SurveyorAvailability
CREATE INDEX "surveyor_availability_user_id_idx" ON "surveyor_availability"("user_id");
CREATE INDEX "surveyor_availability_day_of_week_idx" ON "surveyor_availability"("day_of_week");
CREATE INDEX "surveyor_availability_is_active_idx" ON "surveyor_availability"("is_active");
CREATE UNIQUE INDEX "surveyor_availability_user_id_day_of_week_key" ON "surveyor_availability"("user_id", "day_of_week");

-- CreateIndex: AvailabilityException
CREATE INDEX "availability_exceptions_user_id_idx" ON "availability_exceptions"("user_id");
CREATE INDEX "availability_exceptions_date_idx" ON "availability_exceptions"("date");
CREATE UNIQUE INDEX "availability_exceptions_user_id_date_key" ON "availability_exceptions"("user_id", "date");

-- CreateIndex: Booking
CREATE INDEX "bookings_surveyor_id_idx" ON "bookings"("surveyor_id");
CREATE INDEX "bookings_date_idx" ON "bookings"("date");
CREATE INDEX "bookings_status_idx" ON "bookings"("status");
CREATE INDEX "bookings_created_by_id_idx" ON "bookings"("created_by_id");
CREATE INDEX "bookings_surveyor_id_date_idx" ON "bookings"("surveyor_id", "date");

-- AddForeignKey: SurveyorAvailability -> User
ALTER TABLE "surveyor_availability" ADD CONSTRAINT "surveyor_availability_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey: AvailabilityException -> User
ALTER TABLE "availability_exceptions" ADD CONSTRAINT "availability_exceptions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey: Booking -> User (surveyor)
ALTER TABLE "bookings" ADD CONSTRAINT "bookings_surveyor_id_fkey" FOREIGN KEY ("surveyor_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey: Booking -> User (creator)
ALTER TABLE "bookings" ADD CONSTRAINT "bookings_created_by_id_fkey" FOREIGN KEY ("created_by_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

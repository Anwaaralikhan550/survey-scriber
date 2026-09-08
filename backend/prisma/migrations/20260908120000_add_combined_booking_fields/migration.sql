-- Combined Create-Booking fields (App-Edit brief): survey type, job ref,
-- property details, structured address, access + estate-agent block.
ALTER TABLE "bookings"
  ADD COLUMN "survey_type" VARCHAR(20) NOT NULL DEFAULT 'home_survey',
  ADD COLUMN "job_ref" VARCHAR(100),
  ADD COLUMN "property_type" VARCHAR(50),
  ADD COLUMN "year_built" VARCHAR(20),
  ADD COLUMN "address_line" VARCHAR(255),
  ADD COLUMN "city" VARCHAR(120),
  ADD COLUMN "town" VARCHAR(120),
  ADD COLUMN "postcode" VARCHAR(20),
  ADD COLUMN "county" VARCHAR(120),
  ADD COLUMN "access_type" VARCHAR(20),
  ADD COLUMN "estate_agent_name" VARCHAR(255),
  ADD COLUMN "estate_agent_phone" VARCHAR(50),
  ADD COLUMN "estate_agent_address" VARCHAR(500),
  ADD COLUMN "estate_agent_notes" TEXT;

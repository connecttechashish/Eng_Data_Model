-------------------------
-- 7(a) Medallion layer mapping
-------------------------

-- Bronze (raw landed source):
--   bronze_airports          -- raw geography from source
--   bronze_aircraft          -- raw aircraft types
--   bronze_passengers        -- raw current passenger state
--   bronze_flights           -- raw flights
--   bronze_bookings          -- raw ticket sales feed
--   stg_passenger_updates    -- raw change feed from source

-- Silver (cleaned, conformed, modeled dimensions and facts):
--   dw.DimDate               -- conformed calendar dimension
--   dw.DimPassengerSCD       -- SCD Type 2 passenger dimension
--   dw.DimAirportSnowflake   -- normalized airport dimension
--   dw.DimCity               -- city dimension
--   dw.DimCountry            -- country dimension
--   dw.DimAircraft           -- aircraft dimension
--   dw.DimFlight             -- flight dimension

-- Gold (analytics-ready, partitioned star schema):
--   dw.FactTicketSales       -- partitioned fact at booking grain, feeding dashboards

-------------------------
-- 7(b) Data contract for bronze_bookings
-------------------------

-- Owner:
--   System: Vayu Air booking platform
--   Data owner: Revenue & Analytics team

-- Schema and types (bronze_bookings):
--   booking_id       INT           NOT NULL
--   passenger_id     INT           NOT NULL
--   flight_id        INT           NOT NULL
--   booking_date     DATE          NOT NULL
--   travel_date      DATE          NOT NULL
--   fare_class       VARCHAR(50)   NOT NULL
--   fare_amount      DECIMAL(18,2) NOT NULL
--   tax_amount       DECIMAL(18,2) NOT NULL
--   booking_status   VARCHAR(50)   NOT NULL
--   miles_earned     INT           NOT NULL

-- Allowed values:
--   fare_class:
--       'Economy', 'Premium Economy', 'Business', 'First'
--   booking_status:
--       'Confirmed', 'Cancelled', 'NoShow'

-- Freshness / delivery SLA:
--   - New records delivered as a daily batch by 03:00 local time.
--   - Late delivery beyond 06:00 must be communicated to downstream consumers.

-- Breaking change example:
--   - Renaming 'booking_status' to 'status', or removing 'fare_amount' column.
--   - Changing type of 'booking_id' from INT to VARCHAR.
--   These require coordination, versioning, and consumer migration.

-- Non-breaking change example:
--   - Adding a new nullable column 'promo_code' to bronze_bookings.
--   - Extending fare_class with a new value 'Ultra Economy' after prior notice.
--   These can be rolled out without breaking existing pipelines, provided defaults are handled.

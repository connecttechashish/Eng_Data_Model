-- Grain: One row per ticket booking (one passenger on one flight, per booking_id).

-- Dimension keys (who / what / where / when):
-- booking_id          -- degenerate key (can be carried on fact if needed)
-- passenger_id        -- FK to DimPassenger
-- flight_id           -- FK to DimFlight
-- booking_date        -- FK to DimDate (BookingDateKey)
-- travel_date         -- FK to DimDate (TravelDateKey)
-- fare_class          -- attribute on DimFlight or DimBookingClass
-- booking_status      -- attribute (used for filtering, not a measure)

-- Measures (numbers you would SUM):
-- fare_amount         -- additive
-- tax_amount          -- additive
-- miles_earned        -- additive (over correct grain)

-- Additive vs non-additive note:
-- fare_amount, tax_amount, miles_earned are additive across bookings.
-- A derived ratio like "average fare per passenger" is non-additive across dimensions.

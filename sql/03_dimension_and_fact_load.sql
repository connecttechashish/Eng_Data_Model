-------------------------
-- DimDate population
-------------------------
INSERT INTO dw.DimDate (DateKey, FullDate, DayNumber, MonthNumber, MonthName, YearNumber)
SELECT DISTINCT
    YEAR(d) * 10000 + MONTH(d) * 100 + DAY(d) AS DateKey,
    d AS FullDate,
    DAY(d) AS DayNumber,
    MONTH(d) AS MonthNumber,
    DATENAME(MONTH, d) AS MonthName,
    YEAR(d) AS YearNumber
FROM (
    SELECT booking_date AS d FROM bronze_bookings
    UNION
    SELECT travel_date FROM bronze_bookings
) AS src;
GO

-------------------------
-- DimPassenger population
-------------------------
INSERT INTO dw.DimPassenger (
    PassengerID,
    PassengerName,
    HomeAirportCode,
    FrequentFlyerTier,
    SignupDate
)
SELECT
    p.passenger_id,
    p.passenger_name,
    p.home_airport_code,
    p.frequent_flyer_tier,
    p.signup_date
FROM bronze_passengers p;
GO

-------------------------
-- DimAirport population
-------------------------
INSERT INTO dw.DimAirport (
    AirportCode,
    AirportName,
    City,
    Country,
    Region
)
SELECT
    a.airport_code,
    a.airport_name,
    a.city,
    a.country,
    a.region
FROM bronze_airports a;
GO

-------------------------
-- DimAircraft population
-------------------------
INSERT INTO dw.DimAircraft (
    AircraftCode,
    Model,
    Manufacturer,
    SeatCapacity
)
SELECT
    ac.aircraft_code,
    ac.model,
    ac.manufacturer,
    ac.seat_capacity
FROM bronze_aircraft ac;
GO

-------------------------
-- DimFlight population
-------------------------
INSERT INTO dw.DimFlight (
    FlightID,
    FlightNumber,
    OriginAirportCode,
    DestAirportCode,
    AircraftCode,
    FlightDate
)
SELECT
    f.flight_id,
    f.flight_number,
    f.origin_airport_code,
    f.dest_airport_code,
    f.aircraft_code,
    f.flight_date
FROM bronze_flights f;
GO

-------------------------
-- FactTicketSales population
-------------------------
INSERT INTO dw.FactTicketSales (
    BookingID,
    BookingDateKey,
    TravelDateKey,
    PassengerSK,
    FlightSK,
    FareAmount,
    TaxAmount,
    MilesEarned,
    FareClass,
    BookingStatus
)
SELECT
    b.booking_id,
    bd.DateKey AS BookingDateKey,
    td.DateKey AS TravelDateKey,
    dp.PassengerSK,
    df.FlightSK,
    b.fare_amount,
    b.tax_amount,
    b.miles_earned,
    b.fare_class,
    b.booking_status
FROM bronze_bookings b
JOIN dw.DimPassenger dp
    ON dp.PassengerID = b.passenger_id
JOIN dw.DimFlight df
    ON df.FlightID = b.flight_id
JOIN dw.DimDate bd
    ON bd.FullDate = b.booking_date
JOIN dw.DimDate td
    ON td.FullDate = b.travel_date;
GO

-- Verification: fact row count matches bronze_bookings
SELECT COUNT(*) AS FactTicketSalesRows FROM dw.FactTicketSales;
SELECT COUNT(*) AS BronzeBookingsRows FROM bronze_bookings;
GO

-- Verification: every fact row resolves to all dimensions (no NULL FKs)
SELECT
    SUM(CASE WHEN BookingDateKey IS NULL THEN 1 ELSE 0 END) AS NullBookingDateKey,
    SUM(CASE WHEN TravelDateKey IS NULL THEN 1 ELSE 0 END) AS NullTravelDateKey,
    SUM(CASE WHEN PassengerSK IS NULL THEN 1 ELSE 0 END) AS NullPassengerSK,
    SUM(CASE WHEN FlightSK IS NULL THEN 1 ELSE 0 END) AS NullFlightSK
FROM dw.FactTicketSales;
GO

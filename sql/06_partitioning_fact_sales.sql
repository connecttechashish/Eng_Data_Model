-------------------------
-- Partition function and scheme
-------------------------

-- Example: monthly boundaries for DateKey (adjust values to your data range)
CREATE PARTITION FUNCTION PF_FactTicketSales_DateKey (INT)
AS RANGE RIGHT FOR VALUES (
    20240131,
    20240229,
    20240331,
    20240430,
    20240531,
    20240630,
    20240731,
    20240831,
    20240930,
    20241031,
    20241130,
    20241231
);
GO

CREATE PARTITION SCHEME PS_FactTicketSales_DateKey
AS PARTITION PF_FactTicketSales_DateKey
ALL TO ([PRIMARY]);
GO

-------------------------
-- Recreate FactTicketSales on partition scheme
-------------------------

DROP TABLE IF EXISTS dw.FactTicketSales;
GO

CREATE TABLE dw.FactTicketSales (
    FactTicketSalesID BIGINT IDENTITY(1,1),
    BookingID         INT NOT NULL,
    BookingDateKey    INT NOT NULL,
    TravelDateKey     INT NOT NULL,
    PassengerSK       INT NOT NULL,
    FlightSK          INT NOT NULL,
    FareAmount        DECIMAL(18,2) NOT NULL,
    TaxAmount         DECIMAL(18,2) NOT NULL,
    MilesEarned       INT NOT NULL,
    FareClass         VARCHAR(50) NOT NULL,
    BookingStatus     VARCHAR(50) NOT NULL,

    CONSTRAINT PK_FactTicketSales
        PRIMARY KEY (BookingDateKey, FactTicketSalesID),

    CONSTRAINT FK_FactTicketSales_BookingDate
        FOREIGN KEY (BookingDateKey) REFERENCES dw.DimDate(DateKey),

    CONSTRAINT FK_FactTicketSales_TravelDate
        FOREIGN KEY (TravelDateKey) REFERENCES dw.DimDate(DateKey),

    CONSTRAINT FK_FactTicketSales_Passenger
        FOREIGN KEY (PassengerSK) REFERENCES dw.DimPassengerSCD(PassengerSK),

    CONSTRAINT FK_FactTicketSales_Flight
        FOREIGN KEY (FlightSK) REFERENCES dw.DimFlight(FlightSK)
)
ON PS_FactTicketSales_DateKey (BookingDateKey);
GO


-- Reload fact (same logic as Question 3, but using SCD Passenger)
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
JOIN dw.DimPassengerSCD dp
    ON dp.PassengerID = b.passenger_id
   AND dp.IsCurrent = 1
JOIN dw.DimFlight df
    ON df.FlightID = b.flight_id
JOIN dw.DimDate bd
    ON bd.FullDate = b.booking_date
JOIN dw.DimDate td
    ON td.FullDate = b.travel_date;
GO

-------------------------
-- Query 1: filter on partition key (BookingDateKey)
-------------------------
-- Turn on Actual Execution Plan in SSMS and capture screenshot showing small partition count.

SELECT
    BookingDateKey,
    SUM(FareAmount) AS TotalFare,
    SUM(TaxAmount)  AS TotalTax
FROM dw.FactTicketSales
WHERE BookingDateKey BETWEEN 20240501 AND 20240531
GROUP BY BookingDateKey;
GO

-------------------------
-- Query 2: filter on non-partition column (FareClass)
-------------------------
-- Capture screenshot showing all partitions scanned (no pruning).

SELECT
    FareClass,
    SUM(FareAmount) AS TotalFare,
    SUM(TaxAmount)  AS TotalTax
FROM dw.FactTicketSales
WHERE FareClass = 'Business'
GROUP BY FareClass;
GO

-- Explanation note:
-- Query 1 filters on BookingDateKey, the partition key, so SQL Server can prune
-- to only the relevant partitions (Actual Partition Count is small).
-- Query 2 filters on FareClass, which is not the partition key, so the engine
-- must scan all partitions (Actual Partition Count equals total partitions).

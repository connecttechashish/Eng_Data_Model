CREATE SCHEMA dw;
GO

-------------------------
-- Dimension: Date
-------------------------
CREATE TABLE dw.DimDate (
    DateKey        INT           NOT NULL PRIMARY KEY, -- yyyymmdd
    FullDate       DATE          NOT NULL,
    DayNumber      TINYINT       NOT NULL,
    MonthNumber    TINYINT       NOT NULL,
    MonthName      VARCHAR(20)   NOT NULL,
    YearNumber     INT           NOT NULL
);
GO

-------------------------
-- Dimension: Passenger
-------------------------
CREATE TABLE dw.DimPassenger (
    PassengerSK          INT IDENTITY(1,1) PRIMARY KEY,
    PassengerID          INT         NOT NULL, -- business key
    PassengerName        VARCHAR(200) NOT NULL,
    HomeAirportCode      CHAR(3)     NOT NULL,
    FrequentFlyerTier    VARCHAR(50) NOT NULL,
    SignupDate           DATE        NOT NULL,
    CONSTRAINT UQ_DimPassenger_BK UNIQUE (PassengerID)
);
GO

-------------------------
-- Dimension: Airport
-------------------------
CREATE TABLE dw.DimAirport (
    AirportSK      INT IDENTITY(1,1) PRIMARY KEY,
    AirportCode    CHAR(3)      NOT NULL, -- business key
    AirportName    VARCHAR(200) NOT NULL,
    City           VARCHAR(200) NOT NULL,
    Country        VARCHAR(200) NOT NULL,
    Region         VARCHAR(200) NOT NULL,
    CONSTRAINT UQ_DimAirport_BK UNIQUE (AirportCode)
);
GO

-------------------------
-- Dimension: Aircraft
-------------------------
CREATE TABLE dw.DimAircraft (
    AircraftSK     INT IDENTITY(1,1) PRIMARY KEY,
    AircraftCode   VARCHAR(50)  NOT NULL, -- business key
    Model          VARCHAR(100) NOT NULL,
    Manufacturer   VARCHAR(100) NOT NULL,
    SeatCapacity   INT          NOT NULL,
    CONSTRAINT UQ_DimAircraft_BK UNIQUE (AircraftCode)
);
GO

-------------------------
-- Dimension: Flight
-------------------------
CREATE TABLE dw.DimFlight (
    FlightSK            INT IDENTITY(1,1) PRIMARY KEY,
    FlightID            INT          NOT NULL, -- business key
    FlightNumber        VARCHAR(50)  NOT NULL,
    OriginAirportCode   CHAR(3)      NOT NULL,
    DestAirportCode     CHAR(3)      NOT NULL,
    AircraftCode        VARCHAR(50)  NOT NULL,
    FlightDate          DATE         NOT NULL,
    CONSTRAINT UQ_DimFlight_BK UNIQUE (FlightID)
);
GO

-------------------------
-- Fact: Ticket Sales
-------------------------
CREATE TABLE dw.FactTicketSales (
    FactTicketSalesID   BIGINT IDENTITY(1,1) PRIMARY KEY,

    -- Degenerate key
    BookingID           INT         NOT NULL,

    -- Foreign keys to dimensions
    BookingDateKey      INT         NOT NULL,
    TravelDateKey       INT         NOT NULL,
    PassengerSK         INT         NOT NULL,
    FlightSK            INT         NOT NULL,

    -- Additive measures
    FareAmount          DECIMAL(18,2) NOT NULL,
    TaxAmount           DECIMAL(18,2) NOT NULL,
    MilesEarned         INT           NOT NULL,

    -- Attributes used for filtering (not measures)
    FareClass           VARCHAR(50)   NOT NULL,
    BookingStatus       VARCHAR(50)   NOT NULL,

    CONSTRAINT FK_FactTicketSales_BookingDate
        FOREIGN KEY (BookingDateKey) REFERENCES dw.DimDate(DateKey),

    CONSTRAINT FK_FactTicketSales_TravelDate
        FOREIGN KEY (TravelDateKey) REFERENCES dw.DimDate(DateKey),

    CONSTRAINT FK_FactTicketSales_Passenger
        FOREIGN KEY (PassengerSK) REFERENCES dw.DimPassenger(PassengerSK),

    CONSTRAINT FK_FactTicketSales_Flight
        FOREIGN KEY (FlightSK) REFERENCES dw.DimFlight(FlightSK)
);
GO

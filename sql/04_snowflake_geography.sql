-------------------------
-- Snowflaked geography
-------------------------

CREATE TABLE dw.DimCountry (
    CountrySK   INT IDENTITY(1,1) PRIMARY KEY,
    CountryName VARCHAR(200) NOT NULL,
    Region      VARCHAR(200) NOT NULL,
    CONSTRAINT UQ_DimCountry UNIQUE (CountryName)
);
GO

CREATE TABLE dw.DimCity (
    CitySK      INT IDENTITY(1,1) PRIMARY KEY,
    CityName    VARCHAR(200) NOT NULL,
    CountrySK   INT          NOT NULL,
    CONSTRAINT UQ_DimCity UNIQUE (CityName, CountrySK),
    CONSTRAINT FK_DimCity_Country FOREIGN KEY (CountrySK)
        REFERENCES dw.DimCountry(CountrySK)
);
GO

CREATE TABLE dw.DimAirportSnowflake (
    AirportSK   INT IDENTITY(1,1) PRIMARY KEY,
    AirportCode CHAR(3)      NOT NULL,
    AirportName VARCHAR(200) NOT NULL,
    CitySK      INT          NOT NULL,
    CONSTRAINT UQ_DimAirportSnowflake UNIQUE (AirportCode),
    CONSTRAINT FK_DimAirportSnowflake_City FOREIGN KEY (CitySK)
        REFERENCES dw.DimCity(CitySK)
);
GO

-------------------------
-- Load Country
-------------------------
INSERT INTO dw.DimCountry (CountryName, Region)
SELECT DISTINCT
    country,
    region
FROM bronze_airports;
GO

-------------------------
-- Load City
-------------------------
INSERT INTO dw.DimCity (CityName, CountrySK)
SELECT DISTINCT
    a.city,
    c.CountrySK
FROM bronze_airports a
JOIN dw.DimCountry c
    ON c.CountryName = a.country;
GO

-------------------------
-- Load AirportSnowflake
-------------------------
INSERT INTO dw.DimAirportSnowflake (
    AirportCode,
    AirportName,
    CitySK
)
SELECT DISTINCT
    a.airport_code,
    a.airport_name,
    ci.CitySK
FROM bronze_airports a
JOIN dw.DimCity ci
    ON ci.CityName = a.city
    JOIN dw.DimCountry c
        ON c.CountrySK = ci.CountrySK
        AND c.CountryName = a.country;
GO

-- Example query: resolve airport up to country
SELECT
    a.AirportCode,
    a.AirportName,
    ci.CityName,
    co.CountryName,
    co.Region
FROM dw.DimAirportSnowflake a
JOIN dw.DimCity ci
    ON ci.CitySK = a.CitySK
JOIN dw.DimCountry co
    ON co.CountrySK = ci.CountrySK;
GO

-- Trade-off note:
-- Snowflaking reduces repeated city/country values and improves data quality,
-- at the cost of more joins and slightly more complex queries.

-------------------------
-- Rebuild DimPassenger as SCD Type 2
-------------------------

DROP TABLE IF EXISTS dw.DimPassengerSCD;
GO

CREATE TABLE dw.DimPassengerSCD (
    PassengerSK          INT IDENTITY(1,1) PRIMARY KEY,
    PassengerID          INT          NOT NULL, -- business key
    PassengerName        VARCHAR(200) NOT NULL,
    HomeAirportCode      CHAR(3)      NOT NULL,
    FrequentFlyerTier    VARCHAR(50)  NOT NULL,
    SignupDate           DATE         NOT NULL,

    IsCurrent            BIT          NOT NULL,
    EffectiveFrom        DATE         NOT NULL,
    EffectiveTo          DATE         NULL,

    CONSTRAINT UQ_DimPassengerSCD_BK_Current
        UNIQUE (PassengerID, IsCurrent)
);
GO

-------------------------
-- Initial load from bronze_passengers
-------------------------
INSERT INTO dw.DimPassengerSCD (
    PassengerID,
    PassengerName,
    HomeAirportCode,
    FrequentFlyerTier,
    SignupDate,
    IsCurrent,
    EffectiveFrom,
    EffectiveTo
)
SELECT
    p.passenger_id,
    p.passenger_name,
    p.home_airport_code,
    p.frequent_flyer_tier,
    p.signup_date,
    1 AS IsCurrent,
    CAST(GETDATE() AS DATE) AS EffectiveFrom,
    NULL AS EffectiveTo
FROM bronze_passengers p;
GO

-------------------------
-- Step 1: MERGE to expire changed and insert brand-new passengers
-------------------------
MERGE dw.DimPassengerSCD AS tgt
USING stg_passenger_updates AS src
    ON tgt.PassengerID = src.passenger_id
   AND tgt.IsCurrent = 1
WHEN MATCHED AND (
        tgt.HomeAirportCode <> src.home_airport_code
     OR tgt.FrequentFlyerTier <> src.frequent_flyer_tier
    )
THEN
    UPDATE SET
        tgt.IsCurrent     = 0,
        tgt.EffectiveTo   = CAST(GETDATE() AS DATE)
WHEN NOT MATCHED BY TARGET
THEN
    INSERT (
        PassengerID,
        PassengerName,
        HomeAirportCode,
        FrequentFlyerTier,
        SignupDate,
        IsCurrent,
        EffectiveFrom,
        EffectiveTo
    )
    VALUES (
        src.passenger_id,
        src.passenger_name,
        src.home_airport_code,
        src.frequent_flyer_tier,
        CAST(GETDATE() AS DATE), -- signup_date for new
        1,
        CAST(GETDATE() AS DATE),
        NULL
    );
GO

-------------------------
-- Step 2: INSERT new current versions for expired passengers
-------------------------
INSERT INTO dw.DimPassengerSCD (
    PassengerID,
    PassengerName,
    HomeAirportCode,
    FrequentFlyerTier,
    SignupDate,
    IsCurrent,
    EffectiveFrom,
    EffectiveTo
)
SELECT
    u.passenger_id,
    u.passenger_name,
    u.home_airport_code,
    u.frequent_flyer_tier,
    COALESCE(p.SignupDate, CAST(GETDATE() AS DATE)) AS SignupDate,
    1 AS IsCurrent,
    CAST(GETDATE() AS DATE) AS EffectiveFrom,
    NULL AS EffectiveTo
FROM stg_passenger_updates u
JOIN dw.DimPassengerSCD p
    ON p.PassengerID = u.passenger_id
   AND p.IsCurrent = 0
   AND p.EffectiveTo = CAST(GETDATE() AS DATE);
GO

-- Verification: a passenger who changed shows two versions
SELECT *
FROM dw.DimPassengerSCD
WHERE PassengerID IN (
    SELECT passenger_id
    FROM stg_passenger_updates
)
ORDER BY PassengerID, EffectiveFrom;
GO

-- Expected pattern:
-- - Old version: IsCurrent = 0, EffectiveTo set
-- - New version: IsCurrent = 1, EffectiveFrom = change date, EffectiveTo = NULL

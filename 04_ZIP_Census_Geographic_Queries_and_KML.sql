
USE SQLBook;
GO


/* =========================================================
   Query 1
   Goal: Show highly populated ZIP codes to identify
   major population centers across geographic locations.
   ========================================================= */

SELECT
    Longitude,
    Latitude,
    TotPop AS Population
FROM dbo.ZipCensus
WHERE Latitude BETWEEN 24 AND 50
    AND Longitude BETWEEN -125 AND -65
    AND TotPop > 50000
ORDER BY Population DESC;


/* =========================================================
   Query 2
   Goal: Show ZIP codes with median household income above
   $100,000 to identify higher-income locations.
   ========================================================= */

SELECT
    Longitude,
    Latitude,
    MedianHHInc AS MedianIncome
FROM dbo.ZipCensus
WHERE Latitude BETWEEN 24 AND 50
    AND Longitude BETWEEN -125 AND -65
    AND MedianHHInc > 100000
ORDER BY MedianIncome DESC;


/* =========================================================
   Query 3
   Goal: Show ZIP codes with more than 20,000 households
   to identify locations with larger household markets.
   ========================================================= */

SELECT
    Longitude,
    Latitude,
    TotHHs AS Households
FROM dbo.ZipCensus
WHERE Latitude BETWEEN 24 AND 50
    AND Longitude BETWEEN -125 AND -65
    AND TotHHs > 20000
ORDER BY Households DESC;


/* =========================================================
   Query 4
   Goal: Show geographic locations with high poverty rates
   to identify areas with greater economic hardship.
   ========================================================= */

SELECT
    Longitude,
    Latitude,
    pctPoor AS PovertyRate
FROM dbo.ZipCensus
WHERE Latitude BETWEEN 24 AND 50
    AND Longitude BETWEEN -125 AND -65
    AND pctPoor >= 0.25
ORDER BY PovertyRate DESC;


/* =========================================================
   Query 5
   Goal: Show locations where more than 20% of housing
   units are vacant and compare the number of vacant units.
   ========================================================= */

SELECT
    Longitude,
    Latitude,
    VacHUs AS VacantHousingUnits
FROM dbo.ZipCensus
WHERE Latitude BETWEEN 24 AND 50
    AND Longitude BETWEEN -125 AND -65
    AND pctVacHUs > 0.20
ORDER BY VacantHousingUnits DESC;


/* =========================================================
   Query 6
   Goal: Show ZIP codes with high median home values
   to identify expensive housing markets geographically.
   ========================================================= */

SELECT
    Longitude,
    Latitude,
    MedianHValue AS MedianHomeValue
FROM dbo.ZipCensus
WHERE Latitude BETWEEN 24 AND 50
    AND Longitude BETWEEN -125 AND -65
    AND MedianHValue >= 500000
ORDER BY MedianHomeValue DESC;


/* =========================================================
   Query 7
   Goal: Show ZIP codes with long average commute times
   to identify areas where residents spend more time
   commuting to work.
   ========================================================= */

SELECT
    Longitude,
    Latitude,
    AvgCommute AS AverageCommuteTime
FROM dbo.ZipCensus
WHERE Latitude BETWEEN 24 AND 50
    AND Longitude BETWEEN -125 AND -65
    AND AvgCommute >= 35
ORDER BY AverageCommuteTime DESC;


/* =========================================================
   Query 8
   Goal: Show ZIP codes with high levels of college
   education to identify highly educated locations.
   ========================================================= */

SELECT
    Longitude,
    Latitude,
    pctBachelorsormore AS BachelorsOrMoreRate
FROM dbo.ZipCensus
WHERE Latitude BETWEEN 24 AND 50
    AND Longitude BETWEEN -125 AND -65
    AND pctBachelorsormore >= 0.50
ORDER BY BachelorsOrMoreRate DESC;


/* =========================================================
   Query 9
   Goal: Find the ZIP code with the highest unemployment
   rate in each state and compare these locations.
   ========================================================= */

WITH UnemploymentRanking AS
(
    SELECT
        zcta5,
        Stab,
        Longitude,
        Latitude,
        pctUnemployedCLF,
        ROW_NUMBER() OVER
        (
            PARTITION BY Stab
            ORDER BY pctUnemployedCLF DESC
        ) AS RowNumber
    FROM dbo.ZipCensus
    WHERE Latitude BETWEEN 24 AND 50
        AND Longitude BETWEEN -125 AND -65
        AND pctUnemployedCLF IS NOT NULL
)

SELECT
    Longitude,
    Latitude,
    pctUnemployedCLF AS UnemploymentRate
FROM UnemploymentRanking
WHERE RowNumber = 1
ORDER BY UnemploymentRate DESC;

/* =========================================================
   Query 10
   Goal: Show ZIP codes with high median gross rent
   to identify geographic areas with expensive rental
   housing.
   ========================================================= */

SELECT
    Longitude,
    Latitude,
    MedianGrossRent
FROM dbo.ZipCensus
WHERE Latitude BETWEEN 24 AND 50
    AND Longitude BETWEEN -125 AND -65
    AND MedianGrossRent >= 1500
ORDER BY MedianGrossRent DESC;

/* =========================================================
   KML Visualization
   Goal: Generate KML Placemark data for the 2,000 ZIP codes
   with the highest housing vacancy rates among locations
   where more than 20% of housing units are vacant.
   ========================================================= */

SELECT TOP 2000
    CONCAT(
        '<Placemark>',
            '<name>ZIP ', zcta5, ' - ', Stab, '</name>',
            '<description>',
                'Vacant Housing Units: ', VacHUs,
                ' | Vacancy Rate: ', FORMAT(pctVacHUs, 'P1'),
            '</description>',
            '<Point>',
                '<coordinates>',
                    Longitude, ',', Latitude, ',0',
                '</coordinates>',
            '</Point>',
        '</Placemark>'
    ) AS [KML Placemark]
FROM dbo.ZipCensus
WHERE Latitude BETWEEN 24 AND 50
    AND Longitude BETWEEN -125 AND -65
    AND pctVacHUs > 0.20
ORDER BY pctVacHUs DESC, VacHUs DESC;






USE SQLBook;
GO


/* =========================================================
   Function 1 - ZIP Codes by Population and Household Size

   Purpose:
   Returns ZIP codes that meet both a minimum population
   and a minimum average household size.

   Arguments:
   @minimumPopulation INT = minimum total population.
   @minimumHouseholdSize FLOAT = minimum average household size.

   Example:
   Pass 50000 and 2.5 to analyze ZIP codes with at least
   50,000 people and an average household size of 2.5 or more.
   ========================================================= */

CREATE OR ALTER FUNCTION dbo.GetPopulationAndHouseholdSize
(
    @minimumPopulation INT,
    @minimumHouseholdSize FLOAT
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        [zcta5] AS [ZipCode],
        [ZIPName],
        [Stab] AS [State],
        [TotPop] AS [Population],
        [AvgHHSize] AS [AverageHouseholdSize]
    FROM [SQLBook].[dbo].[ZipCensus]
    WHERE [TotPop] >= @minimumPopulation
      AND [AvgHHSize] >= @minimumHouseholdSize
);
GO

SELECT *
FROM SQLBook.dbo.GetPopulationAndHouseholdSize
(
    50000,
    2.5
);
GO


/* =========================================================
   Function 2 - Housing Affordability

   Purpose:
   Compares household income with home value and returns
   ZIP codes whose home-value-to-income ratio is no greater
   than the ratio passed to the function.

   Argument:
   @maximumRatio FLOAT = maximum allowed ratio between
   median home value and median household income.

   Example:
   Pass 4.0 to return ZIP codes where median home value is
   no more than four times median household income.
   ========================================================= */

CREATE OR ALTER FUNCTION dbo.GetHousingAffordability
(
    @maximumRatio FLOAT
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        [zcta5] AS [ZipCode],
        [ZIPName],
        [Stab] AS [State],
        [MedianHHInc] AS [MedianHouseholdIncome],
        [MedianHValue] AS [MedianHomeValue],
        CAST([MedianHValue] AS FLOAT) /
            NULLIF([MedianHHInc], 0) AS [HomeValueIncomeRatio]
    FROM [SQLBook].[dbo].[ZipCensus]
    WHERE CAST([MedianHValue] AS FLOAT) /
              NULLIF([MedianHHInc], 0) <= @maximumRatio
);
GO

SELECT *
FROM SQLBook.dbo.GetHousingAffordability
(
    4.0
);
GO


/* =========================================================
   Function 3 - Education and Income

   Purpose:
   Returns ZIP codes that meet both a minimum bachelor's
   degree rate and a minimum median household income.

   Arguments:
   @minimumEducationRate FLOAT = minimum proportion with
   a bachelor's degree or higher.
   @minimumIncome INT = minimum median household income.

   Example:
   Pass 0.40 and 75000 to find locations where at least
   40 percent have a bachelor's degree or higher and median
   household income is at least $75,000.
   ========================================================= */

CREATE OR ALTER FUNCTION dbo.GetEducationAndIncome
(
    @minimumEducationRate FLOAT,
    @minimumIncome INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        [zcta5] AS [ZipCode],
        [ZIPName],
        [Stab] AS [State],
        [pctBachelorsormore] AS [BachelorsOrMoreRate],
        [MedianHHInc] AS [MedianHouseholdIncome]
    FROM [SQLBook].[dbo].[ZipCensus]
    WHERE [pctBachelorsormore] >= @minimumEducationRate
      AND [MedianHHInc] >= @minimumIncome
);
GO

SELECT *
FROM SQLBook.dbo.GetEducationAndIncome
(
    0.40,
    75000
);
GO


/* =========================================================
   Function 4 - Housing Vacancy Impact

   Purpose:
   Returns ZIP codes where both the vacancy rate and the
   number of vacant housing units meet limits supplied
   to the function.

   Arguments:
   @minimumVacancyRate FLOAT = minimum housing vacancy rate.
   @minimumVacantUnits INT = minimum number of vacant units.

   Example:
   Pass 0.15 and 1000 to find ZIP codes with at least a
   15 percent vacancy rate and at least 1,000 vacant units.
   ========================================================= */

CREATE OR ALTER FUNCTION dbo.GetHousingVacancyImpact
(
    @minimumVacancyRate FLOAT,
    @minimumVacantUnits INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        [zcta5] AS [ZipCode],
        [ZIPName],
        [Stab] AS [State],
        [VacHUs] AS [VacantHousingUnits],
        [pctVacHUs] AS [VacancyRate]
    FROM [SQLBook].[dbo].[ZipCensus]
    WHERE [pctVacHUs] >= @minimumVacancyRate
      AND [VacHUs] >= @minimumVacantUnits
);
GO

SELECT *
FROM SQLBook.dbo.GetHousingVacancyImpact
(
    0.15,
    1000
);
GO


/* =========================================================
   Function 5 - Economic Hardship

   Purpose:
   Returns ZIP codes that meet both a minimum poverty rate
   and a minimum unemployment rate.

   Arguments:
   @minimumPovertyRate FLOAT = minimum poverty proportion.
   @minimumUnemploymentRate FLOAT = minimum unemployment
   proportion.

   Example:
   Pass 0.20 and 0.08 to find locations with at least
   20 percent poverty and 8 percent unemployment.
   ========================================================= */

CREATE OR ALTER FUNCTION dbo.GetEconomicHardship
(
    @minimumPovertyRate FLOAT,
    @minimumUnemploymentRate FLOAT
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        [zcta5] AS [ZipCode],
        [ZIPName],
        [Stab] AS [State],
        [pctPoor] AS [PovertyRate],
        [pctUnemployedCLF] AS [UnemploymentRate]
    FROM [SQLBook].[dbo].[ZipCensus]
    WHERE [pctPoor] >= @minimumPovertyRate
      AND [pctUnemployedCLF] >= @minimumUnemploymentRate
);
GO

SELECT *
FROM SQLBook.dbo.GetEconomicHardship
(
    0.20,
    0.08
);
GO


/* =========================================================
   Function 6 - Commute and Income

   Purpose:
   Returns ZIP codes based on both average commute time
   and median household income.

   Arguments:
   @maximumCommute FLOAT = maximum average commute time.
   @minimumIncome INT = minimum median household income.

   Example:
   Pass 30 and 70000 to find locations with an average
   commute of no more than 30 minutes and median household
   income of at least $70,000.
   ========================================================= */

CREATE OR ALTER FUNCTION dbo.GetCommuteAndIncome
(
    @maximumCommute FLOAT,
    @minimumIncome INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        [zcta5] AS [ZipCode],
        [ZIPName],
        [Stab] AS [State],
        [AvgCommute] AS [AverageCommute],
        [MedianHHInc] AS [MedianHouseholdIncome]
    FROM [SQLBook].[dbo].[ZipCensus]
    WHERE [AvgCommute] <= @maximumCommute
      AND [MedianHHInc] >= @minimumIncome
);
GO

SELECT *
FROM SQLBook.dbo.GetCommuteAndIncome
(
    30,
    70000
);
GO


/* =========================================================
   Function 7 - Rental Cost Compared with Income

   Purpose:
   Calculates annual median rent as a percentage of median
   household income and returns ZIP codes that do not exceed
   the percentage supplied to the function.

   Argument:
   @maximumRentShare FLOAT = maximum annual rent-to-income
   proportion.

   Example:
   Pass 0.30 to find ZIP codes where estimated annual median
   rent is no more than 30 percent of median household income.
   ========================================================= */

CREATE OR ALTER FUNCTION dbo.GetRentToIncome
(
    @maximumRentShare FLOAT
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        [zcta5] AS [ZipCode],
        [ZIPName],
        [Stab] AS [State],
        [MedianGrossRent],
        [MedianHHInc] AS [MedianHouseholdIncome],
        ([MedianGrossRent] * 12.0) /
            NULLIF([MedianHHInc], 0) AS [RentIncomeRatio]
    FROM [SQLBook].[dbo].[ZipCensus]
    WHERE ([MedianGrossRent] * 12.0) /
              NULLIF([MedianHHInc], 0) <= @maximumRentShare
);
GO

SELECT *
FROM SQLBook.dbo.GetRentToIncome
(
    0.30
);
GO


/* =========================================================
   Function 8 - Customer Purchase Activity

   Purpose:
   Returns customers who have placed at least the specified
   number of orders.

   Argument:
   @minimumOrders INT = minimum number of orders a customer
   must have placed.

   Example:
   Pass 5 to return customers who have placed at least
   five orders.
   ========================================================= */

CREATE OR ALTER FUNCTION dbo.GetCustomersByOrderActivity
(
    @minimumOrders INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        [CustomerId],
        COUNT(*) AS [NumberOfOrders]
    FROM [SQLBook].[dbo].[Orders]
    WHERE [CustomerId] <> 0
    GROUP BY [CustomerId]
    HAVING COUNT(*) >= @minimumOrders
);
GO

SELECT *
FROM SQLBook.dbo.GetCustomersByOrderActivity
(
    5
);
GO


/* =========================================================
   Function 9 - Customer Order History

   Purpose:
   Returns all orders belonging to the customer whose ID
   is passed to the function.

   Argument:
   @customerId INT = CustomerId to search for.

   Example:
   Pass 100 to return the order history for CustomerId 100.
   ========================================================= */

CREATE OR ALTER FUNCTION dbo.GetCustomerOrderHistory
(
    @customerId INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        [OrderId],
        [CustomerId],
        [OrderDate],
        [ZipCode],
        [State]
    FROM [SQLBook].[dbo].[Orders]
    WHERE [CustomerId] = @customerId
);
GO

SELECT *
FROM SQLBook.dbo.GetCustomerOrderHistory
(
    100
);
GO


/* =========================================================
   Function 10 - Geographic Market Size

   Purpose:
   Returns ZIP codes whose population density meets the
   minimum density supplied to the function.

   Argument:
   @minimumDensity FLOAT = minimum number of people per
   square mile.

   Example:
   Pass 5000 to return ZIP codes with at least 5,000
   people per square mile.
   ========================================================= */

CREATE OR ALTER FUNCTION dbo.GetZipsByPopulationDensity
(
    @minimumDensity FLOAT
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        [zcta5] AS [ZipCode],
        [ZIPName],
        [Stab] AS [State],
        [TotPop] AS [Population],
        [LandSQMI],
        CAST([TotPop] AS FLOAT) /
            NULLIF([LandSQMI], 0) AS [PopulationDensity]
    FROM [SQLBook].[dbo].[ZipCensus]
    WHERE CAST([TotPop] AS FLOAT) /
              NULLIF([LandSQMI], 0) >= @minimumDensity
);
GO

SELECT *
FROM SQLBook.dbo.GetZipsByPopulationDensity
(
    5000
);
GO
USE SQLBook;
GO

/* Query 1 - Cursor
   Find the month with the highest revenue in each year.
   The cursor processes the yearly and monthly sales one row at a time
   and keeps the highest-revenue month for each year.
*/

DECLARE @year INT;
DECLARE @prevYear INT = 0;
DECLARE @month INT;
DECLARE @revenue MONEY;

DECLARE @BestMonths TABLE
(
    SalesYear INT,
    BestMonth INT,
    TotalRevenue MONEY
);

DECLARE revenue_cursor CURSOR FOR
SELECT
    YEAR(OrderDate),
    MONTH(OrderDate),
    SUM(TotalPrice)
FROM dbo.Orders
GROUP BY
    YEAR(OrderDate),
    MONTH(OrderDate)
ORDER BY
    YEAR(OrderDate),
    SUM(TotalPrice) DESC;

OPEN revenue_cursor;

FETCH NEXT FROM revenue_cursor
INTO @year, @month, @revenue;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF (@prevYear != @year)
        INSERT INTO @BestMonths
        VALUES (@year, @month, @revenue);

    SET @prevYear = @year;

    FETCH NEXT FROM revenue_cursor
    INTO @year, @month, @revenue;
END;

CLOSE revenue_cursor;
DEALLOCATE revenue_cursor;

SELECT
    SalesYear,
    DATENAME(MONTH, DATEFROMPARTS(SalesYear, BestMonth, 1)) AS BestMonth,
    TotalRevenue
FROM @BestMonths
ORDER BY SalesYear;



/* Query 2 - FIRST_VALUE
   Solve the same problem as Query 1 using the declarative approach
   instead of a cursor.
   Find the month with the highest revenue in each year using
   the FIRST_VALUE window function.
*/

WITH BestRevenueCTE
    (SalesYear, SalesMonth, MonthlyRevenue, FirstRevenue)
AS
(
    SELECT
        YEAR(OrderDate),
        MONTH(OrderDate),
        SUM(TotalPrice),
        FIRST_VALUE(SUM(TotalPrice)) OVER
        (
            PARTITION BY YEAR(OrderDate)
            ORDER BY SUM(TotalPrice) DESC
        )
    FROM dbo.Orders
    GROUP BY
        YEAR(OrderDate),
        MONTH(OrderDate)
)

SELECT
    SalesYear,
    DATENAME(MONTH, DATEFROMPARTS(SalesYear, SalesMonth, 1)) AS BestMonth,
    MonthlyRevenue AS TotalRevenue
FROM BestRevenueCTE
WHERE MonthlyRevenue = FirstRevenue
ORDER BY SalesYear;

/* Query 3 - COUNT
   Count the number of orders for each payment type.
   This helps identify which payment methods customers use most often.
*/

SELECT
    PaymentType,
    COUNT(*) AS NumberOfOrders
FROM dbo.Orders
GROUP BY PaymentType
ORDER BY NumberOfOrders DESC;


/* Query 4 - ROW_NUMBER
   Rank products based on how many times they appear in orders.
   This helps identify the top 10 most frequently ordered products.
*/

WITH ProductRankCTE AS
(
    SELECT
        ProductId,
        COUNT(*) AS NumberOfOrders,
        ROW_NUMBER() OVER
        (
            ORDER BY COUNT(*) DESC
        ) AS ProductRank
    FROM dbo.OrderLines
    GROUP BY ProductId
)

SELECT
    ProductId,
    NumberOfOrders,
    ProductRank
FROM ProductRankCTE
WHERE ProductRank <= 10
ORDER BY ProductRank;



/* Query 5 - NTILE
   Divide ZIP Codes into four groups based on their total revenue.
   Group 1 contains the highest-revenue ZIP Codes and
   Group 4 contains the lowest-revenue ZIP Codes.
*/

WITH ZipRevenueCTE AS
(
    SELECT
        ZipCode,
        SUM(TotalPrice) AS TotalRevenue,
        NTILE(4) OVER
        (
            ORDER BY SUM(TotalPrice) DESC
        ) AS RevenueGroup
    FROM dbo.Orders
    WHERE ZipCode IS NOT NULL
    GROUP BY ZipCode
)

SELECT
    RevenueGroup,
    CASE
        WHEN RevenueGroup = 1 THEN 'Highest Revenue'
        WHEN RevenueGroup = 2 THEN 'High-Medium Revenue'
        WHEN RevenueGroup = 3 THEN 'Low-Medium Revenue'
        WHEN RevenueGroup = 4 THEN 'Lowest Revenue'
    END AS RevenueCategory,
    SUM(TotalRevenue) AS TotalRevenue
FROM ZipRevenueCTE
GROUP BY RevenueGroup
ORDER BY RevenueGroup;


/* Query 6 - VAR
   Calculate the variance of order values for each payment type.
   This shows how much order values vary within each payment method.
*/

SELECT
    PaymentType,
    VAR(TotalPrice) AS OrderValueVariance
FROM dbo.Orders
WHERE PaymentType IS NOT NULL
GROUP BY PaymentType
ORDER BY OrderValueVariance DESC;


/* Query 7 - STDEV
   Find the 10 states with the highest variation in order size.
   Standard deviation shows how much the number of units per order varies.
*/

SELECT TOP 10
    State,
    STDEV(NumUnits) AS OrderSizeDeviation
FROM dbo.Orders
WHERE State IS NOT NULL
GROUP BY State
ORDER BY OrderSizeDeviation DESC;



/* Query 8 - LAG and LEAD
   Compare each month's revenue with the previous and next month.
   This helps analyze changes in monthly sales over time.
*/

WITH MonthlyRevenue AS
(
    SELECT
        YEAR(OrderDate) AS SalesYear,
        MONTH(OrderDate) AS SalesMonth,
        SUM(TotalPrice) AS Revenue
    FROM dbo.Orders
    GROUP BY
        YEAR(OrderDate),
        MONTH(OrderDate)
)

SELECT
    DATENAME(MONTH, DATEFROMPARTS(SalesYear, SalesMonth, 1))
        + ' ' + CAST(SalesYear AS VARCHAR) AS SalesPeriod,
    Revenue,
    LAG(Revenue) OVER
    (
        ORDER BY SalesYear, SalesMonth
    ) AS PreviousMonthRevenue,
    LEAD(Revenue) OVER
    (
        ORDER BY SalesYear, SalesMonth
    ) AS NextMonthRevenue
FROM MonthlyRevenue
ORDER BY SalesYear, SalesMonth;


/* Query 9 - PERCENT_RANK
   Calculate the relative rank of each payment type
   based on its total revenue.
*/

WITH PaymentRevenue AS
(
    SELECT
        PaymentType,
        SUM(TotalPrice) AS TotalRevenue
    FROM dbo.Orders
    WHERE PaymentType IS NOT NULL
    GROUP BY PaymentType
)

SELECT
    PaymentType,
    TotalRevenue,
    PERCENT_RANK() OVER
    (
        ORDER BY TotalRevenue
    ) AS RevenuePercentRank
FROM PaymentRevenue
ORDER BY TotalRevenue DESC;



/* Query 10 - PERCENTILE_CONT
   Calculate the median order value for each payment type.
   This shows the typical order value for each payment method.
*/

SELECT DISTINCT
    PaymentType,
    PERCENTILE_CONT(0.5)
    WITHIN GROUP
    (
        ORDER BY TotalPrice
    )
    OVER
    (
        PARTITION BY PaymentType
    ) AS MedianOrderValue
FROM dbo.Orders
WHERE PaymentType IS NOT NULL
ORDER BY MedianOrderValue DESC;
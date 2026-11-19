
USE SQLBook;
GO
/*Q1 Compare average order value across marketing channels that were active
   in every year from 2012 through 2015. This helps evaluate which
   established channels generated higher-value orders and how their
   performance changed over time. */

SELECT
    c.Channel,

    AVG(IIF(YEAR(o.OrderDate) = 2012, o.TotalPrice, NULL))
        AS [Average 2012],

    AVG(IIF(YEAR(o.OrderDate) = 2013, o.TotalPrice, NULL))
        AS [Average 2013],

    AVG(IIF(YEAR(o.OrderDate) = 2014, o.TotalPrice, NULL))
        AS [Average 2014],

    AVG(IIF(YEAR(o.OrderDate) = 2015, o.TotalPrice, NULL))
        AS [Average 2015]

FROM dbo.Orders AS o

JOIN dbo.Campaigns AS c
    ON o.CampaignId = c.CampaignId

GROUP BY
    c.Channel

HAVING
    AVG(IIF(YEAR(o.OrderDate) = 2012, o.TotalPrice, NULL)) IS NOT NULL
    AND
    AVG(IIF(YEAR(o.OrderDate) = 2013, o.TotalPrice, NULL)) IS NOT NULL
    AND
    AVG(IIF(YEAR(o.OrderDate) = 2014, o.TotalPrice, NULL)) IS NOT NULL
    AND
    AVG(IIF(YEAR(o.OrderDate) = 2015, o.TotalPrice, NULL)) IS NOT NULL

ORDER BY
    [Average 2015] DESC;




/*Q2 Compare annual revenue across customer spending segments.
   This helps show which customer segments generate the most revenue
   and how their contribution changes over time. */

DECLARE @AverageCustomerSpending MONEY;

SELECT
    @AverageCustomerSpending = AVG(CustomerSpending)
FROM
(
    SELECT
        CustomerId,
        SUM(TotalPrice) AS CustomerSpending
    FROM dbo.Orders
    GROUP BY CustomerId
) AS CustomerTotals;

SELECT
    CASE
        WHEN ct.CustomerSpending < @AverageCustomerSpending * 0.5
            THEN 'Low-Value Customer'
        WHEN ct.CustomerSpending <= @AverageCustomerSpending
            THEN 'Mid-Value Customer'
        ELSE 'High-Value Customer'
    END AS CustomerSegment,

    SUM(IIF(YEAR(o.OrderDate) = 2012, o.TotalPrice, 0)) AS [Revenue 2012],
    SUM(IIF(YEAR(o.OrderDate) = 2013, o.TotalPrice, 0)) AS [Revenue 2013],
    SUM(IIF(YEAR(o.OrderDate) = 2014, o.TotalPrice, 0)) AS [Revenue 2014],
    SUM(IIF(YEAR(o.OrderDate) = 2015, o.TotalPrice, 0)) AS [Revenue 2015]

FROM dbo.Orders AS o

JOIN
(
    SELECT
        CustomerId,
        SUM(TotalPrice) AS CustomerSpending
    FROM dbo.Orders
    GROUP BY CustomerId
) AS ct
    ON o.CustomerId = ct.CustomerId

GROUP BY
    CASE
        WHEN ct.CustomerSpending < @AverageCustomerSpending * 0.5
            THEN 'Low-Value Customer'
        WHEN ct.CustomerSpending <= @AverageCustomerSpending
            THEN 'Mid-Value Customer'
        ELSE 'High-Value Customer'
    END

ORDER BY CustomerSegment;



/*Q3 Compare average order value for holidays and regular days across
   multiple years. This helps identify whether holiday purchasing
   behavior differs from regular-day purchasing over time. */

SELECT
    CASE
        WHEN ISNULL(c.HolidayName, 'Regular Day') = 'Regular Day'
            THEN 'Regular Day'
        ELSE 'Holiday'
    END AS DayType,

    AVG(IIF(YEAR(o.OrderDate) = 2012, o.TotalPrice, NULL)) AS [Average 2012],
    AVG(IIF(YEAR(o.OrderDate) = 2013, o.TotalPrice, NULL)) AS [Average 2013],
    AVG(IIF(YEAR(o.OrderDate) = 2014, o.TotalPrice, NULL)) AS [Average 2014],
    AVG(IIF(YEAR(o.OrderDate) = 2015, o.TotalPrice, NULL)) AS [Average 2015]

FROM dbo.Orders AS o

JOIN dbo.Calendar AS c
    ON o.OrderDate = c.Date

GROUP BY
    CASE
        WHEN ISNULL(c.HolidayName, 'Regular Day') = 'Regular Day'
            THEN 'Regular Day'
        ELSE 'Holiday'
    END;



/*Q4 Compare annual revenue by customer gender, including customers whose
   gender was not recorded. This helps show how revenue contribution
   differs across customer groups over time. */

SELECT
    COALESCE(NULLIF(c.Gender, ''), 'Unknown') AS CustomerGender,

    SUM(IIF(YEAR(o.OrderDate) = 2012, o.TotalPrice, 0))
        AS [Revenue 2012],

    SUM(IIF(YEAR(o.OrderDate) = 2013, o.TotalPrice, 0))
        AS [Revenue 2013],

    SUM(IIF(YEAR(o.OrderDate) = 2014, o.TotalPrice, 0))
        AS [Revenue 2014],

    SUM(IIF(YEAR(o.OrderDate) = 2015, o.TotalPrice, 0))
        AS [Revenue 2015]

FROM dbo.Orders AS o

JOIN dbo.Customers AS c
    ON o.CustomerId = c.CustomerId

GROUP BY
    COALESCE(NULLIF(c.Gender, ''), 'Unknown')

ORDER BY [Revenue 2015] DESC;



/* Q5 Summarize the states where each payment type was used and compare
   total sales across payment methods. This helps show the sales
   contribution and geographic use of each payment method. */

WITH PaymentStates AS
(
    SELECT
        PaymentType,
        STRING_AGG(CAST(State AS VARCHAR(MAX)), ', ') AS StatesUsed
    FROM
    (
        SELECT DISTINCT
            PaymentType,
            State
        FROM dbo.Orders
        WHERE PaymentType <> '??'
          AND State <> ''
    ) AS A
    GROUP BY PaymentType
)

SELECT
    o.PaymentType,
    ps.StatesUsed,
    COUNT(*) AS NumberOfOrders,
    SUM(o.TotalPrice) AS TotalSales
FROM dbo.Orders AS o

JOIN PaymentStates AS ps
    ON o.PaymentType = ps.PaymentType

WHERE o.PaymentType <> '??'

GROUP BY
    o.PaymentType,
    ps.StatesUsed

ORDER BY TotalSales DESC;


/* Q6: Split a list of major payment methods into individual values
   and compare their average order values. This helps show differences
   in customer spending across commonly used payment methods. */

DECLARE @PaymentList VARCHAR(50);

SET @PaymentList = 'VI,AE,MC,DB,OC';

SELECT
    o.PaymentType,
    COUNT(*) AS NumberOfOrders,
    AVG(o.TotalPrice) AS AverageOrderValue

FROM dbo.Orders AS o

WHERE o.PaymentType IN
(
    SELECT TRIM(value)
    FROM STRING_SPLIT(@PaymentList, ',')
)

GROUP BY o.PaymentType

ORDER BY AverageOrderValue DESC;


/* Q7: Compare customers who purchased in one year but did not purchase
   again in the following year. This helps evaluate changes in customer
   return behavior across consecutive years. */

SELECT
    '2012-2013' AS YearPeriod,
    COUNT(*) AS CustomersNotReturning
FROM
(
    SELECT CustomerId
    FROM dbo.Orders
    WHERE YEAR(OrderDate) = 2012

    EXCEPT

    SELECT CustomerId
    FROM dbo.Orders
    WHERE YEAR(OrderDate) = 2013
) AS Period1

UNION ALL

SELECT
    '2013-2014' AS YearPeriod,
    COUNT(*) AS CustomersNotReturning
FROM
(
    SELECT CustomerId
    FROM dbo.Orders
    WHERE YEAR(OrderDate) = 2013

    EXCEPT

    SELECT CustomerId
    FROM dbo.Orders
    WHERE YEAR(OrderDate) = 2014
) AS Period2

UNION ALL

SELECT
    '2014-2015' AS YearPeriod,
    COUNT(*) AS CustomersNotReturning
FROM
(
    SELECT CustomerId
    FROM dbo.Orders
    WHERE YEAR(OrderDate) = 2014

    EXCEPT

    SELECT CustomerId
    FROM dbo.Orders
    WHERE YEAR(OrderDate) = 2015
) AS Period3;


/* Q8: Compare products that were sold in consecutive years.
   This helps show how many products continued generating sales
   from one year to the next. */

SELECT
    '2012-2013' AS YearPeriod,
    COUNT(*) AS ProductsSoldInBothYears
FROM
(
    SELECT ol.ProductId
    FROM dbo.OrderLines AS ol
    JOIN dbo.Orders AS o
        ON ol.OrderId = o.OrderId
    WHERE YEAR(o.OrderDate) = 2012

    INTERSECT

    SELECT ol.ProductId
    FROM dbo.OrderLines AS ol
    JOIN dbo.Orders AS o
        ON ol.OrderId = o.OrderId
    WHERE YEAR(o.OrderDate) = 2013
) AS Period1

UNION ALL

SELECT
    '2013-2014',
    COUNT(*)
FROM
(
    SELECT ol.ProductId
    FROM dbo.OrderLines AS ol
    JOIN dbo.Orders AS o
        ON ol.OrderId = o.OrderId
    WHERE YEAR(o.OrderDate) = 2013

    INTERSECT

    SELECT ol.ProductId
    FROM dbo.OrderLines AS ol
    JOIN dbo.Orders AS o
        ON ol.OrderId = o.OrderId
    WHERE YEAR(o.OrderDate) = 2014
) AS Period2

UNION ALL

SELECT
    '2014-2015',
    COUNT(*)
FROM
(
    SELECT ol.ProductId
    FROM dbo.OrderLines AS ol
    JOIN dbo.Orders AS o
        ON ol.OrderId = o.OrderId
    WHERE YEAR(o.OrderDate) = 2014

    INTERSECT

    SELECT ol.ProductId
    FROM dbo.OrderLines AS ol
    JOIN dbo.Orders AS o
        ON ol.OrderId = o.OrderId
    WHERE YEAR(o.OrderDate) = 2015
) AS Period3;


/* Q9: Compare order volume by payment type across multiple years.
   This helps show how the use of different payment methods
   changed from 2012 through 2015. */

SELECT
    PaymentType,
    [2012],
    [2013],
    [2014],
    [2015]

FROM
(
    SELECT
        PaymentType,
        YEAR(OrderDate) AS OrderYear,
        OrderId
    FROM dbo.Orders
    WHERE YEAR(OrderDate) BETWEEN 2012 AND 2015
      AND PaymentType <> '??'
) AS SourceData

PIVOT
(
    COUNT(OrderId)
    FOR OrderYear IN
    (
        [2012],
        [2013],
        [2014],
        [2015]
    )
) AS PivotTable

ORDER BY [2015] DESC;


/* Q10: Compare monthly order volume across multiple years.
   This helps identify recurring seasonal patterns in customer
   purchasing activity from 2012 through 2015. */

SELECT
    MonthNumber,
    MonthName,
    [2012],
    [2013],
    [2014],
    [2015]

FROM
(
    SELECT
        MONTH(OrderDate) AS MonthNumber,
        DATENAME(MONTH, OrderDate) AS MonthName,
        YEAR(OrderDate) AS OrderYear,
        OrderId

    FROM dbo.Orders

    WHERE YEAR(OrderDate) BETWEEN 2012 AND 2015

) AS SourceData

PIVOT
(
    COUNT(OrderId)

    FOR OrderYear IN
    (
        [2012],
        [2013],
        [2014],
        [2015]
    )

) AS PivotTable

ORDER BY MonthNumber;
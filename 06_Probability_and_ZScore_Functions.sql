USE SQLBook;
GO


/* ============================================================
   GENERAL FUNCTIONS
   ============================================================ */


/* ============================================================
   FUNCTION 1 - FACTORIAL

   n! = n * (n-1) * ... * 1
   ============================================================ */

CREATE OR ALTER FUNCTION dbo.Factorial
(
    @n INT
)
RETURNS FLOAT
AS
BEGIN

    DECLARE @Result FLOAT = 1;
    DECLARE @i INT = 1;

    IF @n < 0
        RETURN NULL;

    WHILE @i <= @n
    BEGIN
        SET @Result = @Result * @i;
        SET @i = @i + 1;
    END;

    RETURN @Result;

END;
GO


/* ============================================================
   FUNCTION 2 - COMBINATION

             n!
   C(n,k) = --------
            k!(n-k)!

   Calls dbo.Factorial
   ============================================================ */

CREATE OR ALTER FUNCTION dbo.Combination
(
    @n INT,
    @k INT
)
RETURNS FLOAT
AS
BEGIN

    DECLARE @Result FLOAT;

    IF @n < 0 OR @k < 0 OR @k > @n
        RETURN NULL;

    SET @Result =
        dbo.Factorial(@n) /
        (
            dbo.Factorial(@k) *
            dbo.Factorial(@n - @k)
        );

    RETURN @Result;

END;
GO


/* ============================================================
   FUNCTION 3 - BINOMIAL PROBABILITY

   Probability of EXACTLY k successes in n trials

   P(X = k) =
   C(n,k) * p^k * (1-p)^(n-k)

   Calls dbo.Combination
   ============================================================ */

CREATE OR ALTER FUNCTION dbo.BinomialProbability
(
    @n INT,
    @k INT,
    @p FLOAT
)
RETURNS FLOAT
AS
BEGIN

    DECLARE @Result FLOAT;

    IF @n < 0
       OR @k < 0
       OR @k > @n
       OR @p < 0
       OR @p > 1
        RETURN NULL;

    SET @Result =
        dbo.Combination(@n, @k) *
        POWER(@p, @k) *
        POWER(1 - @p, @n - @k);

    RETURN @Result;

END;
GO


/* ============================================================
   FUNCTION 4 - Z-SCORE

       Value - Mean
   Z = ------------
          STDEV

   Used by:
   Query 5 - Monthly Product Demand
   Query 6 - Monthly Revenue
   ============================================================ */

CREATE OR ALTER FUNCTION dbo.ZScore
(
    @Value FLOAT,
    @Mean FLOAT,
    @StandardDeviation FLOAT
)
RETURNS FLOAT
AS
BEGIN

    IF @StandardDeviation IS NULL
       OR @StandardDeviation = 0
        RETURN NULL;

    RETURN
        (@Value - @Mean) / @StandardDeviation;

END;
GO



/* ============================================================
   QUERY 1 - MULTI-UNIT TRANSACTION

   Business Question:
   What is the probability that a transaction contains
   two or more product units?

   TRUE  = NumUnits >= 2
   FALSE = NumUnits < 2

   Binomial Question:
   What is the probability that exactly 3 of the next
   5 transactions contain two or more units?
   ============================================================ */

DECLARE @p1 FLOAT;

SELECT
    @p1 =
        SUM(
            CASE
                WHEN NumUnits >= 2 THEN 1.0
                ELSE 0
            END
        ) / COUNT(*)
FROM Orders;


SELECT
    COUNT(*) AS TotalTransactions,

    SUM(
        CASE
            WHEN NumUnits >= 2 THEN 1
            ELSE 0
        END
    ) AS MultiUnitTransactions,

    CAST(@p1 AS DECIMAL(10,4))
        AS HistoricalProbability,

    5 AS NumberOfTrials,

    3 AS NumberOfSuccesses,

    CAST(
        dbo.BinomialProbability(5, 3, @p1)
        AS DECIMAL(10,4)
    ) AS BinomialProbability

FROM Orders;



/* ============================================================
   QUERY 2 - REPEAT CUSTOMER

   Business Question:
   What is the probability that a purchasing customer
   is a repeat customer?

   TRUE  = Customer has 2 or more orders
   FALSE = Customer has only 1 order

   Binomial Question:
   What is the probability that exactly 4 of the next
   10 customers are repeat customers?
   ============================================================ */

DECLARE @p2 FLOAT;

DROP TABLE IF EXISTS #CustomerOrders;

SELECT
    CustomerId,
    COUNT(*) AS NumberOfOrders
INTO #CustomerOrders
FROM Orders
WHERE CustomerId IS NOT NULL
GROUP BY CustomerId;


SELECT
    @p2 =
        SUM(
            CASE
                WHEN NumberOfOrders >= 2 THEN 1.0
                ELSE 0
            END
        ) / COUNT(*)
FROM #CustomerOrders;


SELECT
    COUNT(*) AS TotalCustomers,

    SUM(
        CASE
            WHEN NumberOfOrders >= 2 THEN 1
            ELSE 0
        END
    ) AS RepeatCustomers,

    CAST(@p2 AS DECIMAL(10,4))
        AS HistoricalProbability,

    10 AS NumberOfTrials,

    4 AS NumberOfSuccesses,

    CAST(
        dbo.BinomialProbability(10, 4, @p2)
        AS DECIMAL(10,4)
    ) AS BinomialProbability

FROM #CustomerOrders;


DROP TABLE #CustomerOrders;



/* ============================================================
   QUERY 3 - PURCHASE BY DAY OF WEEK
   EXCEL QUERY

   Business Question:
   Which days have the highest probability of receiving
   a purchase?

   For each day:
   TRUE  = Purchase occurs on selected day
   FALSE = Purchase occurs on another day

   Binomial Question:
   What is the probability that exactly 2 of the next
   5 purchases occur on each selected day?

   Excel:
   Column Chart
   ============================================================ */

WITH DayProbability AS
(
    SELECT
        c.DOW,
        c.DOWint,

        COUNT(*) AS NumberOfPurchases,

        COUNT(*) * 1.0 /
        SUM(COUNT(*)) OVER () AS p

    FROM Orders o

    JOIN Calendar c
        ON o.OrderDate = c.Date

    GROUP BY
        c.DOW,
        c.DOWint
)

SELECT
    DOW AS DayOfWeek,

    NumberOfPurchases,

    CAST(p AS DECIMAL(10,4))
        AS HistoricalProbability,

    5 AS NumberOfTrials,

    2 AS NumberOfSuccesses,

    CAST(
        dbo.BinomialProbability(5, 2, p)
        AS DECIMAL(10,4)
    ) AS BinomialProbability

FROM DayProbability

ORDER BY DOWint;



/* ============================================================
   QUERY 4 - CAMPAIGN CHANNEL
   EXCEL QUERY

   Business Question:
   Which campaign channels have the highest probability
   of generating a purchase?

   For each channel:
   TRUE  = Purchase comes from selected channel
   FALSE = Purchase comes from another channel

   Binomial Question:
   What is the probability that exactly 3 of the next
   10 purchases come through each selected channel?

   Excel:
   Column / Bar Chart
   ============================================================ */

WITH ChannelProbability AS
(
    SELECT
        c.Channel,

        COUNT(*) AS NumberOfPurchases,

        COUNT(*) * 1.0 /
        SUM(COUNT(*)) OVER () AS p

    FROM Orders o

    JOIN Campaigns c
        ON o.CampaignId = c.CampaignId

    GROUP BY
        c.Channel
)

SELECT
    Channel,

    NumberOfPurchases,

    CAST(p AS DECIMAL(10,4))
        AS HistoricalProbability,

    10 AS NumberOfTrials,

    3 AS NumberOfSuccesses,

    CAST(
        dbo.BinomialProbability(10, 3, p)
        AS DECIMAL(10,4)
    ) AS BinomialProbability

FROM ChannelProbability

ORDER BY HistoricalProbability DESC;



/* ============================================================
   QUERY 5 - MONTHLY PRODUCT DEMAND
   NORMAL DISTRIBUTION

   Business Question:
   How unusual is monthly product demand compared with
   typical monthly demand?

   Input:
   Number of units sold per month

   Mean = Average Monthly Demand
   Sigma = Standard Deviation

   Z-Score is calculated using dbo.ZScore
   ============================================================ */

DROP TABLE IF EXISTS #MonthlyDemand;

SELECT
    YEAR(o.OrderDate) AS SalesYear,
    MONTH(o.OrderDate) AS SalesMonth,
    SUM(ol.NumUnits) AS UnitsSold

INTO #MonthlyDemand

FROM Orders o

JOIN OrderLines ol
    ON o.OrderId = ol.OrderId

GROUP BY
    YEAR(o.OrderDate),
    MONTH(o.OrderDate);


DECLARE @MeanDemand FLOAT;
DECLARE @StdDemand FLOAT;


SELECT
    @MeanDemand = AVG(UnitsSold * 1.0),
    @StdDemand = STDEV(UnitsSold * 1.0)

FROM #MonthlyDemand;


SELECT
    SalesYear,
    SalesMonth,

    UnitsSold,

    CAST(@MeanDemand AS DECIMAL(18,2))
        AS MeanMonthlyDemand,

    CAST(@StdDemand AS DECIMAL(18,2))
        AS StandardDeviation,

    CAST(
        dbo.ZScore(
            UnitsSold,
            @MeanDemand,
            @StdDemand
        )
        AS DECIMAL(10,4)
    ) AS ZScore,

    CASE

        WHEN dbo.ZScore(
            UnitsSold,
            @MeanDemand,
            @StdDemand
        ) > 3
            THEN 'Extreme High - Above +3 Sigma'

        WHEN dbo.ZScore(
            UnitsSold,
            @MeanDemand,
            @StdDemand
        ) > 2
            THEN 'Unusually High - Above +2 Sigma'

        WHEN dbo.ZScore(
            UnitsSold,
            @MeanDemand,
            @StdDemand
        ) > 1
            THEN 'Above Normal - Between +1 and +2 Sigma'

        WHEN dbo.ZScore(
            UnitsSold,
            @MeanDemand,
            @StdDemand
        ) >= -1
            THEN 'Normal - Within 1 Sigma'

        WHEN dbo.ZScore(
            UnitsSold,
            @MeanDemand,
            @StdDemand
        ) >= -2
            THEN 'Below Normal - Between -1 and -2 Sigma'

        WHEN dbo.ZScore(
            UnitsSold,
            @MeanDemand,
            @StdDemand
        ) >= -3
            THEN 'Unusually Low - Below -2 Sigma'

        ELSE
            'Extreme Low - Below -3 Sigma'

    END AS DemandClassification

FROM #MonthlyDemand

ORDER BY
    SalesYear,
    SalesMonth;


DROP TABLE #MonthlyDemand;



/* ============================================================
   QUERY 6 - MONTHLY REVENUE
   NORMAL DISTRIBUTION

   Business Question:
   How unusual is monthly sales revenue compared with
   typical monthly revenue?

   Input:
   Total sales revenue per month

   Mean = Average Monthly Revenue
   Sigma = Standard Deviation

   Uses the SAME dbo.ZScore function as Query 5.
   ============================================================ */

DROP TABLE IF EXISTS #MonthlyRevenue;

SELECT
    YEAR(OrderDate) AS SalesYear,
    MONTH(OrderDate) AS SalesMonth,
    SUM(TotalPrice) AS Revenue

INTO #MonthlyRevenue

FROM Orders

GROUP BY
    YEAR(OrderDate),
    MONTH(OrderDate);


DECLARE @MeanRevenue FLOAT;
DECLARE @StdRevenue FLOAT;


SELECT
    @MeanRevenue = AVG(Revenue),
    @StdRevenue = STDEV(Revenue)

FROM #MonthlyRevenue;


SELECT
    SalesYear,
    SalesMonth,

    CAST(
        Revenue
        AS DECIMAL(18,2)
    ) AS MonthlyRevenue,

    CAST(
        @MeanRevenue
        AS DECIMAL(18,2)
    ) AS MeanMonthlyRevenue,

    CAST(
        @StdRevenue
        AS DECIMAL(18,2)
    ) AS StandardDeviation,

    CAST(
        dbo.ZScore(
            Revenue,
            @MeanRevenue,
            @StdRevenue
        )
        AS DECIMAL(10,4)
    ) AS ZScore,

    CASE

        WHEN dbo.ZScore(
            Revenue,
            @MeanRevenue,
            @StdRevenue
        ) > 3
            THEN 'Extreme High - Above +3 Sigma'

        WHEN dbo.ZScore(
            Revenue,
            @MeanRevenue,
            @StdRevenue
        ) > 2
            THEN 'Unusually High - Above +2 Sigma'

        WHEN dbo.ZScore(
            Revenue,
            @MeanRevenue,
            @StdRevenue
        ) > 1
            THEN 'Above Normal - Between +1 and +2 Sigma'

        WHEN dbo.ZScore(
            Revenue,
            @MeanRevenue,
            @StdRevenue
        ) >= -1
            THEN 'Normal - Within 1 Sigma'

        WHEN dbo.ZScore(
            Revenue,
            @MeanRevenue,
            @StdRevenue
        ) >= -2
            THEN 'Below Normal - Between -1 and -2 Sigma'

        WHEN dbo.ZScore(
            Revenue,
            @MeanRevenue,
            @StdRevenue
        ) >= -3
            THEN 'Unusually Low - Below -2 Sigma'

        ELSE
            'Extreme Low - Below -3 Sigma'

    END AS RevenueClassification

FROM #MonthlyRevenue

ORDER BY
    SalesYear,
    SalesMonth;


DROP TABLE #MonthlyRevenue;



/* ============================================================
   QUERY 7 - GEOGRAPHIC PURCHASE PROBABILITY
   EXCEL QUERY

   Business Question:
   Which geographic markets have the highest probability
   of generating a purchase?

   For each state:
   TRUE  = Purchase comes from selected state
   FALSE = Purchase comes from another state

   Binomial Question:
   What is the probability that exactly 4 of the next
   10 purchases come from each selected state?

   Excel:
   Filled Map
   ============================================================ */

WITH StateProbability AS
(
    SELECT
        State,

        COUNT(*) AS NumberOfPurchases,

        COUNT(*) * 1.0 /
        SUM(COUNT(*)) OVER () AS p

    FROM Orders

    WHERE State IS NOT NULL

    GROUP BY State
)

SELECT
    State,

    NumberOfPurchases,

    CAST(p AS DECIMAL(10,4))
        AS HistoricalProbability,

    10 AS NumberOfTrials,

    4 AS NumberOfSuccesses,

    CAST(
        dbo.BinomialProbability(10, 4, p)
        AS DECIMAL(10,4)
    ) AS BinomialProbability

FROM StateProbability

ORDER BY HistoricalProbability DESC;



/* ============================================================
   QUERY 8 - HIGH-DISCOUNT CAMPAIGN

   Business Question:
   What is the probability that a campaign has a discount
   above the historical average campaign discount?

   TRUE  = Discount > Average Discount
   FALSE = Discount <= Average Discount

   Binomial Question:
   What is the probability that exactly 3 of the next
   5 campaigns have above-average discounts?
   ============================================================ */

DECLARE @AverageDiscount FLOAT;
DECLARE @p8 FLOAT;


SELECT
    @AverageDiscount = AVG(Discount * 1.0)
FROM Campaigns;


SELECT
    @p8 =
        SUM(
            CASE
                WHEN Discount > @AverageDiscount
                    THEN 1.0
                ELSE 0
            END
        ) / COUNT(*)

FROM Campaigns;


SELECT
    COUNT(*) AS TotalCampaigns,

    CAST(
        @AverageDiscount
        AS DECIMAL(10,2)
    ) AS AverageDiscountThreshold,

    SUM(
        CASE
            WHEN Discount > @AverageDiscount
                THEN 1
            ELSE 0
        END
    ) AS CampaignsAboveAverageDiscount,

    CAST(@p8 AS DECIMAL(10,4))
        AS HistoricalProbability,

    5 AS NumberOfTrials,

    3 AS NumberOfSuccesses,

    CAST(
        dbo.BinomialProbability(5, 3, @p8)
        AS DECIMAL(10,4)
    ) AS BinomialProbability

FROM Campaigns;



/* ============================================================
   QUERY 9 - SUBSCRIBER RETENTION

   Business Question:
   What is the probability that a subscriber stays
   for at least 12 months?

   TRUE  = Tenure >= 12 months
   FALSE = Tenure < 12 months

   Binomial Question:
   What is the probability that exactly 7 of the next
   10 subscribers stay for at least 12 months?

   NULL tenure is excluded.
   ============================================================ */

DECLARE @p9 FLOAT;


SELECT
    @p9 =
        SUM(
            CASE
                WHEN Tenure >= 12 THEN 1.0
                ELSE 0
            END
        ) / COUNT(*)

FROM Subscribers

WHERE Tenure IS NOT NULL;


SELECT
    COUNT(*) AS SubscribersWithKnownTenure,

    SUM(
        CASE
            WHEN Tenure >= 12 THEN 1
            ELSE 0
        END
    ) AS Subscribers12MonthsOrMore,

    CAST(@p9 AS DECIMAL(10,4))
        AS HistoricalProbability,

    10 AS NumberOfTrials,

    7 AS NumberOfSuccesses,

    CAST(
        dbo.BinomialProbability(10, 7, @p9)
        AS DECIMAL(10,4)
    ) AS BinomialProbability

FROM Subscribers

WHERE Tenure IS NOT NULL;



/* ============================================================
   QUERY 10 - HIGHER-PRICE PRODUCT PURCHASE

   Business Question:
   What is the probability that a purchased product line
   belongs to the higher-price segment?

   Threshold:
   Average FullPrice of all products

   TRUE  = FullPrice >= Average Product Price
   FALSE = FullPrice < Average Product Price

   Binomial Question:
   What is the probability that exactly 4 of the next
   10 purchased product lines are higher-price products?
   ============================================================ */

DECLARE @AverageProductPrice FLOAT;
DECLARE @p10 FLOAT;


SELECT
    @AverageProductPrice = AVG(FullPrice)
FROM Products
WHERE FullPrice IS NOT NULL;


SELECT
    @p10 =
        SUM(
            CASE
                WHEN p.FullPrice >= @AverageProductPrice
                    THEN 1.0
                ELSE 0
            END
        ) / COUNT(*)

FROM OrderLines ol

JOIN Products p
    ON ol.ProductId = p.ProductId

WHERE p.FullPrice IS NOT NULL;


SELECT
    COUNT(*) AS TotalPurchasedProductLines,

    CAST(
        @AverageProductPrice
        AS DECIMAL(18,2)
    ) AS AverageProductPriceThreshold,

    SUM(
        CASE
            WHEN p.FullPrice >= @AverageProductPrice
                THEN 1
            ELSE 0
        END
    ) AS HigherPricePurchases,

    CAST(@p10 AS DECIMAL(10,4))
        AS HistoricalProbability,

    10 AS NumberOfTrials,

    4 AS NumberOfSuccesses,

    CAST(
        dbo.BinomialProbability(10, 4, @p10)
        AS DECIMAL(10,4)
    ) AS BinomialProbability

FROM OrderLines ol

JOIN Products p
    ON ol.ProductId = p.ProductId

WHERE p.FullPrice IS NOT NULL;
USE SQLBook;
GO

/*====================================================================
  SUBSCRIBER TENURE LOOKUP MODEL

  WHY SUBSCRIBERS:
  The Subscribers table was selected because it contains a measurable
  outcome (Tenure) and useful subscriber characteristics such as
  Channel, RatePlan, and Market.

  BUSINESS GOAL:
  Use historical subscriber data to estimate the Tenure of similar
  subscribers. This can help identify subscriber groups that are
  expected to maintain longer or shorter relationships with the service.

  MODEL SET:
  Subscribers who started in 2004 are used to build the model.

  SCORE SET:
  Subscribers who started in 2005 are used to apply and evaluate
  the model.

  MODEL PROGRESSION:
  1. No Dimensions
  2. One Dimension: Channel
  3. Multiple Dimensions: Channel + RatePlan + Market
  4. Broader Historical Context
  5. Value Chart using NTILE(10)
====================================================================*/


/*====================================================================
  ABSTRACTION FUNCTION

  GOAL:
  Create a reusable lookup model for any selected historical year.

  WHY:
  The Channel + RatePlan + Market model is needed more than once.
  Creating a table-valued function avoids repeating the same model
  calculation and follows the reusable function approach used in class.

  HOW:
  For the selected year, subscribers are grouped by Channel, RatePlan,
  and Market and the average Tenure is calculated for each combination.
====================================================================*/

CREATE OR ALTER FUNCTION GetSubscriberTenureModel
(
    @ModelYear INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT Channel, RatePlan, Market, AVG(CAST(Tenure AS FLOAT)) AS AverageTenure
    FROM Subscribers
    WHERE YEAR(StartDate) = @ModelYear AND Tenure IS NOT NULL
    GROUP BY Channel, RatePlan, Market
)
GO


/*====================================================================
  EXAMPLE 1 - LOOKUP MODEL WITH NO DIMENSIONS

  GOAL:
  Create the simplest baseline prediction without using any subscriber
  dimensions.

  HOW:
  Calculate the overall average Tenure of subscribers who started in
  2004 and use it as the predicted average Tenure for subscribers who
  started in 2005.

  BUSINESS USE:
  Provides a general baseline that can later be compared with models
  that use subscriber characteristics.
====================================================================*/

DECLARE @ModelYear INT = 2004, @ScoreYear INT = 2005;
DECLARE @ModelAverage FLOAT = (SELECT AVG(CAST(Tenure AS FLOAT)) FROM Subscribers WHERE YEAR(StartDate) = @ModelYear AND Tenure IS NOT NULL);

SELECT @ModelYear AS [Model Year], @ScoreYear AS [Score Year],
       ROUND(@ModelAverage, 2) AS [Predicted Average Tenure],
       ROUND(AVG(CAST(Tenure AS FLOAT)), 2) AS [Actual Average Tenure]
FROM Subscribers
WHERE YEAR(StartDate) = @ScoreYear AND Tenure IS NOT NULL;
GO


/*====================================================================
  EXAMPLE 2 - LOOKUP MODEL WITH ONE DIMENSION: CHANNEL

  GOAL:
  Improve the baseline prediction by adding Channel as one dimension.

  WHY:
  Subscribers acquired through different Channels may have different
  retention patterns.

  HOW:
  Calculate the average historical Tenure for each Channel in 2004
  and apply it to subscribers from the same Channel in 2005.

  FALLBACK:
  If a Channel exists in 2005 but has no historical match in 2004,
  the overall 2004 average Tenure is used.

  BUSINESS USE:
  Helps identify acquisition Channels associated with longer or
  shorter subscriber relationships.
====================================================================*/

DECLARE @ModelYear INT = 2004, @ScoreYear INT = 2005;
DECLARE @FallbackTenure FLOAT = (SELECT AVG(CAST(Tenure AS FLOAT)) FROM Subscribers WHERE YEAR(StartDate) = @ModelYear AND Tenure IS NOT NULL);

WITH ModelSet AS (
    SELECT Channel, AVG(CAST(Tenure AS FLOAT)) AS AverageTenure
    FROM Subscribers
    WHERE YEAR(StartDate) = @ModelYear AND Tenure IS NOT NULL
    GROUP BY Channel
),
ScoreSet AS (
    SELECT SubscriberId, Channel, Tenure
    FROM Subscribers
    WHERE YEAR(StartDate) = @ScoreYear AND Tenure IS NOT NULL
)
SELECT S.Channel, COUNT(*) AS [Number of Subscribers],
       ROUND(AVG(COALESCE(M.AverageTenure, @FallbackTenure)), 2) AS [Predicted Average Tenure],
       ROUND(AVG(CAST(S.Tenure AS FLOAT)), 2) AS [Actual Average Tenure]
FROM ScoreSet S LEFT JOIN ModelSet M ON S.Channel = M.Channel
GROUP BY S.Channel
ORDER BY S.Channel;
GO


/*====================================================================
  EXAMPLE 3 - LOOKUP MODEL WITH MULTIPLE DIMENSIONS:
              CHANNEL + RATEPLAN + MARKET

  GOAL:
  Create a more specific prediction using three subscriber dimensions.

  WHY:
  Channel alone may be too broad. Subscribers acquired through the
  same Channel may have different retention patterns depending on
  their RatePlan and Market.

  HOW:
  The reusable GetSubscriberTenureModel function creates the 2004
  lookup model grouped by Channel + RatePlan + Market. Each subscriber
  in the 2005 Score Set is matched with the historical average Tenure
  of subscribers with the same characteristics.

  FALLBACK:
  If an exact combination is unavailable, the overall 2004 average
  Tenure is used.

  BUSINESS USE:
  Provides more specific predictions for different subscriber segments.
====================================================================*/

DECLARE @ModelYear INT = 2004, @ScoreYear INT = 2005;
DECLARE @FallbackTenure FLOAT = (SELECT AVG(CAST(Tenure AS FLOAT)) FROM Subscribers WHERE YEAR(StartDate) = @ModelYear AND Tenure IS NOT NULL);

WITH ScoreSet AS (
    SELECT SubscriberId, Channel, RatePlan, Market, Tenure
    FROM Subscribers
    WHERE YEAR(StartDate) = @ScoreYear AND Tenure IS NOT NULL
)
SELECT S.Channel, S.RatePlan, S.Market, COUNT(*) AS [Number of Subscribers],
       ROUND(AVG(COALESCE(M.AverageTenure, @FallbackTenure)), 2) AS [Predicted Average Tenure],
       ROUND(AVG(CAST(S.Tenure AS FLOAT)), 2) AS [Actual Average Tenure]
FROM ScoreSet S LEFT JOIN GetSubscriberTenureModel(@ModelYear) M
ON S.Channel = M.Channel AND S.RatePlan = M.RatePlan AND S.Market = M.Market
GROUP BY S.Channel, S.RatePlan, S.Market
ORDER BY S.Channel, S.RatePlan, S.Market;
GO


/*====================================================================
  EXAMPLE 4 - BROADER HISTORICAL CONTEXT

  GOAL:
  Examine subscriber Tenure across all available StartDate years
  instead of considering only the 2004 and 2005 cohorts.

  WHY:
  Looking at multiple years provides broader context for interpreting
  the lookup model.

  HOW:
  Calculate average Tenure for each StartDate year. LAG() retrieves
  the previous year's average so the percentage change between
  consecutive subscriber cohorts can be calculated.

  IMPORTANT:
  A decrease in average Tenure does not automatically mean retention
  became worse. Subscribers with later StartDates may naturally have
  had less time to accumulate Tenure.

  BUSINESS USE:
  Shows how average Tenure differs among subscriber cohorts over time
  and provides context for the 2004-to-2005 model.
====================================================================*/

WITH YearlyTenure AS (
    SELECT YEAR(StartDate) AS [Year], COUNT(*) AS [Number of Subscribers], AVG(CAST(Tenure AS FLOAT)) AS AverageTenure
    FROM Subscribers
    WHERE StartDate IS NOT NULL AND Tenure IS NOT NULL
    GROUP BY YEAR(StartDate)
),
YearlyComparison AS (
    SELECT [Year], [Number of Subscribers], AverageTenure, LAG(AverageTenure) OVER (ORDER BY [Year]) AS PreviousYearAverageTenure
    FROM YearlyTenure
)
SELECT [Year], [Number of Subscribers], ROUND(AverageTenure, 2) AS [Average Tenure],
       ROUND(PreviousYearAverageTenure, 2) AS [Previous Year Average Tenure],
       ROUND(100.0 * (AverageTenure - PreviousYearAverageTenure) / NULLIF(PreviousYearAverageTenure, 0), 2) AS [Year-over-Year Change %]
FROM YearlyComparison
ORDER BY [Year];
GO


/*====================================================================
  EXAMPLE 5 - VALUE CHART USING NTILE(10)

  GOAL:
  Evaluate the multiple-dimension lookup model by comparing predicted
  Tenure with actual Tenure across ten groups.

  WHY:
  Individual predictions for more than one million subscribers are
  difficult to evaluate. A Value Chart summarizes model performance
  into ten approximately equal groups.

  HOW:
  Reuse the Channel + RatePlan + Market model created by the
  GetSubscriberTenureModel function.

  Each 2005 subscriber receives a predicted Tenure based on matching
  historical subscribers from 2004. NTILE(10) then sorts subscribers
  by predicted Tenure and divides them into ten deciles.

  Decile 1 contains subscribers with the highest predicted Tenure.

  BUSINESS USE:
  Shows whether groups predicted to have longer subscriber
  relationships actually demonstrate higher observed Tenure.

  EXCEL:
  Export the final result to Excel and compare Average Predicted Tenure
  with Average Actual Tenure across the ten deciles.
====================================================================*/

DECLARE @ModelYear INT = 2004, @ScoreYear INT = 2005;
DECLARE @FallbackTenure FLOAT = (SELECT AVG(CAST(Tenure AS FLOAT)) FROM Subscribers WHERE YEAR(StartDate) = @ModelYear AND Tenure IS NOT NULL);

WITH ScoreSet AS (
    SELECT SubscriberId, Channel, RatePlan, Market, CAST(Tenure AS FLOAT) AS ActualTenure
    FROM Subscribers
    WHERE YEAR(StartDate) = @ScoreYear AND Tenure IS NOT NULL
),
Predictions AS (
    SELECT S.SubscriberId, S.ActualTenure, COALESCE(M.AverageTenure, @FallbackTenure) AS PredictedTenure
    FROM ScoreSet S LEFT JOIN GetSubscriberTenureModel(@ModelYear) M
    ON S.Channel = M.Channel AND S.RatePlan = M.RatePlan AND S.Market = M.Market
),
ValueChart AS (
    SELECT SubscriberId, ActualTenure, PredictedTenure, NTILE(10) OVER (ORDER BY PredictedTenure DESC) AS Decile
    FROM Predictions
)
SELECT Decile, COUNT(*) AS [Number of Subscribers],
       ROUND(AVG(PredictedTenure), 2) AS [Average Predicted Tenure],
       ROUND(AVG(ActualTenure), 2) AS [Average Actual Tenure]
FROM ValueChart
GROUP BY Decile
ORDER BY Decile;
GO
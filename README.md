# SQLBook Sales and Customer Analytics (T-SQL)

A collection of commented T-SQL scripts that analyze a retail orders database (2009 to 2015), repair broken table relationships, and build reusable functions. Built as coursework for BCIT COMP 2854, Data Analytics Fundamentals. Every query starts with a comment that states its business goal.

The `SQLBook` database is a course dataset and is not included in this repository.

## Scripts

| File | What it does |
|---|---|
| `01_Orders_Analysis_2012_2015.sql` | 10 queries comparing average order value by marketing channel, revenue by customer segment and gender, holiday and regular-day orders, payment types by state, repeat and lapsed customers, and monthly order volume (2012 to 2015). |
| `02_Referential_Integrity.sql` | Checks 7 table relationships for orphaned records, removes them, makes keys non-null, and adds primary and foreign key constraints. **This script deletes rows, so run it only on a practice copy of the database.** |
| `03_Window_Functions_and_Cursor.sql` | Finds the best revenue month per year with a cursor and again with `FIRST_VALUE`, then uses `COUNT`, `ROW_NUMBER`, `NTILE`, variance and standard deviation, `LAG` and `LEAD`, `PERCENT_RANK`, and `PERCENTILE_CONT`. |
| `04_ZIP_Census_Geographic_Queries_and_KML.sql` | 10 geographic queries on ZIP-code census data (population, income, poverty, vacancy, commute, education, rent) and a query that generates KML placemarks for the 2,000 ZIP codes with the highest housing vacancy among those above 20%. |
| `05_Parameterized_Functions.sql` | 10 parameterized functions, for example ZIP codes by minimum population and household size, housing affordability, rent compared with income, and customers with a minimum number of orders. |
| `06_Probability_and_ZScore_Functions.sql` | Factorial, combination, binomial-probability, and z-score functions, used in 10 queries such as the chance that a purchase comes from a given channel or state, and how unusual a month's demand or revenue is. |
| `07_Subscriber_Tenure_Lookup_Model.sql` | A lookup model that predicts subscriber tenure from channel, rate plan, and market, built on subscribers who started in 2004 and scored on 2005 starters, then checked with a 10-group value chart (`NTILE(10)`). |

## Selected findings

- Average web-channel order value rose from about $79 (2012) to about $102 (2015).
- Average order value by payment type was highest for payment type AE (about $98) and lowest for OC (about $32).
- The best revenue month was December in every year from 2010 to 2015.
- The number of customers who bought in one year but not the next grew from 20,254 (2012 to 2013) to 43,501 (2014 to 2015), alongside a growing customer base.

## Tools

T-SQL (SQL Server), CTEs, window functions, cursors, user-defined functions, constraints, Excel charts.

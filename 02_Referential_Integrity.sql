USE SQLBook;
GO


/* ============================================================
   1. Customers → Orders
   ============================================================ */

/* Check for CustomerIds in Orders that do not exist in Customers */
SELECT CustomerId
FROM SQLBook.dbo.Orders

EXCEPT

SELECT CustomerId
FROM SQLBook.dbo.Customers;
GO


/* Remove Orders with CustomerIds that do not exist in Customers */
DELETE FROM SQLBook.dbo.Orders
WHERE CustomerId IN
(
    SELECT CustomerId
    FROM SQLBook.dbo.Orders

    EXCEPT

    SELECT CustomerId
    FROM SQLBook.dbo.Customers
);
GO


/* Checked again to ensure that all orphaned CustomerIds were removed */


/* Enforce referential integrity between Customers and Orders */

/* Ensure the Parent Key cannot contain NULL values */
ALTER TABLE SQLBook.dbo.Customers
ALTER COLUMN CustomerId INT NOT NULL;
GO

/* Match the data type of the Child Key with the Parent Key */
ALTER TABLE SQLBook.dbo.Orders
ALTER COLUMN CustomerId INT;
GO

/* Create Foreign Key constraint */
ALTER TABLE SQLBook.dbo.Orders
ADD CONSTRAINT FK_CustomerId
FOREIGN KEY (CustomerId)
REFERENCES SQLBook.dbo.Customers(CustomerId);
GO



/* ============================================================
   2. Orders → OrderLines
   ============================================================ */

/* Check for OrderIds in OrderLines that do not exist in Orders */
SELECT OrderId
FROM SQLBook.dbo.OrderLines

EXCEPT

SELECT OrderId
FROM SQLBook.dbo.Orders;
GO


/* Remove OrderLines with OrderIds that do not exist in Orders */
DELETE FROM SQLBook.dbo.OrderLines
WHERE OrderId IN
(
    SELECT OrderId
    FROM SQLBook.dbo.OrderLines

    EXCEPT

    SELECT OrderId
    FROM SQLBook.dbo.Orders
);
GO


/* Checked again to ensure that all orphaned OrderIds were removed */


/* Enforce referential integrity between Orders and OrderLines */

/* Ensure the Parent Key cannot contain NULL values */
ALTER TABLE SQLBook.dbo.Orders
ALTER COLUMN OrderId INT NOT NULL;
GO

/* Match the data type of the Child Key with the Parent Key */
ALTER TABLE SQLBook.dbo.OrderLines
ALTER COLUMN OrderId INT NOT NULL;
GO

/* Create Foreign Key constraint */
ALTER TABLE SQLBook.dbo.OrderLines
ADD CONSTRAINT FK_OrderId
FOREIGN KEY (OrderId)
REFERENCES SQLBook.dbo.Orders(OrderId);
GO



/* ============================================================
   3. Products → OrderLines
   ============================================================ */

/* Check for ProductIds in OrderLines that do not exist in Products */
SELECT ProductId
FROM SQLBook.dbo.OrderLines

EXCEPT

SELECT ProductId
FROM SQLBook.dbo.Products;
GO


/* Remove OrderLines with ProductIds that do not exist in Products */
DELETE FROM SQLBook.dbo.OrderLines
WHERE ProductId IN
(
    SELECT ProductId
    FROM SQLBook.dbo.OrderLines

    EXCEPT

    SELECT ProductId
    FROM SQLBook.dbo.Products
);
GO


/* Checked again to ensure that all orphaned ProductIds were removed */


/* Enforce referential integrity between Products and OrderLines */

/* Ensure the Parent Key cannot contain NULL values */
ALTER TABLE SQLBook.dbo.Products
ALTER COLUMN ProductId INT NOT NULL;
GO

/* Match the data type of the Child Key with the Parent Key */
ALTER TABLE SQLBook.dbo.OrderLines
ALTER COLUMN ProductId INT;
GO

/* Create Foreign Key constraint */
ALTER TABLE SQLBook.dbo.OrderLines
ADD CONSTRAINT FK_ProductId
FOREIGN KEY (ProductId)
REFERENCES SQLBook.dbo.Products(ProductId);
GO



/* ============================================================
   4. Campaigns → Orders
   ============================================================ */

/* Check for CampaignIds in Orders that do not exist in Campaigns */
SELECT CampaignId
FROM SQLBook.dbo.Orders

EXCEPT

SELECT CampaignId
FROM SQLBook.dbo.Campaigns;
GO


/* Remove Orders with CampaignIds that do not exist in Campaigns */
DELETE FROM SQLBook.dbo.Orders
WHERE CampaignId IN
(
    SELECT CampaignId
    FROM SQLBook.dbo.Orders

    EXCEPT

    SELECT CampaignId
    FROM SQLBook.dbo.Campaigns
);
GO


/* Checked again to ensure that all orphaned CampaignIds were removed */


/* Enforce referential integrity between Campaigns and Orders */

/* Ensure the Parent Key cannot contain NULL values */
ALTER TABLE SQLBook.dbo.Campaigns
ALTER COLUMN CampaignId INT NOT NULL;
GO

/* Match the data type of the Child Key with the Parent Key */
ALTER TABLE SQLBook.dbo.Orders
ALTER COLUMN CampaignId INT NOT NULL;
GO

/* Create Foreign Key constraint */
ALTER TABLE SQLBook.dbo.Orders
ADD CONSTRAINT FK_CampaignId
FOREIGN KEY (CampaignId)
REFERENCES SQLBook.dbo.Campaigns(CampaignId);
GO



/* ============================================================
   5. ZipCensus → Orders
   ============================================================ */

/* Check for ZipCodes in Orders that do not exist in ZipCensus */
SELECT ZipCode
FROM SQLBook.dbo.Orders

EXCEPT

SELECT zcta5
FROM SQLBook.dbo.ZipCensus;
GO


/* Remove OrderLines that belong to Orders with invalid ZipCodes */
DELETE FROM SQLBook.dbo.OrderLines
WHERE OrderId IN
(
    SELECT OrderId
    FROM SQLBook.dbo.Orders
    WHERE ZipCode IN
    (
        SELECT ZipCode
        FROM SQLBook.dbo.Orders

        EXCEPT

        SELECT zcta5
        FROM SQLBook.dbo.ZipCensus
    )
);
GO


/* Remove Orders with ZipCodes that do not exist in ZipCensus */
DELETE FROM SQLBook.dbo.Orders
WHERE ZipCode IN
(
    SELECT ZipCode
    FROM SQLBook.dbo.Orders

    EXCEPT

    SELECT zcta5
    FROM SQLBook.dbo.ZipCensus
);
GO


/* Checked again to ensure that all orphaned ZipCodes were removed */


/* Enforce referential integrity between ZipCensus and Orders */

/* Ensure the Parent Key cannot contain NULL values */
ALTER TABLE SQLBook.dbo.ZipCensus
ALTER COLUMN zcta5 VARCHAR(50) NOT NULL;
GO

/* Create Primary Key on the Parent Key */
ALTER TABLE SQLBook.dbo.ZipCensus
ADD CONSTRAINT PK_ZipCensus
PRIMARY KEY (zcta5);
GO

/* Match the data type of the Child Key with the Parent Key */
ALTER TABLE SQLBook.dbo.Orders
ALTER COLUMN ZipCode VARCHAR(50) NOT NULL;
GO

/* Create Foreign Key constraint */
ALTER TABLE SQLBook.dbo.Orders
ADD CONSTRAINT FK_ZipCode
FOREIGN KEY (ZipCode)
REFERENCES SQLBook.dbo.ZipCensus(zcta5);
GO



/* ============================================================
   6. Calendar → Orders
   ============================================================ */

/* Check for OrderDates in Orders that do not exist in Calendar */
SELECT OrderDate
FROM SQLBook.dbo.Orders

EXCEPT

SELECT Date
FROM SQLBook.dbo.Calendar;
GO


/* Remove Orders with OrderDates that do not exist in Calendar */
DELETE FROM SQLBook.dbo.Orders
WHERE OrderDate IN
(
    SELECT OrderDate
    FROM SQLBook.dbo.Orders

    EXCEPT

    SELECT Date
    FROM SQLBook.dbo.Calendar
);
GO


/* Checked again to ensure that all orphaned OrderDates were removed */


/* Enforce referential integrity between Calendar and Orders */

/* Ensure the Parent Key cannot contain NULL values */
ALTER TABLE SQLBook.dbo.Calendar
ALTER COLUMN Date DATE NOT NULL;
GO

/* Create Primary Key on the Parent Key */
ALTER TABLE SQLBook.dbo.Calendar
ADD CONSTRAINT PK_Calendar
PRIMARY KEY (Date);
GO

/* Match the data type of the Child Key with the Parent Key */
ALTER TABLE SQLBook.dbo.Orders
ALTER COLUMN OrderDate DATE NOT NULL;
GO

/* Create Foreign Key constraint */
ALTER TABLE SQLBook.dbo.Orders
ADD CONSTRAINT FK_OrderDate
FOREIGN KEY (OrderDate)
REFERENCES SQLBook.dbo.Calendar(Date);
GO



/* ============================================================
   7. ZipCensus → ZipCounty
   ============================================================ */

/* Check for ZipCodes in ZipCounty that do not exist in ZipCensus */
SELECT ZipCode
FROM SQLBook.dbo.ZipCounty
WHERE ZipCode IS NOT NULL

EXCEPT

SELECT zcta5
FROM SQLBook.dbo.ZipCensus;
GO


/* Remove ZipCounty records with ZipCodes that do not exist in ZipCensus */
DELETE FROM SQLBook.dbo.ZipCounty
WHERE ZipCode IN
(
    SELECT ZipCode
    FROM SQLBook.dbo.ZipCounty
    WHERE ZipCode IS NOT NULL

    EXCEPT

    SELECT zcta5
    FROM SQLBook.dbo.ZipCensus
);
GO


/* Checked again to ensure that all orphaned ZipCodes were removed */


/* Enforce referential integrity between ZipCensus and ZipCounty */

/* Ensure the Parent Key cannot contain NULL values */
ALTER TABLE SQLBook.dbo.ZipCensus
ALTER COLUMN zcta5 VARCHAR(50) NOT NULL;
GO

/* Match the data type of the Child Key with the Parent Key */
ALTER TABLE SQLBook.dbo.ZipCounty
ALTER COLUMN ZipCode VARCHAR(50);
GO

/* Create Foreign Key constraint */
ALTER TABLE SQLBook.dbo.ZipCounty
ADD CONSTRAINT FK_ZipCounty_ZipCode
FOREIGN KEY (ZipCode)
REFERENCES SQLBook.dbo.ZipCensus(zcta5);
GO



/* ============================================================
   Final Verification
   ============================================================ */

/* Verify all Primary Key and Foreign Key constraints */
SELECT
    OBJECT_NAME(parent_object_id) AS TableName,
    name AS ConstraintName,
    type_desc AS ConstraintType
FROM sys.objects
WHERE type IN ('PK', 'F')
ORDER BY TableName, ConstraintType;
GO


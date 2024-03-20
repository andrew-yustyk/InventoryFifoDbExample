IF OBJECT_ID('dbo.GetPurchaseLinesForFifo2') IS NOT NULL
    DROP FUNCTION dbo.GetPurchaseLinesForFifo2;
GO;

CREATE FUNCTION dbo.GetPurchaseLinesForFifo2(@UnitID int, @CountDate date, @BaseQuantity decimal(12, 2))
    RETURNS TABLE AS RETURN
        SELECT ItemID
             , SUM(Cost * Quantity) AS TotalCost
             , SUM(Quantity) AS LifoTotalQuantity
             --, MAX(LifoTotalQuantity) as LifoTotalQuantity -- alternative option instead of SUM(Quantity)
            FROM (
                /* Here we process each previously selected PurchaseLine row and normalize its quantity (and LifoTotalQuantity)
                   depending on the base quantity (current inventory items quantity).
                   By comparing previously calculated LifoTotalQuantity and the base quantity we decide should be the row included
                   or excluded from the inventory cost calculation:
                     - if LifoTotalQuantity <= BaseQuantity, then this row still should be fully included in the calculation;
                     - if LifoTotalQuantity > BaseQuantity, then we need either include only part of the row's quantity or exclude it.
                   For partial inclusion, we must calculate the amount by which the current LifoTotalQuantity exceeds the base amount
                   and decrease the PurchaseLine Quantity by this difference: Quantity = Quantity - (LifoTotalQuantity - BaseQuantity).
                   If result quantity is less then 0, then we set it to 0 because zero quantity can safely be included in the
                   weighted average cost calculation while negative number - can't and we should care about its filtering. */
                /* ------------------------------------------------------------------------------------------------------
                   | Cost  | Quantity | LifoTotalQuantity | QuantityOriginal | LifoTotalQuantityOriginal | BusinessDate |
                   | ----- | -------- | ----------------- | ---------------- | ------------------------- | ------------ |
                   | 15.00 | 40.00    | 40.00             | 40.00            | 40.00                     | 2023-12-07   |
                   | 20.00 | 25.00    | 65.00             | 25.00            | 65.00                     | 2023-12-06   |
                   | 20.00 | 30.00    | 95.00             | 30.00            | 95.00                     | 2023-12-05   |
                   | 18.00 |  5.00    | 100.00            | 45.00            | 140.00                    | 2023-12-04   |
                   | 17.00 |  0.00    | 100.00            | 20.00            | 160.00                    | 2023-12-03   |
                   ------------------------------------------------------------------------------------------------------ */
                SELECT ItemID AS ItemID
                     , Cost AS Cost
                     , IIF(LifoTotalQuantity > @BaseQuantity, GREATEST(Quantity - LifoTotalQuantity + @BaseQuantity, 0), Quantity) AS Quantity
                     --, LEAST(LifoTotalQuantity, @BaseQuantity) AS LifoTotalQuantity -- alternative option for max quantity
                     --, Quantity as QuantityOriginal -- for debug
                     --, LifoTotalQuantity as LifoTotalQuantityOriginal -- for debug
                     --, BusinessDate as BusinessDate -- for debug
                    FROM (
                        /* ----------------------------------------------------------------
                           | ItemID | Cost  | Quantity | LifoTotalQuantity | BusinessDate |
                           |      5 | ----- | -------- | ----------------- | ------------ |
                           |      5 | 15.00 | 40.00    | 40.00             | 2023-12-07   |
                           |      5 | 20.00 | 25.00    | 65.00             | 2023-12-06   |
                           |      5 | 20.00 | 30.00    | 95.00             | 2023-12-05   |
                           |      5 | 18.00 | 45.00    | 140.00            | 2023-12-04   |
                           |      5 | 17.00 | 20.00    | 160.00            | 2023-12-03   |
                           ---------------------------------------------------------------- */
                        SELECT pl.ItemID AS ItemID
                             , pl.Cost AS Cost
                             , pl.Quantity AS Quantity
                             , SUM(pl.Quantity) OVER (PARTITION BY pl.ItemID ORDER BY ph.BusinessDate DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS LifoTotalQuantity
                             --, ph.BusinessDate as BusinessDate -- for debug
                            FROM PurchaseLine AS pl
                            INNER JOIN dbo.PurchaseHeader ph ON pl.PurchaseHeaderID = ph.PurchaseHeaderID
                            WHERE ph.BusinessDate < @CountDate AND ph.UnitID = @UnitID) AS x1 -- lifo-qty-aggregation-weighted purchase lines
                    WHERE Quantity - LifoTotalQuantity + @BaseQuantity > 0 -- cut unnecessary rows
            ) AS x2 -- lifo-qty-aggregation-weighted purchase lines but quantity of the last item is corrected to prevent exceeding @BaseQuantity.
            GROUP BY ItemID;
GO;

DECLARE @UnitID int = 5;
DECLARE @CountDate date = '2024-01-01';
DECLARE @BaseQuantity decimal(12, 2) = 1000;
SELECT *
    FROM dbo.GetPurchaseLinesForFifo2(@UnitID, @CountDate, @BaseQuantity)
    ORDER BY ItemID;


/*
 * INLINE implementation. WIP
 */
DECLARE @UnitID int = 5;
DECLARE @CountDate date = '2024-01-01';
SET @UnitID = 1;
SET @CountDate = '2023-12-08';

WITH
    pchItems1 AS (
        SELECT pl.ItemID AS ItemID
             , pl.Cost AS Cost
             , pl.Quantity AS Quantity
             , inv.Quantity AS BaseQuantity
             , SUM(pl.Quantity) OVER (PARTITION BY pl.ItemID ORDER BY ph.BusinessDate DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS LifoTotalQuantity
            FROM PurchaseLine AS pl
            INNER JOIN dbo.PurchaseHeader ph ON pl.PurchaseHeaderID = ph.PurchaseHeaderID
            INNER JOIN dbo.Inventory AS inv ON inv.UnitID = @UnitID AND inv.BusinessDate = @CountDate AND pl.ItemID = inv.ItemID
            WHERE ph.BusinessDate < @CountDate AND ph.UnitID = @UnitID),
    pchItems2 AS (
        SELECT ItemID AS ItemID
             , Cost AS Cost
             , IIF(LifoTotalQuantity > BaseQuantity, GREATEST(Quantity - LifoTotalQuantity + BaseQuantity, 0), Quantity) AS Quantity
             , BaseQuantity AS BaseQuantity
            FROM pchItems1
            WHERE Quantity - LifoTotalQuantity + BaseQuantity > 0),
    totals    AS (
        SELECT ItemID
             , SUM(Cost * Quantity) AS TotalCost
             , SUM(Quantity) AS LifoTotalQuantity
             , BaseQuantity AS BaseQuantity
            FROM pchItems2
            GROUP BY ItemID, BaseQuantity)
SELECT calcItems.ItemID,
       (CASE
            WHEN totals.ItemID IS NULL
                THEN (
                SELECT TOP (1) ISNULL(pl.Cost, 0)
                    FROM dbo.PurchaseLine AS pl
                    INNER JOIN dbo.PurchaseHeader ph
                        ON pl.PurchaseHeaderID = ph.PurchaseHeaderID
                    WHERE ph.UnitID = @UnitID AND ph.BusinessDate < @CountDate AND pl.ItemID = calcItems.ItemID
                    ORDER BY ph.BusinessDate DESC)
            WHEN totals.LifoTotalQuantity >= totals.BaseQuantity
                THEN CASE
                         WHEN totals.LifoTotalQuantity = totals.BaseQuantity
                             THEN totals.TotalCost / totals.LifoTotalQuantity
                             ELSE 1 / 0 -- should be impossible in real life
                     END
            ELSE 42
        END) AS FIFO
    FROM ItemsToCalcCost AS calcItems
    LEFT JOIN totals
        ON calcItems.ItemID = totals.ItemID;

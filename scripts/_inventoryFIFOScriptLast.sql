DECLARE @UnitID int = 1;
DECLARE @CountDate date = '2023-12-08';
-- SET @UnitID = 5;
-- SET @CountDate = '2024-01-01';

WITH
    pchItems1 AS (
     /* -------------------------------------------------------------------------------
        | ItemID | Cost  | Quantity | BaseQuantity | LifoTotalQuantity | BusinessDate |
        | ------ | ----- | -------- | ------------ | ----------------- | ------------ |
        |      5 | 15.00 | 40.00    |          100 | 40.00             | 2023-12-07   |
        |      5 | 20.00 | 25.00    |          100 | 65.00             | 2023-12-06   |
        |      5 | 20.00 | 30.00    |          100 | 95.00             | 2023-12-05   |
        |      5 | 18.00 | 45.00    |          100 | 140.00            | 2023-12-04   |
        |      5 | 17.00 | 20.00    |          100 | 160.00            | 2023-12-03   |
        ------------------------------------------------------------------------------- */
        SELECT pl.ItemID AS ItemID
             , pl.Cost AS Cost
             , pl.Quantity AS Quantity
             , inv.Quantity AS BaseQuantity
             , SUM(pl.Quantity) OVER (PARTITION BY pl.ItemID ORDER BY ph.BusinessDate DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS LifoTotalQuantity
             --, ph.BusinessDate as BusinessDate -- for debug only
            FROM PurchaseLine AS pl
            INNER JOIN dbo.PurchaseHeader ph ON pl.PurchaseHeaderID = ph.PurchaseHeaderID
            INNER JOIN dbo.Inventory AS inv ON inv.UnitID = @UnitID AND inv.BusinessDate = @CountDate AND pl.ItemID = inv.ItemID
            WHERE ph.BusinessDate < @CountDate AND ph.UnitID = @UnitID),
    pchItems2 AS (
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
     /* ------------------------------------------------------------------------------------------------------------------------------
        | ItemID | Cost  | Quantity | BaseQuantity | LifoTotalQuantity | QuantityOriginal | LifoTotalQuantityOriginal | BusinessDate |
        | ------ | ----- | -------- | ------------ | ----------------- | ---------------- | ------------------------- | ------------ |
        |      1 | 15.00 | 40.00    |          100 | 40.00             | 40.00            | 40.00                     | 2023-12-07   |
        |      2 | 20.00 | 25.00    |          100 | 65.00             | 25.00            | 65.00                     | 2023-12-06   |
        |      3 | 20.00 | 30.00    |          100 | 95.00             | 30.00            | 95.00                     | 2023-12-05   |
        |      4 | 18.00 |  5.00    |          100 | 100.00            | 45.00            | 140.00                    | 2023-12-04   |
        |      5 | 17.00 |  0.00    |          100 | 100.00            | 20.00            | 160.00                    | 2023-12-03   |
        ------------------------------------------------------------------------------------------------------------------------------ */
        SELECT ItemID AS ItemID
             , Cost AS Cost
             , IIF(LifoTotalQuantity > BaseQuantity, GREATEST(Quantity - LifoTotalQuantity + BaseQuantity, 0), Quantity) AS Quantity
             , BaseQuantity AS BaseQuantity
             --, LEAST(LifoTotalQuantity, @BaseQuantity) AS LifoTotalQuantity -- alternative option for max quantity calculation
             --, Quantity as QuantityOriginal -- for debug
             --, LifoTotalQuantity as LifoTotalQuantityOriginal -- for debug
             --, BusinessDate as BusinessDate -- for debug
            FROM pchItems1
            WHERE Quantity - LifoTotalQuantity + BaseQuantity > 0), -- cut unnecessary rows that overflow the base quantity
    totals    AS (
     /* ----------------------------------------------------------
        | ItemID | TotalCost  | LifoTotalQuantity | BaseQuantity |
        | ------ | ---------- | ----------------- | ------------ |
        |      1 |  1100.0000 |             65.00 |          100 |
        |      2 |  1380.0000 |            100.00 |          100 |
        |      3 |  1100.0000 |             65.00 |          100 |
        |      4 |  1100.0000 |             65.00 |          100 |
        |      5 |  1790.0000 |            100.00 |          100 |
        ---------------------------------------------------------- */
        SELECT ItemID
             , SUM(Cost * Quantity) AS TotalCost
             , SUM(Quantity) AS LifoTotalQuantity
             --, MAX(LifoTotalQuantity) as LifoTotalQuantity -- alternative option instead of SUM(Quantity)
             , BaseQuantity AS BaseQuantity
            FROM pchItems2
            GROUP BY ItemID, BaseQuantity)
SELECT calcItems.ItemID,
       CAST((CASE
                 WHEN totals.ItemID IS NULL
                     THEN (
                     -- select the "Cost" value from the last "PurchaseLine" record if the "Inventory" record for the count date is missing
                     SELECT TOP (1) ISNULL(pl.Cost, 0)
                         FROM dbo.PurchaseLine AS pl
                         INNER JOIN dbo.PurchaseHeader ph
                             ON pl.PurchaseHeaderID = ph.PurchaseHeaderID
                         WHERE ph.UnitID = @UnitID AND ph.BusinessDate < @CountDate AND pl.ItemID = calcItems.ItemID
                         ORDER BY ph.BusinessDate DESC)
                 WHEN totals.LifoTotalQuantity >= totals.BaseQuantity
                     THEN CASE
                              -- the main flow when we can calculate FIFO cost only from the "PurchaseLine" records
                              WHEN totals.LifoTotalQuantity = totals.BaseQuantity
                                  THEN totals.TotalCost / totals.LifoTotalQuantity
                                  ELSE 1 / 0 -- should be impossible in real life
                          END
                     ELSE (
                         SELECT TOP (1)
                             -- the last case when we can get only a part of required data from the "PurchaseLine" records,
                             -- here we add the missing rest values from the previous "Inventory" record.
                             ((totals.TotalCost + LEAST(ISNULL(prevInv.Quantity, 0), totals.BaseQuantity - totals.LifoTotalQuantity) * prevInv.Cost)) /
                             (totals.LifoTotalQuantity + LEAST(ISNULL(prevInv.Quantity, 0), totals.BaseQuantity - totals.LifoTotalQuantity))
                             FROM dbo.Inventory AS prevInv
                             WHERE prevInv.UnitID = @UnitID AND prevInv.BusinessDate < @CountDate AND prevInv.ItemID = calcItems.ItemID
                             ORDER BY prevInv.BusinessDate DESC)
             END) AS decimal(38, 6)) AS FIFO
    FROM dbo.ItemsToCalcCost AS calcItems
    LEFT JOIN totals
        ON calcItems.ItemID = totals.ItemID;

IF OBJECT_ID('dbo.GetFiFo') IS NOT NULL
    DROP FUNCTION dbo.GetFiFo;
GO;

IF OBJECT_ID('dbo.GetLastPurchaseCost') IS NOT NULL
    DROP FUNCTION dbo.GetLastPurchaseCost;
GO;

IF OBJECT_ID('dbo.GetNormalizedPurchaseLinesForFifo') IS NOT NULL
    DROP FUNCTION dbo.GetNormalizedPurchaseLinesForFifo;
GO;


CREATE FUNCTION dbo.GetLastPurchaseCost(@UnitID int, @CountDate date, @ItemID int) RETURNS decimal(8, 2)
AS
BEGIN
    /* TODO: Need to clarify a case with a possible collision when 2+ purchases with different prices
       took place on the same day, for the same unit and item. */
    DECLARE @lastPchCost decimal(8, 2);
    SELECT TOP (1) @lastPchCost = ISNULL(pl.Cost, 0)
        FROM dbo.PurchaseLine AS pl
        INNER JOIN dbo.PurchaseHeader ph
            ON pl.PurchaseHeaderID = ph.PurchaseHeaderID
        WHERE ph.BusinessDate < @CountDate AND pl.ItemID = @ItemID
          AND ph.UnitID = @UnitID /* maybe need to reorder item and unit, depends on data distribution */
        ORDER BY ph.BusinessDate DESC;

    RETURN ISNULL(@lastPchCost, 0);
END;
GO;


CREATE FUNCTION dbo.GetNormalizedPurchaseLinesForFifo(@UnitID int, @CountDate date, @ItemID int, @BaseQuantity decimal(12, 2))
    RETURNS TABLE AS RETURN
        /* Here we get all purchased lines for specified "UnitID" and "ItemID" that were added
           before the current inventory calculation and after the previous inventory calculation.
           An additional value "LifoTotalQuantity" for each row means a sum of the quantity for "this" and newer rows
           because in FIFO inventory calculation we assume that older items were sold and we should take into account
           only the newer rows whose sum is equal or exceeds the BaseQuantity (current inventory items quantity).
           Based on this field we can decide whether the row should be fully included, partially included,
           or excluded from the inventory cost calculation.
           -------------------------------------------------------
           | Cost  | Quantity | LifoTotalQuantity | BusinessDate |
           |-------|----------|-------------------|--------------|
           | 15.00 | 40.00    | 40.00             | 2023-12-07   |
           | 20.00 | 25.00    | 65.00             | 2023-12-06   |
           | 20.00 | 30.00    | 95.00             | 2023-12-05   |
           | 18.00 | 45.00    | 140.00            | 2023-12-04   |
           | 17.00 | 20.00    | 160.00            | 2023-12-03   |
           ------------------------------------------------------- */
        WITH purchaseLinesWithLIFOAggregatedQuantity AS (
            SELECT pl.Cost AS Cost
                 , pl.Quantity AS Quantity
                /* TODO: here we still have a collision in a case of 2+ purchases with different prices for the same date */
                 , SUM(pl.Quantity) OVER (ORDER BY ph.BusinessDate DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS LifoTotalQuantity
                 , ph.BusinessDate AS BusinessDate -- FOR DEBUG ONLY
                FROM PurchaseLine AS pl
                INNER JOIN dbo.PurchaseHeader ph
                    ON pl.PurchaseHeaderID = ph.PurchaseHeaderID
                WHERE ph.BusinessDate < @CountDate AND ph.UnitID = @UnitID AND pl.ItemID = @ItemID
            -- AND pl.Quantity > 0 /* there is no make sense to select lines with qty > 0 as they don't affect weighted average cost, but depends on DB constraints */
        )
        /* Here we process each previously selected PurchaseLine row and normalize its quantity (and LifoTotalQuantity)
           depending on the base quantity (current inventory items quantity).
           By comparing previously calculated LifoTotalQuantity and the base quantity we decide should be the row included
           or excluded from the inventory cost calculation:
             - if LifoTotalQuantity <= BaseQuantity, then this row still should be fully included in the calculation;
             - if LifoTotalQuantity > BaseQuantity, then we need either include only part of the row's quantity or exclude it.
               For partial inclusion, we must calculate the amount by which the current LifoTotalQuantity exceeds the base amount
               and decrease the PurchaseLine Quantity by this difference: Quantity = Quantity - (LifoTotalQuantity - BaseQuantity).
               If result quantity is less then 0, then we set it to 0 because zero quantity can safely be included in the
               weighted average cost calculation while negative number - can't and we should care about its filtering.
           ------------------------------------------------------------------------------------------------------
           | Cost  | Quantity | LifoTotalQuantity | QuantityOriginal | LifoTotalQuantityOriginal | BusinessDate |
           | ----- | -------- | ----------------- | ---------------- | ------------------------- | ------------ |
           | 15.00 | 40.00    | 40.00             | 40.00            | 40.00                     | 2023-12-07   |
           | 20.00 | 25.00    | 65.00             | 25.00            | 65.00                     | 2023-12-06   |
           | 20.00 | 30.00    | 95.00             | 30.00            | 95.00                     | 2023-12-05   |
           | 18.00 |  5.00    | 100.00            | 45.00            | 140.00                    | 2023-12-04   |
           | 17.00 |  0.00    | 100.00            | 20.00            | 160.00                    | 2023-12-03   |
           ------------------------------------------------------------------------------------------------------ */
        SELECT Cost AS Cost
             , IIF(LifoTotalQuantity > @BaseQuantity, GREATEST(Quantity - LifoTotalQuantity + @BaseQuantity, 0), Quantity) AS Quantity
             , LEAST(LifoTotalQuantity, @BaseQuantity) AS LifoTotalQuantity -- May be unnecessary, need to compare Sum(Quantity) and Max(LifoTotalQuantity) performance.
             , BusinessDate AS BusinessDate                                 -- FOR DEBUG ONLY
             , Quantity AS QuantityOriginal                                 -- FOR DEBUG ONLY
             , LifoTotalQuantity AS LifoTotalQuantityOriginal               -- FOR DEBUG ONLY
            FROM purchaseLinesWithLIFOAggregatedQuantity;
GO;


CREATE FUNCTION dbo.GetFiFo(@UnitID int, @CountDate date, @ItemID int) RETURNS decimal(8, 2)
AS
BEGIN
    DECLARE @baseQty decimal(12, 2);
    SELECT @baseQty = Quantity
        FROM dbo.Inventory
        WHERE BusinessDate = @CountDate AND UnitID = @UnitID AND ItemID = @ItemID
        ORDER BY BusinessDate DESC;

    /* If there is no record with the requested date in the Inventory table,
       then we need to return a last purchase cost. */
    IF (@baseQty IS NULL)
        RETURN dbo.GetLastPurchaseCost(@UnitID, @CountDate, @ItemID);

    IF (0 = @baseQty)
        RETURN 0; /* Skip inventory cost calculation if there are no items in it. */

    DECLARE @totalCost decimal(8, 2);
    DECLARE @totalQuantity decimal(12, 2);
    SELECT @totalCost = SUM(Cost * Quantity), @totalQuantity = MAX(LifoTotalQuantity)
        FROM dbo.GetNormalizedPurchaseLinesForFifo(@UnitID, @CountDate, @ItemId, @baseQty)
        WHERE Quantity > 0;

    IF (@totalQuantity > @baseQty)
        RETURN 1 / 0; /* Should never occur in real life. */

    IF (@totalQuantity = @baseQty)
        RETURN @totalCost / @totalQuantity;

    DECLARE @prevInvCost decimal(8, 2);
    DECLARE @prevInvQty decimal(12, 2);
    SELECT @prevInvCost = ISNULL(inv.Cost, 0), @prevInvQty = ISNULL(inv.Quantity, 0)
        FROM dbo.Inventory AS inv
        WHERE inv.BusinessDate < @CountDate AND inv.UnitID = @UnitID AND inv.ItemID = @ItemID;

    SET @prevInvQty = LEAST(@prevInvQty, @baseQty - @totalQuantity);
    SET @totalQuantity = @totalQuantity + @prevInvQty;
    SET @totalCost = @totalCost + @prevInvCost * @prevInvQty;

    RETURN @totalCost / @totalQuantity;
END;
GO;

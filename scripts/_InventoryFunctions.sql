IF OBJECT_ID('dbo.GetFiFo') IS NOT NULL
    DROP FUNCTION dbo.GetFiFo;
GO;

IF OBJECT_ID('dbo.GetLastPurchaseCost') IS NOT NULL
    DROP FUNCTION dbo.GetLastPurchaseCost;
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
        WHERE ph.BusinessDate < @CountDate
          AND pl.ItemID = @ItemID
          AND ph.UnitID = @UnitID /* maybe need to reorder item and unit, depends on data distribution */
        ORDER BY ph.BusinessDate DESC;

    RETURN ISNULL(@lastPchCost, 0);
END;
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
    IF @baseQty IS NULL
        RETURN dbo.GetLastPurchaseCost(@UnitID, @CountDate, @ItemID);

    /* TODO: Implement main algorithm */
    RETURN 42;
END;
GO;

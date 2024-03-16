IF OBJECT_ID('[dbo].[GetFiFo]') IS NOT NULL
    BEGIN
        DROP FUNCTION [dbo].[GetFiFo]
    END;
GO;

IF OBJECT_ID('[dbo].[GetLastPurchase]') IS NOT NULL
    BEGIN
        DROP FUNCTION [dbo].[GetLastPurchase]
    END;
GO;

CREATE FUNCTION [dbo].[GetLastPurchase](@unit int, @date date, @item int) RETURNS decimal(8, 2)
AS
BEGIN
    DECLARE @lastPch decimal(8, 2)
    SELECT TOP (1) @lastPch = pl.[Cost]
        FROM [dbo].[PurchaseLine] AS pl
            INNER JOIN [dbo].[PurchaseHeader] ph
                ON pl.PurchaseHeaderID = ph.PurchaseHeaderID
        WHERE ph.BusinessDate < @date
          AND pl.ItemID = @item
          AND ph.UnitID = @unit /* maybe need to reorder item and unit? depends on data distribution */
        ORDER BY ph.BusinessDate DESC;

    RETURN ISNULL(@lastPch, 0);
END;
GO;

CREATE FUNCTION [dbo].[GetFiFo](@unit int, @date date, @item int) RETURNS decimal(8, 2)
AS
BEGIN
    DECLARE @baseQty decimal(12, 2);
    SELECT @baseQty = [Quantity]
        FROM [dbo].[Inventory]
        WHERE [BusinessDate] = @date AND [UnitID] = @unit AND [ItemID] = @item
        ORDER BY [BusinessDate] DESC;

    /* If there is no record with the requested date in the Inventory table,
       then we need to return a last purchase cost. */
    IF @baseQty IS NULL
        RETURN dbo.GetLastPurchase(@unit, @date, @item)

    /* TODO: Implement main algorithm */
    RETURN 42;
END;
GO;

SELECT [ItemID] AS ItemID,
       [dbo].[GetFiFo](1, '2023-12-08', ItemID)
    FROM [dbo].[ItemsToCalcCost];

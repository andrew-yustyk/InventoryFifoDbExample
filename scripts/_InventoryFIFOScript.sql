DECLARE @UnitID int = 1;
DECLARE @CountDate date = '2023-12-08';

/* For dbo.GetFiFo(...) please check _InventoryFunctions.sql */
SELECT ItemID AS ItemID, dbo.GetFiFo(@UnitID, @CountDate, ItemID) AS FIFO
    FROM dbo.ItemsToCalcCost;

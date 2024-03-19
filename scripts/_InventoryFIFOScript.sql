DECLARE @UnitID int = 1;
DECLARE @CountDate date = '2023-12-08';
-- SET @UnitID = 5;
-- SET @CountDate = '2024-01-01';

/* For dbo.GetFiFo(...) please check _InventoryFunctions.sql */
SELECT DISTINCT ItemID AS ItemID, CAST(dbo.GetFiFo(@UnitID, @CountDate, ItemID) as decimal(38, 2)) AS FIFO
    FROM dbo.ItemsToCalcCost;

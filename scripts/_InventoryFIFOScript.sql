DECLARE @UnitID int = 1;
DECLARE @CountDate date = '2023-12-08';
SELECT ItemID AS ItemID, dbo.GetFiFo(@UnitID, @CountDate, ItemID) AS FIFO
    FROM dbo.ItemsToCalcCost;

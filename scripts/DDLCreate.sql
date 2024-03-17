IF (OBJECT_ID('dbo.PurchaseHeader', 'U') IS NULL)
    BEGIN
        CREATE TABLE dbo.PurchaseHeader
        (
            PurchaseHeaderID uniqueidentifier NOT NULL,
            UnitID           int              NOT NULL,
            BusinessDate     date             NOT NULL,
            CONSTRAINT PK_PurchaseHeader PRIMARY KEY NONCLUSTERED (PurchaseHeaderID)
        );

        CREATE CLUSTERED INDEX CIX_PurchaseHeader ON dbo.PurchaseHeader (UnitID, BusinessDate);
    END;

IF (OBJECT_ID('dbo.PurchaseLine', 'U') IS NULL)
    BEGIN
        CREATE TABLE dbo.PurchaseLine
        (
            PurchaseLineID   uniqueidentifier NOT NULL,
            PurchaseHeaderID uniqueidentifier NOT NULL,
            ItemID           int              NOT NULL,
            Quantity         decimal(12, 2)   NOT NULL,
            Cost             decimal(8, 2)    NOT NULL,
            CONSTRAINT PK_PurchaseLine PRIMARY KEY NONCLUSTERED (PurchaseLineID)
        );

        CREATE CLUSTERED INDEX CIX_PurchaseLine ON dbo.PurchaseLine (PurchaseHeaderID);
    END;

IF (OBJECT_ID('dbo.Inventory', 'U') IS NULL)
    BEGIN
        CREATE TABLE dbo.Inventory
        (
            UnitID       INT            NOT NULL,
            BusinessDate DATE           NOT NULL,
            ItemID       INT            NOT NULL,
            Quantity     DECIMAL(12, 2) NOT NULL,
            Cost         DECIMAL(8, 2)  NOT NULL,
            CONSTRAINT PK_Inventory PRIMARY KEY (UnitID, BusinessDate, ItemID)
        );
    END;

-- ItemsToCalcCost is created as a regular table (not a temporary one) just for impl usability.
IF (OBJECT_ID('dbo.ItemsToCalcCost', 'U') IS NULL)
    BEGIN
        CREATE TABLE dbo.ItemsToCalcCost
        (
            ItemID int
        );
    END;

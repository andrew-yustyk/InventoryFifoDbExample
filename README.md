# InventoryFifoDbExample

This example demonstrates SQL solution for inventory cost calculation with FIFO method for each item in
the `#ItemsToCalcCost` table for the specified `@UnitID` and `@CountDate`.
https://en.wikipedia.org/wiki/FIFO_and_LIFO_accounting

### FIFO calculation method:

1. Find the item quantity in the `Inventory` table for `@UnitID` and `@CountDate`, let's call it `BaseQuantity`;
    1. if you can't to find the `BaseQuantity` on the first step, take cost from the latest document
       (where the `BusinessDate` is older than the `@CountDate`)
2. Take the latest documents from the `PurchaseHeader`/`PurchaseLine` tables
   till the sum of their quantities is smaller or equal to the`BaseQuantity`.
   (Documents should be older then @CountDate but newer then previous inventory of the item);
3. If the sum is still smaller than the `BaseQuantity`, take values from the previous inventory record;
4. The FIFO cost is a weighted average cost of the documents you took in (2) and (3)

## Examples

### Example 1:

| Date      | Table     | Quantity | Cost |
|-----------|-----------|----------|------|
| 12/8/2023 | Inventory | 100      |      |
| 12/7/2023 | Purchase  | 40       | 15$  |
| 12/6/2023 | Purchase  | 25       | 20$  |
| 12/1/2023 | Inventory | 50       | 10$  |

```
FIFO cost = (40*15$ + 25*20$ + 35*10$) / 100 = 14.5$
```

### Example 2:

| Date      | Table     | Quantity | Cost |
|-----------|-----------|----------|------|
| 12/8/2023 | Inventory | 100      |      |
| 12/7/2023 | Purchase  | 40       | 15$  |
| 12/6/2023 | Purchase  | 25       | 20$  |
| 12/5/2023 | Purchase  | 45       | 8$   |
| 12/1/2023 | Inventory | 50       | 10$  |

```
FIFO cost = (40*15$ + 25*20$ + 35*8$) / 100 = 13.8$
```

### Example 3:

| Date      | Table     | Quantity | Cost |
|-----------|-----------|----------|------|
| 12/8/2023 | Inventory | 100      |      |
| 12/7/2023 | Purchase  | 40       | 15$  |
| 12/6/2023 | Purchase  | 25       | 20$  |
| 12/1/2023 | Inventory | 20       | 10$  |

```
FIFO cost = (40*15$ + 25*20$ + 20*10$) / 85 = 15.29$
```

### Example 4:

| Date      | Table     | Quantity   | Cost       |
|-----------|-----------|------------|------------|
| 12/8/2023 | Inventory | no records | no records |
| 12/7/2023 | Purchase  | 40         | 15$        |
| 12/6/2023 | Purchase  | 25         | 20$        |
| 12/1/2023 | Inventory | 20         | 10$        |

```
FIFO cost = last cost = 15$
```

## Database structure

### Inventory table

```sql
CREATE TABLE Inventory
(
    UnitID       int            NOT NULL,
    BusinessDate date           NOT NULL,
    ItemID       int            NOT NULL,
    Quantity     decimal(12, 2) NOT NULL,
    Cost         decimal(8, 2)  NOT NULL,

    CONSTRAINT PK_Inventory
        PRIMARY KEY (UnitID, BusinessDate, ItemID)
)
```

### PurchaseHeader table

```sql
CREATE TABLE PurchaseHeader
(
    PurchaseHeaderID uniqueidentifier NOT NULL,
    UnitID           int              NOT NULL,
    BusinessDate     date             NOT NULL,

    CONSTRAINT PK_PurchaseHeader
        PRIMARY KEY NONCLUSTERED (PurchaseHeaderID)
)
CREATE CLUSTERED INDEX [CIX_PurchaseHeader] ON PurchaseHeader (UnitID, BusinessDate)
```

### PurchaseLine table

```sql
CREATE TABLE PurchaseLine
(
    PurchaseLineID   uniqueidentifier NOT NULL,
    PurchaseHeaderID uniqueidentifier NOT NULL,
    ItemID           int              NOT NULL,
    Quantity         decimal(12, 2)   NOT NULL,
    Cost             decimal(8, 2)    NOT NULL,

    CONSTRAINT PK_PurchaseLine
        PRIMARY KEY NONCLUSTERED (PurchaseLineID)
)

CREATE CLUSTERED INDEX [CIX_PurchaseLine] ON PurchaseLine (PurchaseHeaderID)
```

### ItemsToCalcCost table

```sql
CREATE TABLE #ItemsToCalcCost
(
    ItemID int
)
```

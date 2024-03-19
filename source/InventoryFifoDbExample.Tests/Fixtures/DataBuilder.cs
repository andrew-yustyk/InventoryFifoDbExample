using System;
using InventoryFifoDbExample.Tests.Entities;

namespace InventoryFifoDbExample.Tests.Fixtures;

public class DataBuilder
{
    public Random Random { get; set; } = new Random();

    public ushort MinQuantity { get; set; } = 10;
    public ushort MaxQuantity { get; set; } = 100;

    public ushort MinCost { get; set; } = 5;
    public ushort MaxCost { get; set; } = 50;

    public PurchaseHeader GetPurchaseHeader(int unitId, DateOnly businessDate)
    {
        return new PurchaseHeader
        {
            PurchaseHeaderId = Guid.NewGuid(),
            UnitId = unitId,
            BusinessDate = businessDate,
        };
    }

    public PurchaseLine GetPurchaseLine(Guid headerId, int itemId, bool decQuantity, bool decCost)
    {
        return new PurchaseLine
        {
            PurchaseLineId = Guid.NewGuid(),
            PurchaseHeaderId = headerId,
            ItemId = itemId,
            Quantity = decQuantity ? RandomDecimal(MinQuantity, MaxQuantity) : RandomInt(MinQuantity, MaxQuantity),
            Cost = decCost ? RandomDecimal(MinCost, MaxCost) : RandomInt(MinCost, MaxCost),
        };
    }

    public Inventory GetInventory(int unitId, DateOnly businessDate, int itemId, decimal quantity, decimal cost)
    {
        return new Inventory
        {
            UnitId = unitId,
            BusinessDate = businessDate,
            ItemId = itemId,
            Quantity = quantity,
            Cost = cost
        };
    }

    private decimal RandomInt(int min, int max)
    {
        return Random.Next(min, max + 1);
    }

    private decimal RandomDecimal(decimal min, decimal max, int decimals = 2)
    {
        var part = (decimal)Random.NextDouble() * (max - min);
        return Math.Round(min + part, decimals);
    }
}

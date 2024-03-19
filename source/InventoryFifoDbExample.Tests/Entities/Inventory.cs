using System;

namespace InventoryFifoDbExample.Tests.Entities;

public class Inventory
{
    public int UnitId { get; set; }

    public DateOnly BusinessDate { get; set; }

    public int ItemId { get; set; }

    public decimal Quantity { get; set; }

    public decimal Cost { get; set; }
}

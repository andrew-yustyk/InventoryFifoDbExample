using System;

namespace InventoryFifoDbExample.Tests.Entities;

public class PurchaseLine
{
    public Guid PurchaseLineId { get; set; }

    public Guid PurchaseHeaderId { get; set; }

    public int ItemId { get; set; }

    public decimal Quantity { get; set; }

    public decimal Cost { get; set; }
}

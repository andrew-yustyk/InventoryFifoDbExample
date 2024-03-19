using System;

namespace InventoryFifoDbExample.Tests.Entities;

public class PurchaseHeader
{
    public Guid PurchaseHeaderId { get; set; }

    public int UnitId { get; set; }

    public DateOnly BusinessDate { get; set; }
}

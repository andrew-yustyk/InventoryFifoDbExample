using InventoryFifoDbExample.Tests.Entities;
using Microsoft.EntityFrameworkCore;

namespace InventoryFifoDbExample.Tests.Context;

public class InventoryDbContext : DbContext
{
    public InventoryDbContext()
    {
    }

    public InventoryDbContext(DbContextOptions<InventoryDbContext> options)
        : base(options)
    {
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Inventory>(entity =>
        {
            entity.ToTable("Inventory");

            entity.Property(e => e.UnitId).HasColumnName("UnitID");
            entity.Property(e => e.BusinessDate).HasColumnName("BusinessDate");
            entity.Property(e => e.ItemId).HasColumnName("ItemID");
            entity.Property(e => e.Quantity).HasColumnName("Quantity").HasColumnType("decimal(12, 2)");
            entity.Property(e => e.Cost).HasColumnName("Cost").HasColumnType("decimal(8, 2)");

            entity.HasKey(e => new { e.UnitId, e.BusinessDate, e.ItemId });
        });

        modelBuilder.Entity<PurchaseHeader>(entity =>
        {
            entity.ToTable("PurchaseHeader");

            entity.Property(e => e.PurchaseHeaderId).ValueGeneratedNever().HasColumnName("PurchaseHeaderID");
            entity.Property(e => e.UnitId).HasColumnName("UnitID");
            entity.Property(e => e.BusinessDate).HasColumnName("BusinessDate");

            entity.HasKey(e => e.PurchaseHeaderId).IsClustered(false);
            entity.HasIndex(e => new { e.UnitId, e.BusinessDate }, "CIX_PurchaseHeader").IsClustered();
        });

        modelBuilder.Entity<PurchaseLine>(entity =>
        {
            entity.ToTable("PurchaseLine");

            entity.Property(e => e.PurchaseLineId).ValueGeneratedNever().HasColumnName("PurchaseLineID");
            entity.Property(e => e.PurchaseHeaderId).HasColumnName("PurchaseHeaderID");
            entity.Property(e => e.ItemId).HasColumnName("ItemID");
            entity.Property(e => e.Quantity).HasColumnType("decimal(12, 2)");
            entity.Property(e => e.Cost).HasColumnType("decimal(8, 2)");

            entity.HasKey(e => e.PurchaseLineId).IsClustered(false);
            entity.HasIndex(e => e.PurchaseHeaderId, "CIX_PurchaseLine").IsClustered();
        });

        modelBuilder.Entity<ItemsToCalcCost>(entity =>
        {
            entity.ToTable("ItemsToCalcCost");
            entity.Property(e => e.ItemId).HasColumnName("ItemID");
            entity.HasNoKey();
        });
    }
}

using System;
using System.Linq;
using System.Threading.Tasks;
using InventoryFifoDbExample.Tests.Context;
using InventoryFifoDbExample.Tests.Entities;
using InventoryFifoDbExample.Tests.Fixtures;
using InventoryFifoDbExample.Tests.Utils;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Xunit.Abstractions;

namespace InventoryFifoDbExample.Tests;

public abstract class InventorySeedTestBase
{
    private readonly InventoryFixtureBase _fixture;
    private readonly ITestOutputHelper _outputHelper;
    private readonly IDbContextFactory<InventoryDbContext> _contextFactory;

    protected InventorySeedTestBase(InventoryFixtureBase fixture, ITestOutputHelper outputHelper)
    {
        _fixture = fixture;
        _outputHelper = outputHelper;
        _contextFactory = _fixture.ServiceProvider.GetRequiredService<IDbContextFactory<InventoryDbContext>>();
    }

    protected async Task DataCleanup()
    {
        await using var context = _contextFactory.CreateDbContextWithoutTracking();
        await context.Set<ItemsToCalcCost>().ExecuteDeleteAsync();
        await context.Set<Inventory>().ExecuteDeleteAsync();
        await context.Set<PurchaseLine>().ExecuteDeleteAsync();
        await context.Set<PurchaseHeader>().ExecuteDeleteAsync();
    }

    protected async Task DataSeed()
    {
        const ushort unitsOffset = 0;
        const ushort unitsCount = 10;
        const ushort itemsCount = 300;
        DateOnly startDate = new DateOnly(2019, 01, 01);
        DateOnly endDate = new DateOnly(2024, 01, 01);

        var builder = new DataBuilder();
        var itemIds = Enumerable.Range(1, itemsCount).ToArray();
        var unitIds = Enumerable.Range(unitsOffset + 1, unitsCount).ToArray();

        await using var context = _contextFactory.CreateDbContextWithoutTracking();

        _outputHelper.WriteLine("{0}: Seeding initial data", DateTime.Now);
        foreach (var unitId in unitIds)
        {
            var head = builder.GetPurchaseHeader(unitId, startDate.AddDays(-1));
            var items = itemIds.Select(itemId => builder.GetPurchaseLine(head.PurchaseHeaderId, itemId, _fixture.GenerateDecimalQuantity, _fixture.GenerateDecimalCost)).ToList();
            var inventories = items.Select(x => builder.GetInventory(unitId, startDate, x.ItemId, x.Quantity, x.Cost));
            await context.Set<PurchaseHeader>().AddAsync(head);
            await context.Set<PurchaseLine>().AddRangeAsync(items);
            await context.Set<Inventory>().AddRangeAsync(inventories);
            await context.SaveChangesAndClearAsync();
        }

        _outputHelper.WriteLine("{0}: Seeding main data", DateTime.Now);
        for (var genDate = startDate; genDate < endDate; genDate = genDate.AddDays(1))
        {
            _outputHelper.WriteLineIf(genDate.DayOfYear == 1, "{0}: Seeding main data for: {1:O}", DateTime.Now, genDate);
            foreach (var unitId in unitIds)
            {
                var head = context.Set<PurchaseHeader>().Add(builder.GetPurchaseHeader(unitId, genDate)).Entity;
                await context.Set<PurchaseLine>()
                    .AddRangeAsync(itemIds.Select(itemId => builder.GetPurchaseLine(head.PurchaseHeaderId, itemId, _fixture.GenerateDecimalQuantity, _fixture.GenerateDecimalCost)));
                await context.SaveChangesAndClearAsync();
            }
        }

        _outputHelper.WriteLine("{0}: Seeding last inventory data for: {1:O}", DateTime.Now, endDate);
        foreach (var unitId in unitIds)
        {
            await context.AddRangeAsync(itemIds.Select(itemId => builder.GetInventory(unitId, endDate, itemId, 1000, 0)));
            await context.SaveChangesAndClearAsync();
        }

        await SeedItemsToCalcCost(context, itemIds.OrderBy(_ => builder.Random.Next()).ToArray());
    }

    private async Task SeedItemsToCalcCost(InventoryDbContext context, int[] itemIds)
    {
        var items = itemIds.Select(x => $"({x})").ToArray();
        var entityType = context.Set<ItemsToCalcCost>().EntityType;
        var columnName = entityType.FindProperty(nameof(ItemsToCalcCost.ItemId))?.GetColumnName() ?? nameof(ItemsToCalcCost.ItemId);
        var table = entityType.GetTableName() ?? nameof(ItemsToCalcCost);
        var schema = entityType.GetSchema();
        var fullTableName = !string.IsNullOrEmpty(schema) ? $"[{schema}].[{table}]" : $"[{table}]";

        var sql = $"""
                   MERGE INTO {fullTableName} AS target
                       USING (VALUES {string.Join(",", items)}) AS source ([{columnName}])
                       ON target.[{columnName}] = source.[{columnName}]
                       WHEN NOT MATCHED BY TARGET THEN
                       INSERT ([{columnName}]) VALUES (source.[{columnName}]);
                   """;

        await context.Database.ExecuteSqlRawAsync(sql);
    }
}

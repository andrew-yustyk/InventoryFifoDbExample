using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;

namespace InventoryFifoDbExample.Tests.Utils;

public static class DbContextExtensions
{
    public static T CreateDbContextWithoutTracking<T>(this IDbContextFactory<T> contextFactory)
        where T : DbContext
    {
        var context = contextFactory.CreateDbContext();
        context.ChangeTracker.QueryTrackingBehavior = QueryTrackingBehavior.NoTracking;
        context.ChangeTracker.AutoDetectChangesEnabled = false;
        return context;
    }

    public static async Task SaveChangesAndClearAsync(this DbContext context)
    {
        await context.SaveChangesAsync();
        context.ChangeTracker.Clear();
    }
}

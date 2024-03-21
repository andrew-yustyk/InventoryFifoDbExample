using System;
using System.Threading.Tasks;
using InventoryFifoDbExample.Tests.Configuration;
using InventoryFifoDbExample.Tests.Context;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace InventoryFifoDbExample.Tests.Fixtures;

public abstract class InventoryFixtureBase : IDisposable, IAsyncDisposable
{
    public abstract bool GenerateDecimalCost { get; }

    public abstract bool GenerateDecimalQuantity { get; }

    protected abstract string DbConnectionName { get; }

    public required int DbContextPoolSize { get; init; } = Math.Min(Environment.ProcessorCount, 1);

    public string EnvironmentName { get; }

    public IConfiguration Configuration { get; }

    public ServiceProvider ServiceProvider { get; }

    protected InventoryFixtureBase()
    {
        EnvironmentName = EnvironmentUtils.GetEnvironmentName();
        Configuration = new ConfigurationBuilder().AddDefaultSources(EnvironmentName).Build();

        var options = new ServiceProviderOptions { ValidateScopes = true, ValidateOnBuild = true };
        var services = new ServiceCollection()
            .AddSingleton(Configuration)
            .AddOptions()
            .AddLogging(b => b.AddDebug())
            .AddPooledDbContextFactory<InventoryDbContext>(b => b.UseSqlServer(Configuration.GetConnectionString(DbConnectionName)), DbContextPoolSize);

        ServiceProvider = services.BuildServiceProvider(options);
    }

    public void Dispose()
    {
        Dispose(true);
        GC.SuppressFinalize(this);
    }

    public async ValueTask DisposeAsync()
    {
        await DisposeAsyncCore();
        GC.SuppressFinalize(this);
    }

    protected virtual void Dispose(bool disposing)
    {
        if (disposing)
        {
            if (ServiceProvider is IDisposable disposable)
            {
                disposable.Dispose();
            }
        }
    }

    protected virtual async ValueTask DisposeAsyncCore()
    {
        if (ServiceProvider is IAsyncDisposable asyncDisposable)
        {
            await asyncDisposable.DisposeAsync();
        }
    }
}

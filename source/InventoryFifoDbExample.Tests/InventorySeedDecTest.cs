using System.Threading.Tasks;
using InventoryFifoDbExample.Tests.Fixtures;
using Xunit;
using Xunit.Abstractions;

namespace InventoryFifoDbExample.Tests;

[Collection(nameof(InventoryTestCollectionDec))]
public class InventorySeedDecTest : InventorySeedTestBase
{
    private const string SkipReason = "explicit";

    public InventorySeedDecTest(InventoryFixtureDec fixture, ITestOutputHelper outputHelper)
        : base(fixture, outputHelper)
    {
    }

    [Fact(Skip = SkipReason)]
    public async Task InventoryCleanup()
    {
        await DataCleanup();
    }

    [Fact(Skip = SkipReason)]
    public async Task InventorySeed()
    {
        await DataSeed();
    }
}

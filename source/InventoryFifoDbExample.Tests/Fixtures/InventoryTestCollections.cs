using Xunit;

namespace InventoryFifoDbExample.Tests.Fixtures;

[CollectionDefinition(nameof(InventoryTestCollection1))]
public class InventoryTestCollection1 : ICollectionFixture<InventoryFixture1>
{
    // This class has no code, and is never created. Its purpose is simply
    // to be the place to apply [CollectionDefinition] and all the
    // ICollectionFixture<> interfaces.
}

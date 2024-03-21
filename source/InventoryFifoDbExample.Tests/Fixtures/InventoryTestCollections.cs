using Xunit;

namespace InventoryFifoDbExample.Tests.Fixtures;

[CollectionDefinition(nameof(InventoryTestCollectionInt))]
public class InventoryTestCollectionInt : ICollectionFixture<InventoryFixtureInt>
{
    // This class has no code, and is never created. Its purpose is simply
    // to be the place to apply [CollectionDefinition] and all the
    // ICollectionFixture<> interfaces.
}

[CollectionDefinition(nameof(InventoryTestCollectionDec))]
public class InventoryTestCollectionDec : ICollectionFixture<InventoryFixtureDec>
{
    // This class has no code, and is never created. Its purpose is simply
    // to be the place to apply [CollectionDefinition] and all the
    // ICollectionFixture<> interfaces.
}

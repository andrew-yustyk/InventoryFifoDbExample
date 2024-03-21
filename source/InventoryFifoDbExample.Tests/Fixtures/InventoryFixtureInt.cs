namespace InventoryFifoDbExample.Tests.Fixtures;

public class InventoryFixtureInt : InventoryFixtureBase
{
    public override bool GenerateDecimalCost => false;

    public override bool GenerateDecimalQuantity => false;

    protected override string DbConnectionName => "SqlServerInt";
}

namespace InventoryFifoDbExample.Tests.Fixtures;

public class InventoryFixtureDec : InventoryFixtureBase
{
    public override bool GenerateDecimalCost => true;

    public override bool GenerateDecimalQuantity => true;

    protected override string DbConnectionName => "SqlServerDec";
}

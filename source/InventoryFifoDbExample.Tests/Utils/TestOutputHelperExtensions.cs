using Xunit.Abstractions;

namespace InventoryFifoDbExample.Tests.Utils;

public static class TestOutputHelperExtensions
{
    public static void WriteLineIf(this ITestOutputHelper outputHelper, bool condition, string message)
    {
        if (condition)
        {
            outputHelper.WriteLine(message);
        }
    }

    public static void WriteLineIf(this ITestOutputHelper outputHelper, bool condition, string format, params object[] args)
    {
        if (condition)
        {
            outputHelper.WriteLine(format, args);
        }
    }
}

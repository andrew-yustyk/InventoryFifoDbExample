using System;

namespace InventoryFifoDbExample.Tests.Configuration;

public static class EnvironmentUtils
{
    public static string GetEnvironmentName()
    {
        var envName = Environment.GetEnvironmentVariable("DOTNET_ENVIRONMENT");

        if (string.IsNullOrEmpty(envName))
        {
            envName = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT");
        }

        if (string.IsNullOrEmpty(envName))
        {
            envName = "Production";
        }

        return envName;
    }
}

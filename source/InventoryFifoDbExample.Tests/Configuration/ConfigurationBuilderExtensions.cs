using System;
using Microsoft.Extensions.Configuration;

namespace InventoryFifoDbExample.Tests.Configuration;

public static class ConfigurationBuilderExtensions
{
    public static IConfigurationBuilder AddDefaultSources(this IConfigurationBuilder builder, string envName)
    {
        if (string.IsNullOrEmpty(envName))
        {
            envName = "Production";
        }

        return builder
            .SetBasePath(AppDomain.CurrentDomain.BaseDirectory)
            .AddJsonFile("appsettings.json", true, true)
            .AddJsonFile($"appsettings.{envName}.json", true, true)
            .AddEnvironmentVariables();
    }

    public static IConfigurationBuilder AddDefaultSources(this IConfigurationBuilder builder, string envName, params string[] cmdArgs)
    {
        return builder
            .AddDefaultSources(envName)
            .AddCommandLine(cmdArgs);
    }
}

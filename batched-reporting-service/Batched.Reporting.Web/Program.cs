using Autofac.Extensions.DependencyInjection;
using Batched.Reporting.Shared;
using System;
using Microsoft.Extensions.Configuration;

namespace Batched.Reporting.Web
{
    public class Program
    {
        public static void Main(string[] args)
        {
            CreateHostBuilder(args).Build().Run();
        }
        public static IHostBuilder CreateHostBuilder(string[] args) =>
           Host.CreateDefaultBuilder(args)
            .ConfigureAppConfiguration((hostingContext, config) =>
            {
                var configPath = Environment.GetEnvironmentVariable("APPSETTINGS_PATH");
                if (!string.IsNullOrEmpty(configPath))
                {
                    config.AddJsonFile(configPath, optional: false, reloadOnChange: true);
                }
            })
           .UseServiceProviderFactory(new AutofacServiceProviderFactory())
               .ConfigureWebHostDefaults(webBuilder =>
               {
                   webBuilder.UseStartup<Startup>();
               })
           .WithSerilog();
    }
}
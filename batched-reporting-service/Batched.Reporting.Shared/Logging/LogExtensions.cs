using Batched.Common;
using Batched.Common.Serilog;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;

namespace Batched.Reporting.Shared
{
    public static class LogExtensions
    {
        //step 1.1
        public static IHostBuilder WithSerilog(this IHostBuilder hostBuilder)
        {
            hostBuilder.AddSerilog();
            return hostBuilder;
        }
        //step 1.1
        public static IWebHostBuilder WithSerilog(this IWebHostBuilder webHostBuilder)
        {
            webHostBuilder.AddSerilog();
            return webHostBuilder;
        }
        //step 2
        public static void RegisterLogDependencies(this IServiceCollection services)
        {
            services.AddTransient<ILogWriterFactory, SerilogWriterFactory>();
            services.AddTransient<ILogSink, SerilogSink>();
            services.AddSingleton<IConfigProvider, AppSettingConfigProvider>();
        }
        //step 3
        public static void InitializeTaskPoolAndLogger(ILogWriterFactory logWriterFactory, int logPoolSize)
        {
            AsyncTasks.UseDefaultPool();
            AsyncTasks.AddPool("logging", logPoolSize);

            //initialize logger
            Logger.Initialize(logWriterFactory);
        }
    }
}

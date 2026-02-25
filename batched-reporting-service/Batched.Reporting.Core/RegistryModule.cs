using Autofac;
using Batched.Common.Auth;
using Batched.Reporting.Contracts;
using Batched.Reporting.Contracts.Interfaces;
using Batched.Reporting.Core.Core;
using Batched.Reporting.Core.Services;
using Microsoft.Extensions.Configuration;
using StackExchange.Redis;

namespace Batched.Reporting.Core
{
    public class RegistryModule : Module
    {
        private readonly IConfiguration _configuration;

        public RegistryModule(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<HealthCheckService>().As<IHealthCheckService>();
            builder.RegisterType<HealthCheck>().As<IHealthCheck>();

            builder.RegisterType<CachedTenantProvider>().As<ITenantProvider>();
            builder.RegisterType<TenantProvider>().Named<ITenantProvider>("source");
            builder.RegisterType<LeadTimeReportProvider>().As<ILeadTimeProvider>();
            builder.RegisterType<LeadTimeReportService>().As<ILeadTimeService>();
            builder.RegisterType<CustomerService>().As<ICustomerService>();

            var appSettingsSection = _configuration.GetSection("AppSettings");
            builder.RegisterInstance<IConnectionMultiplexer>(ConnectionMultiplexer.Connect(appSettingsSection["RedisHost"]));

            builder.RegisterType<AccessTokenStore>().As<IAccessTokenStore>();
            builder.RegisterType<PermissionRoleRepository>().As<IPermissionRoleRepository>();
            builder.RegisterType<ClientRepository>().As<IClientRepository>();
            builder.RegisterType<PermissionService>().As<IPermissionService>();

            builder.RegisterType<AwsSetting>().As<IAwsSetting>();
            builder.RegisterType<ExportService>().As<IExportService>();

            builder.RegisterType<Common.Export.ExportService>().As<Common.Export.IExportService>();
            builder.RegisterType<Common.Export.FileService>().As<Common.Export.IFileService>();
            builder.RegisterType<Common.Export.S3Service>().As<Common.Export.IS3Service>();

            builder.RegisterType<LeadTimeExceptionsService>().As<ILeadTimeExceptionsService>();
            builder.RegisterType<LeadTimeExceptionsProvider>().As<ILeadTimeExceptionsProvider>();

            builder.RegisterType<ReservationService>().As<IReservationService>();
            builder.RegisterType<ReservationProvider>().As<IReservationProvider>();

            builder.RegisterType<StagingRequirementService>().As<IStagingRequirementService>();
            builder.RegisterType<StagingRequirementProvider>().As<IStagingRequirementProvider>();

            builder.RegisterType<ConfigurableViewsProvider>().As<IConfigurableViewsProvider>();

            builder.RegisterType<Common.Repository.ConfigurationRepository>().As<Common.Interfaces.IConfigurationRepository>();
            builder.RegisterType<Common.Repository.ScheduleEventRepository>().As<Common.Interfaces.IScheduleEventRepository>();
            builder.RegisterType<Common.Repository.ValueStreamRepository>().As<Common.Interfaces.IValueStreamRepository>();

        }
    }
}

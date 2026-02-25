using Autofac;
using Batched.Common;
using Batched.Reporting.Contracts;
using Batched.Reporting.Contracts.Interfaces;
using Batched.Reporting.Data.Contracts;
using Batched.Reporting.Data.Internals;
using Batched.Reporting.Data.Repository;

namespace Batched.Reporting.Data
{
    public class RegistryModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<UnitOfWorkFactory>();
            builder.RegisterType<UnitOfWork>().As<IUnitOfWork>();
            builder.RegisterType<DBContextFactory>().As<IDBContextFactory>();

            builder.RegisterType<TenantRepository>().As<ITenantRepository>();
            builder.RegisterType<ConnectionStringService>().As<IConnectionStringService>();

            builder.RegisterType<EquipmentRepository>().As<IEquipmentRepository>();
            builder.RegisterType<TicketTaskRepository>().As<ITicketTaskRepository>();
            builder.RegisterType<CachedEquipmentRepository>().As<ICachedEquipmentRepository>();
            builder.RegisterType<FacilityRepository>().As<IFacilityRepository>();
            builder.RegisterType<LeadTimeExceptionsRepository>().As<ILeadTimeExceptionsRepository>();
            builder.RegisterType<ReservationsRepository>().As<IReservationsRepository>();
            builder.RegisterType<CustomerRepository>().As<ICustomerRepository>();

            builder.RegisterType<StagingRequirementRepository>().As<IStagingRequirementRepository>();

            builder.RegisterType<ReportConfigRepository>().As<IReportConfigRepository>();
            builder.RegisterType<CachedReportConfigRepository>().Named<IReportConfigRepository>("cache");
        }
    }
}

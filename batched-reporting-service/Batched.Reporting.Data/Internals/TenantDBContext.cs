using Batched.Common.Data.Tenants.Sql.Models;
using Batched.Reporting.Data.Contracts;
using Microsoft.EntityFrameworkCore;

namespace Batched.Reporting.Data.Internals
{
    public class TenantDBContext : TenantContext
    {
        private readonly IConnectionStringService connectionStringService;
        public TenantDBContext(IConnectionStringService connectionStringService)
        {
            this.connectionStringService = connectionStringService;
        }

        protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        {
            var connectionString = connectionStringService.GetTenantConnectionString().Result;
            optionsBuilder.UseLazyLoadingProxies().UseSqlServer(connectionString);
        }
    }
}

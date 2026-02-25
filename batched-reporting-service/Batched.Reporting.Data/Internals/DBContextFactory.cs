using Batched.Common;
using Batched.Reporting.Data.Contracts;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;

namespace Batched.Reporting.Data.Internals
{ 
    public class DBContextFactory : IDBContextFactory
    {
        private readonly IConfiguration _configuration;
        private readonly IConnectionStringService _connectionStringService;
        public DBContextFactory(IConfiguration configuration, IConnectionStringService connectionStringService)
        {
            this._configuration = configuration;
            _connectionStringService = connectionStringService;
        }

        public DbContext Get(DBContextLevel dBContextLevel)
        {
            return dBContextLevel switch
            {
                DBContextLevel.Batched => new BatchedDBContext(_configuration),
                DBContextLevel.Tenant => new TenantDBContext(_connectionStringService),
                _ => throw new System.NotImplementedException(),

            };
        }
    }
}

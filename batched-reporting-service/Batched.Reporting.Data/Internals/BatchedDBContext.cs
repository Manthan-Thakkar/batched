using Batched.Common.Data.Sql.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;

namespace Batched.Reporting.Data.Internals
{
    public class BatchedDBContext : BatchedContext
    {
        private readonly IConfiguration _configuration;
        public BatchedDBContext(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        {
            optionsBuilder.UseLazyLoadingProxies().UseSqlServer(_configuration.GetConnectionString("BatchedDBConnection"));
        }
    }
}

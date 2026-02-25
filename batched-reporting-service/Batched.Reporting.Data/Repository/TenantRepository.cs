using Batched.Common;
using Batched.Common.Data.Sql.Models;
using Batched.Reporting.Contracts;
using Batched.Reporting.Shared;
using Microsoft.EntityFrameworkCore;
using static Batched.Reporting.Shared.Extensions;

namespace Batched.Reporting.Data.Repository
{
    public class TenantRepository : ITenantRepository
    {
        private readonly UnitOfWorkFactory _unitOfWorkFactory;

        public TenantRepository(UnitOfWorkFactory unitOfWorkFactory)
        {
            this._unitOfWorkFactory = unitOfWorkFactory;
        }
        public async Task<string> GetTenantDatabaseNameAsync(string tenantId, CancellationToken cancellationToken)
        {
            using (Tracer.Benchmark("repo-tenantDatabase-getbyTenantId"))
            using (var unitOfWork = _unitOfWorkFactory.BeginUnitOfWork(DBContextLevel.Batched, DbAccessMode.read))
            {
                var tenantDB = unitOfWork.Repository<TenantDatabase>().GetQueryable();

                var result = await tenantDB.Where(m => m.TenantId == tenantId).FirstOrDefaultAsync();

                return result?.DbName;
            }
        }

        public async Task<DateTime> GetTenantCurrentTimeAsync(string tenantId, CancellationToken cancellationToken)
        {
            using (Tracer.Benchmark("repo-get-tenant-locat-current-time"))
            using (var unitOfWork = _unitOfWorkFactory.BeginUnitOfWork(DBContextLevel.Batched, DbAccessMode.read))
            {
                var tenantDB = unitOfWork.Repository<Tenant>().GetQueryable();

                var result = await tenantDB.FirstOrDefaultAsync(m => m.Id == tenantId, cancellationToken: cancellationToken);

                var timeZone = new DateTimeWithZone(result?.TimeZone);

                return timeZone.LocalTime;
            }

        }
    }
}

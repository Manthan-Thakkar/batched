using Batched.Common;
using Batched.Reporting.Contracts;

namespace Batched.Reporting.Core.Core
{
    public class HealthCheck : IHealthCheck
    {
        private readonly UnitOfWorkFactory _unitOfWorkFactory;
        public HealthCheck(UnitOfWorkFactory unitOfWorkFactory)
        {
            _unitOfWorkFactory = unitOfWorkFactory;
        }
        public async Task<bool> HealthCheckAsync(bool shouldCheckWithDB, CancellationToken cancellationToken)
        {
            if (shouldCheckWithDB)
            {
                using (Tracer.Benchmark("check-db-health"))
                using (var unitOfWork = _unitOfWorkFactory.BeginUnitOfWork(DBContextLevel.Batched))
                {
                    await unitOfWork.ExecuteAsync("SELECT 1");
                }
            }
            return true;
        }
    }
}

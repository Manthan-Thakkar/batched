using Batched.Reporting.Contracts;

namespace Batched.Reporting.Core.Services
{
    public class HealthCheckService : IHealthCheckService
    {
        private readonly IHealthCheck healthCheck;
        public HealthCheckService(IHealthCheck healthCheck)
        {
            this.healthCheck = healthCheck;
        }
        public async Task<bool> IsHealthyAsync(bool shouldCheckWithDB, CancellationToken cancellationToken)
        {
            return await healthCheck.HealthCheckAsync(shouldCheckWithDB, cancellationToken);
        }
    }
}

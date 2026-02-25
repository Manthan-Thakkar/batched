using Batched.Reporting.Contracts;
namespace Batched.Reporting.Core.Core
{
    public class TenantProvider : ITenantProvider
    {
        private readonly ITenantRepository _tenantDatabaseRepository;

        public TenantProvider(ITenantRepository tenantDatabaseRepository)
        {
            _tenantDatabaseRepository = tenantDatabaseRepository;
        }
        public Task<string> GetTenantDatabaseNameAsync(string tenantId, CancellationToken cancellationToken)
        {
            return _tenantDatabaseRepository.GetTenantDatabaseNameAsync(tenantId, cancellationToken);
        }
    }
}

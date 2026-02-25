using Batched.Reporting.Contracts;
using Batched.Reporting.Shared;
using Batched.Common;

namespace Batched.Reporting.Core
{
    public class CachedTenantProvider : ITenantProvider
    {
        private readonly IObjectProvider objectProvider;
        private readonly ICache cache;
        public CachedTenantProvider(IObjectProvider objectProvider, ICache cache)
        {
            this.objectProvider = objectProvider;
            this.cache = cache;
        }
        public async Task<string> GetTenantDatabaseNameAsync(string tenantId, CancellationToken cancellationToken)
        {
            if (!string.IsNullOrEmpty(ApplicationContext.Current?.TenantName))
                return ApplicationContext.Current.TenantName;


            var dbName = await cache.GetAsync<string>(GetTenantDbNameKey(tenantId), cancellationToken: cancellationToken, appendAppName: false);

            if (string.IsNullOrEmpty(dbName))
            {
                var source = objectProvider.GetInstance<ITenantProvider>("source");
                dbName = await source.GetTenantDatabaseNameAsync(tenantId, cancellationToken);

                if (!string.IsNullOrEmpty(dbName))
                {
                    await cache.SetAsync(GetTenantDbNameKey(tenantId), dbName, cancellationToken: cancellationToken, appendAppName: false);
                }
            }
            return dbName;
        }
        private string GetTenantDbNameKey(string tenantId) => $"tenantDbName-{tenantId}";
    }
}

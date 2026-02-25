using Batched.Common;
using Batched.DBInstanceService.Sdk;
using Batched.Reporting.Data.Contracts;
using Batched.Reporting.Shared;

namespace Batched.Reporting.Data.Internals
{
    public class ConnectionStringService : IConnectionStringService
    {
        private readonly IConfigProvider _configProvider;
        private readonly IDBConnectionInfoProvider dBConnectionInfoProvider;
        private readonly ICache cache;

        public ConnectionStringService(IConfigProvider configProvider, ICache cache, IDBConnectionInfoProvider dBConnectionProvider)
        {
            this._configProvider = configProvider;
            this.dBConnectionInfoProvider = dBConnectionProvider;
            this.cache = cache;
        }
        public async Task<string> GetTenantConnectionString()
        {
#if DEBUG
            var conn = _configProvider.GetConfig<string>("ConnectionStrings", "TenantDBConnection");
            conn = conn.Replace("{TENANT_NAME}", ApplicationContext.Current.TenantName);

            return conn;
#endif
            string tenantId = ApplicationContext.Current?.TenantId;
            string cacheKey = $"TenantDBConnection_{tenantId}";
            var response = await cache.GetAsync<ConnectionRes>(cacheKey, appendAppName: false);
            bool UseSDKValues = response == null ? false : response.UseSDK;
            string connectionString = response == null ? string.Empty : response.ConnectionString;
            if (response == null)
            {
                try
                {
                    var connectionDetails = await dBConnectionInfoProvider.GetAsync(tenantId);
                    if (connectionDetails != null)
                        await cache.SetAsync(cacheKey, connectionDetails, null, TimeSpan.FromHours(2), appendAppName: false);
                    UseSDKValues = connectionDetails?.UseSDK ?? false;
                    connectionString = connectionDetails?.ConnectionString;
                }
                catch (Exception exception)
                {
                    AppLogger.LogException(exception);
                }
            }
            if (!UseSDKValues)
            {
                connectionString = _configProvider.GetConfig<string>("ConnectionStrings", "TenantDBConnection");
                connectionString = connectionString.Replace("{TENANT_NAME}", ApplicationContext.Current.TenantName);
            }
            return connectionString;
        }

    }
}

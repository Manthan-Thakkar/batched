namespace Batched.Reporting.Contracts
{
    public interface ITenantRepository
    {
        Task<string> GetTenantDatabaseNameAsync(string tenantId, CancellationToken cancellationToken);
        Task<DateTime> GetTenantCurrentTimeAsync(string tenantId, CancellationToken cancellationToken);
    }
}

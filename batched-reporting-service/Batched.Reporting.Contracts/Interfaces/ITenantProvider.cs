namespace Batched.Reporting.Contracts
{
    public interface ITenantProvider
    {
        Task<string> GetTenantDatabaseNameAsync(string tenantId, CancellationToken cancellationToken);

    }
}

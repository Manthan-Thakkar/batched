namespace Batched.Reporting.Data.Contracts
{
    public interface IConnectionStringService
    {
        Task<string> GetTenantConnectionString();
    }
}

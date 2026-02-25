namespace Batched.Reporting.Contracts
{
    public interface IHealthCheck
    {
        Task<bool> HealthCheckAsync(bool shouldCheckWithDB, CancellationToken cancellationToken);
    }
}

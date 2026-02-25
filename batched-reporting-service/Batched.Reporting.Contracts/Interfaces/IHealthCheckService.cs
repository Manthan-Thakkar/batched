
namespace Batched.Reporting.Contracts
{
    public interface IHealthCheckService
    {
        Task<bool> IsHealthyAsync(bool shouldCheckWithDB, CancellationToken cancellationToken);
    }
}

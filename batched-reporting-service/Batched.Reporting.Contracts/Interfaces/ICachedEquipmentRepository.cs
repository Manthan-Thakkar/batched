namespace Batched.Reporting.Contracts
{
    public interface ICachedEquipmentRepository
    {
        Task<List<FilterData>> GetFilterDataAsync(DashboardFilter filter, CancellationToken cancellationToken);
    }
}

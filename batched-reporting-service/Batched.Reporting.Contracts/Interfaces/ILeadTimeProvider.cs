using Batched.Reporting.Contracts.Models.LeadTimeManager;

namespace Batched.Reporting.Contracts
{
    public interface ILeadTimeProvider
    {
        Task<List<LeadTimeDashboardFilter>> GetFilterDataAsync(DashboardFilter filter, CancellationToken cancellationToken);
        Task<LeadTimeManagerKpi> GetKpiAsync(DashboardFilter filter, CancellationToken cancellationToken);
        Task<List<CapacitySummary>> GetCapacitySummaryAsync(DashboardFilter filter, CancellationToken cancellationToken);
        Task<List<CapacityOverview>> GetCapacityOverviewsAsync(DashboardFilter filter, CancellationToken cancellationToken);
        Task<OpenTicketDetailsResponse> GetOpenTicketsLTMAsync(LeadTimeManagerFilters filter, CancellationToken cancellationToken);
        Task<CapacityOutlookOverTimeResponse> GetCapacityOutlookOverTimeAsync(DashboardFilter filter, CancellationToken cancellationToken);
    }
}

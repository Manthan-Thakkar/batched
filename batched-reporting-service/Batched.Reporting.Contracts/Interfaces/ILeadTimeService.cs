using Batched.Reporting.Contracts.Models.LeadTimeManager;

namespace Batched.Reporting.Contracts
{
    public interface ILeadTimeService
    {
        Task<List<LeadTimeDashboardFilter>> GetFilterDataAsync(Contracts.DashboardFilter filter, CancellationToken cancellationToken);
        Task<LeadTimeManagerKpi> GetKpiAsync(DashboardFilter filter, CancellationToken cancellationToken);
        Task<CapacitySummaryResponse> GetCapacitySummaryAsync(DashboardFilter filter, CancellationToken cancellationToken);
        Task<CapacityOverviewResponse> GetCapacityOverviewAsync(DashboardFilter filter, CancellationToken cancellationToken);
        Task<OpenTicketDetailsResponse> GetOpenTicketsLTMAsync(LeadTimeManagerFilters filter, CancellationToken cancellationToken);
        Task<CapacityOutlookOverTimeResponse> GetCapacityOutlookOverTimeAsync(DashboardFilter filter, CancellationToken cancellationToken);
    }
}

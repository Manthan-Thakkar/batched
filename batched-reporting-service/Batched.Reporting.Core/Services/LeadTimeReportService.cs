using Batched.Reporting.Contracts;
using Batched.Reporting.Contracts.Models.LeadTimeManager;

namespace Batched.Reporting.Core
{
    public class LeadTimeReportService : ILeadTimeService
    {
        private readonly ILeadTimeProvider _leadTimeReportProvider;

        public LeadTimeReportService(ILeadTimeProvider leadTimeReportProvider)
        {
            _leadTimeReportProvider = leadTimeReportProvider;
        }

        public async Task<List<LeadTimeDashboardFilter>> GetFilterDataAsync(DashboardFilter filter, CancellationToken cancellationToken)
        {
            return await _leadTimeReportProvider.GetFilterDataAsync(filter, cancellationToken);
        }

        public async Task<LeadTimeManagerKpi> GetKpiAsync(DashboardFilter filter, CancellationToken cancellationToken)
        {
            return await _leadTimeReportProvider.GetKpiAsync(filter, cancellationToken);
        }

        public async Task<CapacitySummaryResponse> GetCapacitySummaryAsync(DashboardFilter filter, CancellationToken cancellationToken)
        {
            var result = await _leadTimeReportProvider.GetCapacitySummaryAsync(filter, cancellationToken);
            return new CapacitySummaryResponse()
            {
                CapacitySummary = result,
            };
        }
        public async Task<CapacityOverviewResponse> GetCapacityOverviewAsync(DashboardFilter filter, CancellationToken cancellationToken)
        {
            var result = await _leadTimeReportProvider.GetCapacityOverviewsAsync(filter, cancellationToken);
            return new CapacityOverviewResponse { CapacityOverviews = result };
        }

        public async Task<OpenTicketDetailsResponse> GetOpenTicketsLTMAsync(LeadTimeManagerFilters filter, CancellationToken cancellationToken)
        {
            return await _leadTimeReportProvider.GetOpenTicketsLTMAsync(filter, cancellationToken);
        }

        public async Task<CapacityOutlookOverTimeResponse> GetCapacityOutlookOverTimeAsync(DashboardFilter filter, CancellationToken cancellationToken)
        {
            return await _leadTimeReportProvider.GetCapacityOutlookOverTimeAsync(filter, cancellationToken);  
           
        }

    }
}

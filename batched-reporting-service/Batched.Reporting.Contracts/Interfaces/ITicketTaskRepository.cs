using Batched.Reporting.Contracts.Models;
using Batched.Reporting.Contracts.Models.LeadTimeManager;

namespace Batched.Reporting.Contracts.Interfaces
{
    public interface ITicketTaskRepository
    {
        Task<List<TicketsDemand>> GetTicketsDemandAsync(DashboardFilter filter, DateTime endDate, CancellationToken cancellationToken);
        Task<List<dynamic>> GetOpenTicketsLTMAsync(LeadTimeManagerFilters filter, List<string> availableAttributes, List<ReportViewField> columns, CancellationToken cancellationToken);
        Task<List<string>> GetTicketAttributesAvailableInCacheTable();
        Task<List<LastRunInfo>> GetLastJobRunInfoAsync(CancellationToken cancellationToken);
    }
}

using Batched.Reporting.Contracts.Models.StagingRequirement;

namespace Batched.Reporting.Contracts.Interfaces
{
    public interface IStagingRequirementProvider
    {
        Task<List<StagingReportFilterData>> GetFilterDataAsync(StagingRequirementFilterDataPayload filter, CancellationToken cancellationToken);
        Task<StagingRequirementKPIData> GetKPIDataAsync(StagingRequirementFilter filter, CancellationToken cancellationToken);
        Task<List<StagingRequirements>> GetAllStagingRequirementsAsync();
        Task<StagingRequirementData> GetStagingRequirementReportAsync(StagingRequirementReportFilter filter, CancellationToken cancellationToken);
        Task UpdateTicketTaskStagingStateAsync(List<TicketTaskStagingPayload> ticketTaskStagingPayload, CancellationToken cancellationToken);
        Task<TicketStagingInfo> GetTicketTaskInfoAsync(TicketTaskStagingInfoPayload stagingPayload, CancellationToken cancellationToken);
        Task<TicketStagingInfo> GetApplicableTicketTaskStagingInfoAsync(TicketTaskStagingInfoPayload stagingPayload, CancellationToken cancellationToken);
    }
}

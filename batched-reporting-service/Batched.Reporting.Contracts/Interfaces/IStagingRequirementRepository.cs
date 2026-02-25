using Batched.Reporting.Contracts.Models.StagingRequirement;

namespace Batched.Reporting.Contracts.Interfaces
{
    public interface IStagingRequirementRepository
    {
        Task<List<TicketTaskStagingData>> GetTicketTaskStagingInfoAsync(StagingRequirementFilter filter, CancellationToken cancellationToken);
        Task<List<StagingRequirements>> GetAllStagingRequirementsAsync();
        Task<List<string>> GetApplicableStagingRequirementsForTicketTaskAsync(TicketTaskStagingInfoPayload stagingPayload, CancellationToken cancellationToken);
        Task<StagingRequirementData> GetStagingRequirementDataAsync(StagingRequirementReportFilter filter, List<string> ticketAttributes, DateTime tenantLocalDateTime, List<StagingRequirements> stagingRequirements, List<string> configurableViewTicketAttributes, CancellationToken cancellationToken);
        Task UpdateTicketTaskStagingStateAsync(List<TicketTaskStagingPayload> ticketTaskStagingData, CancellationToken cancellationToken);
        Task<List<TicketLevelAttributeValues>> GetTicketAttributeValuesAsync(List<string> ticketIds, List<string> ticketAttributes, CancellationToken cancellationToken);
        Task UpdateStagingStatusInTicketDataCache(List<string> tickets, CancellationToken cancellationToken);
    }
}
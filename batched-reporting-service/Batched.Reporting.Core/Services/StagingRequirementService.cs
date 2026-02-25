using Batched.Reporting.Contracts.Interfaces;
using Batched.Reporting.Contracts.Models;
using Batched.Reporting.Contracts.Models.StagingRequirement;

namespace Batched.Reporting.Core.Services
{
    public class StagingRequirementService : IStagingRequirementService
    {
        private readonly IStagingRequirementProvider _stagingRequirementProvider;

        public StagingRequirementService(IStagingRequirementProvider stagingRequirementProvider)
        {
            _stagingRequirementProvider = stagingRequirementProvider;
        }

        public async Task<List<StagingRequirements>> GetAllStagingRequirementsAsync()
        {
            return await _stagingRequirementProvider.GetAllStagingRequirementsAsync();
        }

        public async Task<List<StagingReportFilterData>> GetFilterDataAsync(StagingRequirementFilterDataPayload filter, CancellationToken cancellationToken)
        {
            return await _stagingRequirementProvider.GetFilterDataAsync(filter, cancellationToken);
        }

        public async Task<StagingRequirementKPIData> GetKPIDataAsync(StagingRequirementFilter filter, CancellationToken cancellationToken)
        {
            return await _stagingRequirementProvider.GetKPIDataAsync(filter, cancellationToken);
        }

        public async Task<StagingRequirementData> GetStagingRequirementReportAsync(StagingRequirementReportFilter filter, CancellationToken cancellationToken)
        {
            return await _stagingRequirementProvider.GetStagingRequirementReportAsync(filter, cancellationToken);
        }

        public async Task UpdateTicketTaskStagingStateAsync(List<TicketTaskStagingPayload> ticketTaskStagingPayload, CancellationToken cancellationToken)
        {
            await _stagingRequirementProvider.UpdateTicketTaskStagingStateAsync(ticketTaskStagingPayload, cancellationToken);
        }

        public async Task<TicketStagingInfo> GetTicketTaskInfoAsync(TicketTaskStagingInfoPayload stagingPayload, CancellationToken cancellationToken)
        {
            return await _stagingRequirementProvider.GetApplicableTicketTaskStagingInfoAsync(stagingPayload, cancellationToken);
        }
    }
}
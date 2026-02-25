using Batched.Reporting.Contracts.Models.LeadTimeManager;
using Batched.Reporting.Contracts.Models.StagingRequirement;

namespace Batched.Reporting.Contracts
{
    public interface IEquipmentRepository
    {
        Task<List<EquipmentValueStreams>> GetEquipmentValueStreams();
        Task<List<FilterData>> GetFilterDataAsync(DashboardFilter filter, CancellationToken cancellationToken);
        Task<List<EquipmentTicket>> GetEquipmentWiseTicketsAysnc(DashboardFilter filter, CancellationToken cancellationToken);
        Task<List<DailyEquipmentCapacity>> GetEquipmentsCapacityAsync(DateTime startDate, DateTime endDate, CancellationToken token);
        Task<DateTime> GetMaxEquipmentCalendarDate();
        Task<List<EquipmentCapacityOutlook>> GetDailyEquipmentCapacityOutlookAsync(DashboardFilter filter, CancellationToken cancellationToken);
        Task<List<EquipmentStagingTickets>> GetEquipmentWiseStagingTicketsAysnc(StagingRequirementFilterDataPayload filter, CancellationToken cancellationToken);
        Task<List<StagingReportFilterData>> GetStagingFilterDataAsync(StagingRequirementFilterDataPayload filter, CancellationToken cancellationToken);
        Task<List<EquipemntDetailsData>> GetAllEquipmentsDataAsync(DashboardFilter filter, CancellationToken cancellationToken);
    }
}

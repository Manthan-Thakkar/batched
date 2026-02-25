using Batched.Reporting.Contracts;
using Batched.Reporting.Contracts.Interfaces;
using Batched.Reporting.Contracts.Models.StagingRequirement;
using Batched.Reporting.Core.Translators;
using Batched.Reporting.Shared;
using Batched.Reporting.Shared.Helper;
using static Batched.Reporting.Shared.BatchedConstants;

namespace Batched.Reporting.Core.Core
{
    public class StagingRequirementProvider : IStagingRequirementProvider
    {
        private readonly IEquipmentRepository _equipmentRepository;
        private readonly IStagingRequirementRepository _stagingRequirementRepository;
        private readonly IConfigurableViewsProvider _configurableViewsProvider;
        private readonly Common.Interfaces.IScheduleEventRepository _scheduleEventRepository;
        private readonly ITenantRepository _tenantRepository;

        public StagingRequirementProvider(
            IEquipmentRepository equipmentRepository,
            IStagingRequirementRepository stagingRequirementRepository,
            Common.Interfaces.IScheduleEventRepository scheduleEventRepository,
            ITenantRepository tenantRepository,
            IConfigurableViewsProvider configurableViewsProvider
            )
        {
            _equipmentRepository = equipmentRepository;
            _stagingRequirementRepository = stagingRequirementRepository;
            _scheduleEventRepository = scheduleEventRepository;
            _tenantRepository = tenantRepository;
            _configurableViewsProvider = configurableViewsProvider;
        }

        public async Task<List<StagingRequirements>> GetAllStagingRequirementsAsync()
        {
            return await _stagingRequirementRepository.GetAllStagingRequirementsAsync();
        }

        public async Task<List<StagingReportFilterData>> GetFilterDataAsync(StagingRequirementFilterDataPayload filter, CancellationToken cancellationToken)
        {
            var equipmentTicketsTask = _equipmentRepository.GetEquipmentWiseStagingTicketsAysnc(filter, cancellationToken);
            var equipmentFilterDataTask = _equipmentRepository.GetStagingFilterDataAsync(filter, cancellationToken);

            await Task.WhenAll(equipmentTicketsTask, equipmentFilterDataTask);

            var equipmentTickets = equipmentTicketsTask.Result;
            var equipmentFilterData = equipmentFilterDataTask.Result;

            return equipmentFilterData.Select(x => new StagingReportFilterData
            {
                EquipmentId = x.EquipmentId,
                EquipmentName = x.EquipmentName,
                FacilityId = x.FacilityId,
                FacilityName = x.FacilityName,
                WorkcenterId = x.WorkcenterId,
                WorkcenterName = x.WorkcenterName,
                ValueStreams = x.ValueStreams,
                StagingRequirements = x.StagingRequirements,
                Tickets = equipmentTickets.Where(t => t.EquipmentId == x.EquipmentId).FirstOrDefault()?.Tickets ?? new()
            }).ToList();
        }

        public async Task<StagingRequirementKPIData> GetKPIDataAsync(StagingRequirementFilter filter, CancellationToken cancellationToken)
        {
            var stagingInfoTask = _stagingRequirementRepository.GetTicketTaskStagingInfoAsync(filter, cancellationToken);
            var nextScheduleRunTask = _scheduleEventRepository.GetNextScheduleRunTimeAsync(ApplicationContext.Current.TenantId, filter.Facilities, cancellationToken);
            var tenantLocalDateTimeTask = _tenantRepository.GetTenantCurrentTimeAsync(ApplicationContext.Current.TenantId, cancellationToken);

            await Task.WhenAll(stagingInfoTask, nextScheduleRunTask, tenantLocalDateTimeTask);

            var stagingInfo = CalculateStagingKpis(stagingInfoTask.Result, tenantLocalDateTimeTask.Result);
            stagingInfo.NextFacilityScheduledTime = nextScheduleRunTask.Result.Translate();

            return stagingInfo;
        }

        public async Task<TicketStagingInfo> GetApplicableTicketTaskStagingInfoAsync(TicketTaskStagingInfoPayload stagingPayload, CancellationToken cancellationToken)
        {
            var applicableStagingRequirements = await _stagingRequirementRepository.GetApplicableStagingRequirementsForTicketTaskAsync(stagingPayload, cancellationToken);

            var response = new TicketStagingInfo
            {
                TicketId = stagingPayload.TicketId,
                TicketNumber = stagingPayload.TicketNumber,
                TaskName = stagingPayload.TaskName,
                StagingInfo = new()
            };

            if (applicableStagingRequirements != null && applicableStagingRequirements.Count > 0)
            {
                var ticketAttributes = StagingRequirementReportConstant.StagingRequirementInfoAttributes.Where(x => applicableStagingRequirements.Contains(x.Key)).SelectMany(x => x.Value).ToList();
                var filter = new StagingRequirementFilter
                {
                    Facilities = new(),
                    ValueStreams = new(),
                    Workcenters = new(),
                    Equipments = new(),
                    Components = new(),
                    Tickets = new() { stagingPayload.TicketNumber },
                    StartDate = null,
                    EndDate = null
                };

                var ticketAttributeDataTask = _stagingRequirementRepository.GetTicketAttributeValuesAsync(new List<string> { stagingPayload.TicketId }, ticketAttributes, cancellationToken);
                var ticketStagingInfoTask = _stagingRequirementRepository.GetTicketTaskStagingInfoAsync(filter, cancellationToken);

                await Task.WhenAll(ticketAttributeDataTask, ticketStagingInfoTask);

                var ticketAttributeValues = ticketAttributeDataTask.Result.FirstOrDefault().TicketAttributeValues;
                var ticketTaskStagingInfo = ticketStagingInfoTask.Result.FirstOrDefault(x => x.TaskName == stagingPayload.TaskName);

                foreach (var req in applicableStagingRequirements)
                {
                    response.StagingInfo.Add(new StagingInfo
                    {
                        StagingRequirement = req,
                        IsRequirementApplicable = true,
                        IsStaged = GetStagingRequirementStatus(ticketTaskStagingInfo.StagingStatus, req.GetStagingNameKey()),
                        StagingData = StagingRequirementReportConstant.StagingRequirementInfoAttributes.TryGetValue(req, out var taskStagingDict)
                                    ? ticketAttributeValues.Where(x => taskStagingDict.Contains(x.Name)).ToList()
                                    : new()
                    });
                }
            }

            return response;
        }

        public async Task<TicketStagingInfo> GetTicketTaskInfoAsync(TicketTaskStagingInfoPayload stagingPayload, CancellationToken cancellationToken)
        {
            var ticketAttributes = StagingRequirementReportConstant.StagingRequirementInfoAttributes.SelectMany(x => x.Value).ToList();
            var filter = new StagingRequirementFilter
            {
                Facilities = new(),
                ValueStreams = new(),
                Workcenters = new(),
                Equipments = new(),
                Components = new(),
                Tickets = new() { stagingPayload.TicketNumber },
                StartDate = null,
                EndDate = null
            };

            var ticketAttributeDataTask = _stagingRequirementRepository.GetTicketAttributeValuesAsync(new List<string> { stagingPayload.TicketId }, ticketAttributes, cancellationToken);
            var ticketStagingInfoTask = _stagingRequirementRepository.GetTicketTaskStagingInfoAsync(filter, cancellationToken);
            var allStagingRequirementsTask = _stagingRequirementRepository.GetAllStagingRequirementsAsync();

            await Task.WhenAll(ticketAttributeDataTask, ticketStagingInfoTask, allStagingRequirementsTask);

            var ticketAttributeValues = ticketAttributeDataTask.Result.FirstOrDefault().TicketAttributeValues;
            var ticketTaskStagingInfo = ticketStagingInfoTask.Result.FirstOrDefault(x => x.TaskName == stagingPayload.TaskName);

            var response = new TicketStagingInfo
            {
                TicketId = stagingPayload.TicketId,
                TicketNumber = stagingPayload.TicketNumber,
                TaskName = stagingPayload.TaskName,
                StagingInfo = new()
            };

            foreach (var req in allStagingRequirementsTask.Result)
            {
                var stagingReq = req.StagingRequirementName.GetStagingNameKey();
                var isStagingRequirementApplicable = ticketTaskStagingInfo.StagingReq != null && ticketTaskStagingInfo.StagingReq.Contains(stagingReq);

                response.StagingInfo.Add(new StagingInfo
                {
                    StagingRequirement = req.StagingRequirementName,
                    IsRequirementApplicable = isStagingRequirementApplicable,
                    IsStaged = !isStagingRequirementApplicable || GetStagingRequirementStatus(ticketTaskStagingInfo.StagingStatus, stagingReq),
                    StagingData = StagingRequirementReportConstant.StagingRequirementInfoAttributes.TryGetValue(req.StagingRequirementName, out var taskStagingDict)
                                    ? ticketAttributeValues.Where(x => taskStagingDict.Contains(x.Name)).ToList()
                                    : new()
                });
            }

            return response;
        }

        public async Task<StagingRequirementData> GetStagingRequirementReportAsync(StagingRequirementReportFilter filter, CancellationToken cancellationToken)
        {
            var configurableViewColumnsTask = _configurableViewsProvider.GetConfigurableViewFieldsAsync(filter.ViewId, filter.ReportName, cancellationToken);
            var tenantLocalDateTimeTask = _tenantRepository.GetTenantCurrentTimeAsync(ApplicationContext.Current.TenantId, cancellationToken);
            var tenantStagingRequirementsTask = _stagingRequirementRepository.GetAllStagingRequirementsAsync();

            await Task.WhenAll(configurableViewColumnsTask, tenantLocalDateTimeTask, tenantStagingRequirementsTask);

            var configurableViewColumns = configurableViewColumnsTask.Result;
            var tenantLocalDateTime = tenantLocalDateTimeTask.Result;
            var tenantStagingRequirements = tenantStagingRequirementsTask.Result;

            var configurableViewTicketAttributes = configurableViewColumns.Columns.Where(m => m.Category == FieldCategory.TicketAttribute).Select(m => m.FieldName).ToList();

            var ticketAttributeName = new List<string>();
            ticketAttributeName.AddRange(configurableViewTicketAttributes);
            ticketAttributeName.AddRange(StagingRequirementReportConstant.StagingRequirementAttributes.SelectMany(x => x.Value).ToList());
            ticketAttributeName.AddRange(StagingRequirementReportConstant.StagingRequirementInfoAttributes.SelectMany(x => x.Value).ToList());

            var stagingRequirementData = await _stagingRequirementRepository.GetStagingRequirementDataAsync(filter, ticketAttributeName.Distinct().ToList(), tenantLocalDateTime, tenantStagingRequirements, configurableViewTicketAttributes, cancellationToken);

            return stagingRequirementData;
        }

        public async Task UpdateTicketTaskStagingStateAsync(List<TicketTaskStagingPayload> ticketTaskStagingPayload, CancellationToken cancellationToken)
        {
            await _stagingRequirementRepository.UpdateTicketTaskStagingStateAsync(ticketTaskStagingPayload, cancellationToken);
            await _stagingRequirementRepository.UpdateStagingStatusInTicketDataCache(ticketTaskStagingPayload.Select(x => x.TicketId).ToList(), cancellationToken);
        }



        #region Privete Methods
        private static bool GetStagingRequirementStatus(List<StagingStatus> stagingStatus, string stagingReq)
        {
            return stagingStatus.Count > 0 && (bool)stagingStatus.Find(x => x.StagingNameKey == stagingReq)?.IsStaged;
        }

        private static StagingRequirementKPIData CalculateStagingKpis(List<TicketTaskStagingData> data, DateTime tenantLocalDateTime)
        {
            var response = new StagingRequirementKPIData
            {
                TotalTicketTasks = data.Count,
                UrgentTicketTasks = GetUrgentUnstagedTicketTaskCount(data, tenantLocalDateTime),
                UnstagedArtProofs = GetTicketTaskUnstagedCount(data, "IsArtProofsStaged"),
                UnstagedPlates = GetTicketTaskUnstagedCount(data, "IsPlatesStaged"),
                UnstagedInks = GetTicketTaskUnstagedCount(data, "IsInksStaged"),
                UnstagedCylinders = GetTicketTaskUnstagedCount(data, "IsCylindersStaged"),
                UnstagedTools = GetTicketTaskUnstagedCount(data, "IsToolsStaged"),
                UnstagedSubstrates = GetTicketTaskUnstagedCount(data, "IsSubstratesStaged"),
                UnstagedCores = GetTicketTaskUnstagedCount(data, "IsCoresStaged")
            };

            return response;
        }

        private static int GetTicketTaskUnstagedCount(List<TicketTaskStagingData> data, string StagingNameKey)
        {
            return data.Count(x =>
                x.StagingReq != null
                && x.StagingReq.Contains(StagingNameKey)
                && (x.StagingStatus.Count == 0
                    || x.StagingStatus.Any(z => z.StagingNameKey == StagingNameKey && !(bool)z.IsStaged)));
        }

        private static int GetUrgentUnstagedTicketTaskCount(List<TicketTaskStagingData> data, DateTime tenantLocalDateTime)
        {
            return data.Count(x =>
                (x.StartsAt - tenantLocalDateTime).TotalHours <= 4
                && x.StagingReq != null
                && (x.StagingStatus.Count == 0
                    || x.StagingStatus.Any(z => z.IsStaged == false)));
        }
        #endregion
    }
}
using Batched.Common;
using Batched.Reporting.Contracts;
using Batched.Reporting.Contracts.Interfaces;
using Batched.Reporting.Contracts.Models;
using Batched.Reporting.Contracts.Models.LeadTimeManager;
using Batched.Reporting.Shared;
using Batched.Reporting.Contracts.Models.Reservations;

namespace Batched.Reporting.Core
{
    public class LeadTimeReportProvider : ILeadTimeProvider
    {
        private readonly IEquipmentRepository _equipmentRepository;
        private readonly ICachedEquipmentRepository _cachedEquipmentRepository;
        private readonly ITicketTaskRepository _ticketTaskRepository;
        private readonly IFacilityRepository _facilityRepository;
        private readonly ITenantRepository _tenantRepository;
        private readonly IReservationsRepository _reservationsRepository;
        private readonly IConfigurableViewsProvider _configurableViewsProvider;

        public LeadTimeReportProvider(IEquipmentRepository equipmentRepository, ICachedEquipmentRepository cachedEquipmentRepository, ITicketTaskRepository ticketTaskRepository, IFacilityRepository facilityRepository, ITenantRepository tenantRepository, IReservationsRepository reservationsRepository, IConfigurableViewsProvider configurableViewsProvider)
        {
            _equipmentRepository = equipmentRepository;
            _cachedEquipmentRepository = cachedEquipmentRepository;
            _ticketTaskRepository = ticketTaskRepository;
            _facilityRepository = facilityRepository;
            _tenantRepository = tenantRepository;
            _reservationsRepository = reservationsRepository;
            _configurableViewsProvider = configurableViewsProvider;
        }

        public async Task<List<LeadTimeDashboardFilter>> GetFilterDataAsync(DashboardFilter filter, CancellationToken cancellationToken)
        {
            var equipmentTicketsTask = _equipmentRepository.GetEquipmentWiseTicketsAysnc(filter, cancellationToken);
            var equipmentFilterDataTask = _cachedEquipmentRepository.GetFilterDataAsync(filter, cancellationToken);

            await Task.WhenAll(equipmentTicketsTask, equipmentFilterDataTask);

            var equipmentTickets = equipmentTicketsTask.Result;
            var equipmentFilterData = equipmentFilterDataTask.Result;

            return ToLeadTimeReportFilterData(equipmentTickets, equipmentFilterData);
        }

        public async Task<LeadTimeManagerKpi> GetKpiAsync(DashboardFilter filter, CancellationToken cancellationToken)
        {
            var tenantLocalDateTime = await _tenantRepository.GetTenantCurrentTimeAsync(ApplicationContext.Current?.TenantId, cancellationToken);
            var maxEquipmentCalendarDate = tenantLocalDateTime.AddDays(Constants.MaxEquipmentCalendarGenerationDays);
            var filterDataTask = _equipmentRepository.GetAllEquipmentsDataAsync(filter, cancellationToken);
            var ticketsDemandTask = _ticketTaskRepository.GetTicketsDemandAsync(filter, maxEquipmentCalendarDate, cancellationToken);
            var allEquipmentsCapacityTask = _equipmentRepository.GetEquipmentsCapacityAsync(filter.StartDate, maxEquipmentCalendarDate, cancellationToken);
            var facilityHolidayCountTask = _facilityRepository.GetFacilityHolidaysCountAsync(filter.Facilities, filter.StartDate, filter.EndDate);
            var allFacilityWiseHolidaysTask = _facilityRepository.GetAllFacilityWiseHolidays(filter.Facilities);
            var reservationEventsTask = _reservationsRepository.GetReservationEventAsync(cancellationToken);
            await Task.WhenAll(ticketsDemandTask, allEquipmentsCapacityTask, facilityHolidayCountTask, allFacilityWiseHolidaysTask, reservationEventsTask, filterDataTask);

            var ticketsDemand = ticketsDemandTask.Result;
            var allEquipmentsCapacity = allEquipmentsCapacityTask.Result;
            var facilityHolidayCount = facilityHolidayCountTask.Result;
            var reservationEvents = reservationEventsTask.Result;
            var filterData = filterDataTask.Result;
            var allFacilityWiseHolidays = allFacilityWiseHolidaysTask.Result;

            var equipmentDetails = flattenEquipmentDetails(filterData);
            return CalculateKpiValues(ticketsDemand, allEquipmentsCapacity, facilityHolidayCount, filter, tenantLocalDateTime, reservationEvents, equipmentDetails, allFacilityWiseHolidays);

        }
        public async Task<List<CapacitySummary>> GetCapacitySummaryAsync(DashboardFilter filter, CancellationToken cancellationToken)
        {
            var tenantLocalDateTime = await _tenantRepository.GetTenantCurrentTimeAsync(ApplicationContext.Current?.TenantId, cancellationToken);
            var maxEquipmentCalendarDate = tenantLocalDateTime.AddDays(Constants.MaxEquipmentCalendarGenerationDays);
            var filterDataTask = _equipmentRepository.GetAllEquipmentsDataAsync(filter, cancellationToken);
            var ticketsDemandTask = _ticketTaskRepository.GetTicketsDemandAsync(filter, maxEquipmentCalendarDate, cancellationToken);
            var facilityHolidayCountTask = _facilityRepository.GetFacilityHolidaysCountAsync(filter.Facilities, filter.StartDate, filter.EndDate);
            var allFacilityWiseHolidaysTask = _facilityRepository.GetAllFacilityWiseHolidays(filter.Facilities);
            var allEquipmentsCapacityTask = _equipmentRepository.GetEquipmentsCapacityAsync(filter.StartDate, maxEquipmentCalendarDate, cancellationToken);
            var reservationEventsTask = _reservationsRepository.GetReservationEventAsync(cancellationToken);
            await Task.WhenAll(ticketsDemandTask, facilityHolidayCountTask, allEquipmentsCapacityTask, filterDataTask, reservationEventsTask, allFacilityWiseHolidaysTask);

            var ticketsDemand = ticketsDemandTask.Result;
            var allEquipmentsCapacity = allEquipmentsCapacityTask.Result;
            var facilityHolidayCount = facilityHolidayCountTask.Result;
            var filterData = filterDataTask.Result;
            var reservationEvents = reservationEventsTask.Result;
            var allFacilityWiseHolidays = allFacilityWiseHolidaysTask.Result;

            var equipmentDetails = flattenEquipmentDetails(filterData);

            var demandForSelectedDateRange = ticketsDemand
                .Where(x => x.ShipByDate <= filter.EndDate && (filter.Tickets.Count == 0 || filter.Tickets.Contains(x.SourceTicketId))).ToList();

            var equipmentWiseTicketsDemand = MapTicketDemandToEquipmentDetails(equipmentDetails, demandForSelectedDateRange, filter);

            var currentEquipments = demandForSelectedDateRange.Select(x => x.EquipmentId).Distinct().ToList();
            var equipmentsWithFacility = demandForSelectedDateRange.GroupBy(x => x.EquipmentId)
                .Select(g => new EquipmentDto { Id = g.Key, FacilityId = g.First().FacilityId }).ToList();
            var currentEquipmentsCapacity = allEquipmentsCapacity.Where(x => currentEquipments.Contains(x.EquipmentId)).ToList();


            var equipmentCapacityForDateRange = currentEquipmentsCapacity.Where(x => x.TheDate >= filter.StartDate && x.TheDate <= filter.EndDate).ToList();
            var reservationEventsForDateRange = reservationEvents.Where(x => x.Date >= filter.StartDate && x.Date <= filter.EndDate).ToList();
            var equipmentDowntimes = CalculateDayWiseDowntimes(equipmentCapacityForDateRange);
            var plannedDownTimeHours = CalculatePlannedDowntimeHours(equipmentsWithFacility, equipmentDowntimes, facilityHolidayCount);

            var nextAvailableDateInfo = ticketsDemand.Count > 0 ? GetNextAvailableDateInfo(ticketsDemand, currentEquipmentsCapacity, tenantLocalDateTime, reservationEvents) : new();

            var result = equipmentWiseTicketsDemand.GroupBy(s => s.FacilityId).Select(group => new CapacitySummary
            {
                Id = group.Key,
                Name = group.FirstOrDefault()?.FacilityName,
                Type = Constants.EquipmentLevel.Facility,
                CapacitySummaryData = CalculateGroupedCapacityConfigData(group, allEquipmentsCapacity, equipmentCapacityForDateRange, plannedDownTimeHours, nextAvailableDateInfo.EquipmentWiseNextAvailableDate, reservationEventsForDateRange, allFacilityWiseHolidays),
                DownStreamSummary = group.Any(x => x.ValueStreamId != null) ?
                             GetValueStreamLevelCapacitySummary(group, allEquipmentsCapacity, equipmentCapacityForDateRange, plannedDownTimeHours, nextAvailableDateInfo.EquipmentWiseNextAvailableDate, nextAvailableDateInfo.WorkcenterWiseNextAvailableDate, reservationEventsForDateRange, allFacilityWiseHolidays)
                            : GetWorkcenterLevelCapacitySummary(group, allEquipmentsCapacity, equipmentCapacityForDateRange, plannedDownTimeHours, nextAvailableDateInfo.EquipmentWiseNextAvailableDate, nextAvailableDateInfo.WorkcenterWiseNextAvailableDate, reservationEventsForDateRange, allFacilityWiseHolidays)
            }).ToList();

            CalculateMaxNextAvailableDateForFacilityVsLevel(result);

            return result;
        }
        private static List<CapacitySummary> CalculateMaxNextAvailableDateForFacilityVsLevel(List<CapacitySummary> summary)
        {
            using (Tracer.Benchmark("calc-max-nextavailabledate-facility-valuestream-level"))
                foreach (var facilitySummary in summary)
                {
                    foreach (var vsSummary in facilitySummary.DownStreamSummary)
                    {
                        vsSummary.CapacitySummaryData.NextAvailableDate = vsSummary.DownStreamSummary.Max(x => x.CapacitySummaryData.NextAvailableDate);
                        vsSummary.CapacitySummaryData.ActualLeadTimeDays = vsSummary.DownStreamSummary.Max(x => x.CapacitySummaryData.ActualLeadTimeDays);
                    }
                    facilitySummary.CapacitySummaryData.NextAvailableDate = facilitySummary.DownStreamSummary.Max(x => x.CapacitySummaryData.NextAvailableDate);
                    facilitySummary.CapacitySummaryData.ActualLeadTimeDays = facilitySummary.DownStreamSummary.Max(x => x.CapacitySummaryData.ActualLeadTimeDays);
                }
            return summary;
        }

        public async Task<List<CapacityOverview>> GetCapacityOverviewsAsync(DashboardFilter filter, CancellationToken cancellationToken)
        {
            var reservationEventsTask = _reservationsRepository.GetReservationEventAsync(cancellationToken);
            var equipmentDetailsTask = _equipmentRepository.GetAllEquipmentsDataAsync(filter, cancellationToken);
            var ticketsDemandTask = _ticketTaskRepository.GetTicketsDemandAsync(filter, filter.EndDate, cancellationToken);
            var allEquipmentsCapacityTask = _equipmentRepository.GetEquipmentsCapacityAsync(filter.StartDate, filter.EndDate, cancellationToken);

            await Task.WhenAll(ticketsDemandTask, allEquipmentsCapacityTask, equipmentDetailsTask, reservationEventsTask);

            var ticketsDemand = ticketsDemandTask.Result;
            var allEquipmentsCapacity = allEquipmentsCapacityTask.Result;
            var allEquipmentDetails = equipmentDetailsTask.Result;
            var reservationEvents = reservationEventsTask.Result;

            var equipmentDetails = flattenEquipmentDetails(allEquipmentDetails);
            equipmentDetails = ApplyDashboardFilter(filter, equipmentDetails);
            var dailyEquipmentCapacity = MapDemandToEquipmentCapacity(equipmentDetails, allEquipmentsCapacity, ticketsDemand, filter);

            var capacityOverview = dailyEquipmentCapacity.GroupBy(x => x.FacilityId)
                .Select(facilityGroup => new CapacityOverview
                {
                    Id = facilityGroup.First().FacilityId,
                    Name = facilityGroup.First().FacilityName,
                    Type = Constants.EquipmentLevel.Facility,
                    CapacityOverviewData = GetCapacityOverviewData(facilityGroup.ToList(), reservationEvents, Constants.EquipmentLevel.Facility, facilityGroup.Select(fc => fc.WorkcenterId).ToList()),
                    DownStreamOverview = GetGroupLevelCapacityOverview(facilityGroup.ToList(), reservationEvents),
                }).ToList();

            return capacityOverview;
        }

        public async Task<CapacityOutlookOverTimeResponse> GetCapacityOutlookOverTimeAsync(DashboardFilter filter, CancellationToken cancellationToken)
        {
            var response = new CapacityOutlookOverTimeResponse();
            var dailyCapacityOutlookTask = _equipmentRepository.GetDailyEquipmentCapacityOutlookAsync(filter, cancellationToken);
            var ticketsDemandTask = _ticketTaskRepository.GetTicketsDemandAsync(filter, filter.EndDate, cancellationToken);
            var equipmentDetailsTask = _equipmentRepository.GetAllEquipmentsDataAsync(filter, cancellationToken);
            var reservationEventsTask = _reservationsRepository.GetReservationEventAsync(cancellationToken);

            await Task.WhenAll(dailyCapacityOutlookTask, ticketsDemandTask, reservationEventsTask, equipmentDetailsTask);
            var dailyCapacityOutlook = dailyCapacityOutlookTask.Result;
            var ticketsDemand = ticketsDemandTask.Result;
            var reservationEvents = reservationEventsTask.Result;
            var filterData = equipmentDetailsTask.Result;

            var equipmentDetails = flattenEquipmentDetails(filterData);

            var reservationEventsForDateRange = reservationEvents.Where(x => x.Date >= filter.StartDate && x.Date <= filter.EndDate).ToList();
            var filteredEquipmentDetails = ApplyDashboardFilter(filter, equipmentDetails);
            var workcentersApplicable = filteredEquipmentDetails.Select(x => x.WorkcenterId).ToList();
            var filteredReservationEvents = reservationEventsForDateRange
                .Where(x => workcentersApplicable.Contains(x.WorkcenterId))
                .ToList();

            var dailyCapacityOutlookData = MapDemandAndDowntimeHoursToOutlook(dailyCapacityOutlook, ticketsDemand, filteredReservationEvents);
            response.CapacityOutlookOverTime = TranslateToCapacityOutLookOverTime(dailyCapacityOutlookData, filteredReservationEvents, filter);

            return response;
        }

        public async Task<OpenTicketDetailsResponse> GetOpenTicketsLTMAsync(LeadTimeManagerFilters filter, CancellationToken cancellationToken)
        {
            var configurableViewColumns = await _configurableViewsProvider.GetConfigurableViewFieldsAsync(filter.ViewId, filter.ReportName, cancellationToken);

            if (configurableViewColumns.NoViewFound)
                throw ClientSideError.InvalidRequest("Invalid ViewId provided.");

            var tenantLocalTimeTask = _tenantRepository.GetTenantCurrentTimeAsync(ApplicationContext.Current.TenantId, cancellationToken);
            var ticketAttributesAvailableInCacheTask = _ticketTaskRepository.GetTicketAttributesAvailableInCacheTable();
            var lastRunInfoTask = _ticketTaskRepository.GetLastJobRunInfoAsync(cancellationToken);
            var equipmentValueStreamsTask = _equipmentRepository.GetEquipmentValueStreams();

            await Task.WhenAll(tenantLocalTimeTask, ticketAttributesAvailableInCacheTask, lastRunInfoTask, equipmentValueStreamsTask);

            var tenantLocalTime = tenantLocalTimeTask.Result;
            var attributesAvailableInCache = ticketAttributesAvailableInCacheTask.Result;
            var lastRunInfo = lastRunInfoTask.Result;
            var equipmentValueStreams = equipmentValueStreamsTask.Result;

            var openTicketsData = await _ticketTaskRepository.GetOpenTicketsLTMAsync(filter, attributesAvailableInCache, configurableViewColumns.Columns, cancellationToken);

            openTicketsData = FilterScheduleData(openTicketsData, filter, equipmentValueStreams);
            ComputeScheduleData(openTicketsData, tenantLocalTime, lastRunInfo);
            openTicketsData = GetSortedScheduleData(openTicketsData, filter);

            return new()
            {
                OpenTickets = openTicketsData
            };
        }


        private static List<dynamic> GetSortedScheduleData(List<dynamic> openTicketsData, LeadTimeManagerFilters filter)
        {
            if (string.IsNullOrEmpty(filter.SortField))
            {
                return openTicketsData
                    .OrderBy(item => ((IDictionary<string, object>)item)["shipByDate"])
                    .ThenBy(item => ((IDictionary<string, object>)item)["ticketNumber"])
                    .ToList();
            }

            if (filter.SortBy.Equals("asc"))
            {
                return openTicketsData
                    .OrderBy(item => ((IDictionary<string, object>)item)[filter.SortField])
                    .ToList();
            }

            return openTicketsData
                .OrderByDescending(item => ((IDictionary<string, object>)item)[filter.SortField])
                .ToList();
        }

        private static List<dynamic> FilterScheduleData(List<dynamic> openTicketsData, LeadTimeManagerFilters filter, List<EquipmentValueStreams> equipmentValueStreams)
        {
            var filteredData = openTicketsData.Where(data =>
            {
                var equipmentValueStream = equipmentValueStreams.FirstOrDefault(ev => ev.EquipmentId == (string)data.equipmentId || ev.EquipmentId == (string)data.originalEquipmentId);

                return (filter.Workcenters.Count == 0 || filter.Workcenters.Contains((string)data.workcenterId)) &&
                       (filter.Equipments.Count == 0 || filter.Equipments.Contains((string)data.equipmentId) || filter.Equipments.Contains((string)data.originalEquipmentId)) &&
                       (filter.Tickets.Count == 0 || filter.Tickets.Contains((string)data.ticketNumber)) &&
                       (filter.Facilities.Count == 0 || filter.Facilities.Contains((string)data.facilityId)) &&
                       (filter.ValueStreams.Count == 0 || (equipmentValueStream != null && equipmentValueStream.ValueStreams.Any(vs => filter.ValueStreams.Contains(vs)))) &&
                       (string.IsNullOrEmpty(filter.ScheduleStatus) || (filter.ScheduleStatus.Equals("Scheduled") && (string)data.scheduleId != null) || (filter.ScheduleStatus.Equals("Unscheduled") && (string)data.scheduleId == null));
            }).ToList();

            return filteredData;
        }

        private static void ComputeScheduleData(List<dynamic> openTicketsData, DateTime tenantLocalTime, List<LastRunInfo> lastRunTicketInfos)
        {
            foreach (var item in openTicketsData)
            {
                var dict = (IDictionary<string, object>)item;

                item.scheduledHours = (object)CalculateScheduledHours(dict);
                item.isOnPress = (object)CalculateIsOnPress(dict, lastRunTicketInfos);
                item.taskStatus = (object)CalculateTaskStatus(dict, tenantLocalTime);
            }
        }

        private static string CalculateTaskStatus(IDictionary<string, object> dict, DateTime tenantLocalTime)
        {
            var shipByDate = dict["shipByDate"];

            DateTime? estMaxDueDateTime = null;
            DateTime? endsAt = null;
            bool? isComplete = null;

            if (dict.TryGetValue("isComplete", out var value) && value is bool boolValue)
                isComplete = boolValue;

            if (dict.TryGetValue("estMaxDueDateTime", out var value1) && value1 is DateTime dateValue1)
                estMaxDueDateTime = dateValue1;

            if (dict.TryGetValue("endsAt", out var value2) && value2 is DateTime dateValue2)
                endsAt = dateValue2;

            var dueDateAndCurrentDateDiff = (estMaxDueDateTime - tenantLocalTime).GetValueOrDefault().TotalHours;
            var dueDateAndTaskEndsAtDiff = (estMaxDueDateTime - endsAt).GetValueOrDefault().TotalHours;

            if (isComplete ?? false)
                return "Complete";
            else if (shipByDate == null)
                return "Late";
            else if (endsAt == null)
                return "Unscheduled";
            else if (tenantLocalTime > estMaxDueDateTime || endsAt > estMaxDueDateTime)
                return "Late";
            else if (dueDateAndCurrentDateDiff < 4 || dueDateAndTaskEndsAtDiff < 4)
                return "At Risk";
            else if (tenantLocalTime > endsAt)
                return "Behind";
            else
                return "On Track";
        }

        private static bool CalculateIsOnPress(IDictionary<string, object> dict, List<LastRunInfo> lastRunTicketInfos)
        {
            string sourceTicketId = dict["ticketNumber"]?.ToString();
            string equipmentId = dict["equipmentId"]?.ToString();

            return lastRunTicketInfos.Any(x => x.LastRunEquipmentId == equipmentId && x.SourceTicketId == sourceTicketId);
        }

        private static string CalculateScheduledHours(IDictionary<string, object> dict)
        {
            string scheduleId = dict["scheduleId"]?.ToString();

            float? actualEstTotalHours = null;
            float? taskMinutes = null;
            float? changeoverMinutes = null;

            if (dict.TryGetValue("actualEstTotalHours", out var value1) && float.TryParse(value1?.ToString(), out float dataValue1))
                actualEstTotalHours = dataValue1;

            if (dict.TryGetValue("taskMinutes", out var value2) && float.TryParse(value2?.ToString(), out float dataValue2))
                taskMinutes = dataValue2;

            if (dict.TryGetValue("changeoverMinutes", out var value3) && float.TryParse(value3?.ToString(), out float dataValue3))
                changeoverMinutes = dataValue3;

            var scheduledHours = scheduleId == null
                ? (actualEstTotalHours ?? 0F)
                : (((taskMinutes ?? 0F) + (changeoverMinutes ?? 0F)) / 60);

            return scheduledHours.FormatNumber();
        }



        private static List<CapacityOverview> GetGroupLevelCapacityOverview(List<DailyEquipmentCapaityOverview> facilityGroup,
            List<ReservationEventDto> reservationEvents)
        {
            return facilityGroup.Any(x => x.ValueStreamId != null) ?
                    facilityGroup.GroupBy(x => x.ValueStreamId)
                    .Select(vsGroup => new CapacityOverview
                    {
                        Id = vsGroup.First().ValueStreamId,
                        Name = vsGroup.First().ValueStreamName,
                        Type = Constants.EquipmentLevel.ValueStream,
                        CapacityOverviewData = GetCapacityOverviewData(vsGroup.ToList(), reservationEvents, Constants.EquipmentLevel.ValueStream, vsGroup.Select(x => x.WorkcenterId).ToList()),
                        DownStreamOverview = vsGroup.GroupBy(x => x.WorkcenterId)
                                .Select(wcGroup => new CapacityOverview
                                {
                                    Id = wcGroup.First().WorkcenterId,
                                    Name = wcGroup.First().WorkcenterName,
                                    Type = Constants.EquipmentLevel.Workcenter,
                                    CapacityOverviewData = GetCapacityOverviewData(wcGroup.ToList(), reservationEvents, Constants.EquipmentLevel.Workcenter, new List<string> { wcGroup.First().WorkcenterId }),
                                    DownStreamOverview = GetEquipmentLevelCapacityOverview(wcGroup.ToList(), reservationEvents)
                                }).ToList(),
                    }).ToList() :
                    facilityGroup.GroupBy(x => x.WorkcenterId)
                    .Select(wcGroup => new CapacityOverview
                    {
                        Id = wcGroup.First().WorkcenterId,
                        Name = wcGroup.First().WorkcenterName,
                        Type = Constants.EquipmentLevel.Workcenter,
                        CapacityOverviewData = GetCapacityOverviewData(wcGroup.ToList(), reservationEvents, Constants.EquipmentLevel.Workcenter, new List<string> { wcGroup.First().WorkcenterId }),
                        DownStreamOverview = GetEquipmentLevelCapacityOverview(wcGroup.ToList(), reservationEvents)
                    }).ToList();
        }

        private static List<CapacityOverview> GetEquipmentLevelCapacityOverview(List<DailyEquipmentCapaityOverview> wcGroup,
             List<ReservationEventDto> reservationEvents)
        {
            return wcGroup.Any() ? wcGroup.GroupBy(x => x.EquipmentId).Select(equipment => new CapacityOverview
            {
                Id = equipment.First().EquipmentId,
                Name = equipment.First().EquipmentName,
                Type = Constants.EquipmentLevel.Equipment,
                DownStreamOverview = new List<CapacityOverview>(),
                CapacityOverviewData = GetCapacityOverviewData(equipment.ToList(), reservationEvents, Constants.EquipmentLevel.Equipment, new List<string> { equipment.First().EquipmentId })
            }).ToList() : new List<CapacityOverview>();
        }

        private static List<CapacityOverviewData> GetCapacityOverviewData(List<DailyEquipmentCapaityOverview> dailyEquipmentCapacities,
             List<ReservationEventDto> reservationEvents, string equipmentLevel, List<string> ids)
        {
            dailyEquipmentCapacities = dailyEquipmentCapacities.GroupBy(x => new { x.EquipmentId, x.TheDate })
                .Select(x => x.First()).ToList();

            return dailyEquipmentCapacities.GroupBy(x => x.TheDate)
                .Select(x => new CapacityOverviewData
                {
                    TheDate = x.First().TheDate,
                    AvailabilityThreshold = x.Max(x => x.AvailabilityThreshold),
                    AvailableCapacity = x.Sum(x => x.TotalAvailableCapacity) - GetNetReservedDemand(reservationEvents, equipmentLevel, ids, x.First().TheDate),
                    TotalCapacity = x.Sum(x => x.ActualCapacityHours),
                    TotalDemandHours = x.GroupBy(x => new { x.EquipmentId, x.ValueStreamId }) //this group by equipment and valuestream is for nullifying the duplicate records due to one equipment in 2 valueStreams
                    .Select(x => x.First()).Sum(x => x.TotalDemandHours) + GetNetReservedDemand(reservationEvents, equipmentLevel, ids, x.First().TheDate),
                    IsAvailable = CalculateAvailabilityOfEquipment(x.Sum(x => x.TotalAvailableCapacity), x.Max(x => x.AvailabilityThreshold))
                }).ToList();
        }

        private static float GetNetReservedDemand(List<ReservationEventDto> reservationEvents, string equipmentLevel, List<string> ids, DateTime date)
        {
            if (reservationEvents == null || !reservationEvents.Any())
                return 0;

            if (equipmentLevel == Constants.EquipmentLevel.Equipment)
                return (float)reservationEvents
                    .Where(re => re.Date == date && ids.First() == re.EquipmentId).Sum(re => re.NetReservedDemand);
            else
                return (float)reservationEvents
                    .Where(re => re.Date == date && ids.Contains(re.WorkcenterId)).Sum(re => re.NetReservedDemand);
        }

        private static float GetNetReservedDemand(List<ReservationEventDto> reservationEvents, string equipmentLevel, List<string> ids)
        {
            if (reservationEvents == null || !reservationEvents.Any())
                return 0;

            if (equipmentLevel == Constants.EquipmentLevel.Equipment)
                return (float)reservationEvents
                    .Where(re => ids.First() == re.EquipmentId).Sum(re => re.NetReservedDemand);
            else
                return (float)reservationEvents
                    .Where(re => ids.Contains(re.WorkcenterId)).Sum(re => re.NetReservedDemand);
        }
        private static List<DailyEquipmentCapaityOverview> MapDemandToEquipmentCapacity(List<EquipmentDetails> equipmentDetails, List<DailyEquipmentCapacity> dailyEquipmentCapacities, List<TicketsDemand> ticketsDemandData, DashboardFilter filterData)
        {
            var result = new List<DailyEquipmentCapaityOverview>();

            ticketsDemandData = ticketsDemandData.GroupBy(x => new { x.TicketId, x.EquipmentId, x.ShipByDate })
                .Select(x => x.First()).ToList();
            var ticketDemandByDateAndEquipment = ticketsDemandData.Where(x => x.ShipByDate.HasValue)
                .GroupBy(x => new { ShipByDate = x.ShipByDate.Value.Date, x.EquipmentId })
                .ToDictionary(g => g.Key, g => g.Sum(x => x.EstTotalHours));

            var equipmentWiseLateTasksHours = ticketsDemandData.Where(x => x.ShipByDate == null || x.ShipByDate.Value.Date < DateTime.Today)
                                .GroupBy(x => x.EquipmentId).ToDictionary(g => g.Key, g => g.Sum(x => x.EstTotalHours));

            Parallel.ForEach(dailyEquipmentCapacities, (capacity) =>
            {
                capacity.DemandHours = ticketDemandByDateAndEquipment.TryGetValue(new { ShipByDate = capacity.TheDate.Date, capacity.EquipmentId }, out var totalHours)
                                            ? totalHours : 0;
            });

            foreach (var capacity in dailyEquipmentCapacities.GroupBy(x => x.EquipmentId))
                capacity.First().DemandHours += equipmentWiseLateTasksHours.GetValueOrDefault(capacity.First().EquipmentId);

            foreach (var equipment in equipmentDetails)
            {
                var currentEquipmentsDailyCapacity = dailyEquipmentCapacities.Where(x => x.EquipmentId == equipment.EquipmentId)
                    .OrderBy(x => x.TheDate).ToList();

                if (currentEquipmentsDailyCapacity.Any())
                    foreach (var dailyCapacity in currentEquipmentsDailyCapacity)
                    {
                        result.Add(new DailyEquipmentCapaityOverview()
                        {
                            FacilityId = equipment.FacilityId,
                            FacilityName = equipment.FacilityName,
                            ValueStreamId = equipment.ValueStreamId,
                            ValueStreamName = equipment.ValueStreamName,
                            WorkcenterId = equipment.WorkcenterId,
                            WorkcenterName = equipment.WorkcenterName,
                            EquipmentId = equipment.EquipmentId,
                            EquipmentName = equipment.EquipmentName,
                            TheDate = dailyCapacity.TheDate,
                            TotalDemandHours = dailyCapacity.DemandHours,
                            TotalCapacityHours = dailyCapacity.TotalCapacityHours,
                            ActualCapacityHours = dailyCapacity.IsHoliday ? 0 : (dailyCapacity.ActualCapacityHours - dailyCapacity.DowntimeHours),
                            AvailabilityThreshold = dailyCapacity.AvailabilityThreshold,
                            TotalAvailableCapacity = dailyCapacity.IsHoliday ? 0 : dailyCapacity.ActualCapacityHours -
                                                            (dailyCapacity.DemandHours + dailyCapacity.DowntimeHours),
                            IsAvailable = CalculateAvailabilityOfEquipment(dailyCapacity),
                        });
                    }
                else
                    result.AddRange(GetCapacityOverviewForEquipmentWithNoCapacity(filterData.StartDate, filterData.EndDate, equipment, ticketsDemandData));
            }
            return result;
        }

        private static List<DailyEquipmentCapaityOverview> GetCapacityOverviewForEquipmentWithNoCapacity(DateTime startDate, DateTime endDate, EquipmentDetails equipmentDetails, List<TicketsDemand> ticketsDemand)
        {
            var result = new List<DailyEquipmentCapaityOverview>();
            var theDate = startDate;
            var lateTaskHours = ticketsDemand.Where(x => x.EquipmentId == equipmentDetails.EquipmentId && x.ShipByDate == null || x.ShipByDate.Value.Date < DateTime.Today);
            var totalLateTaskhours = lateTaskHours.Sum(x => x.EstTotalHours);

            while (theDate <= endDate)
            {
                var ticketDemand = ticketsDemand.Where(x => x.EquipmentId == equipmentDetails.EquipmentId && x.ShipByDate.HasValue && x.ShipByDate.Value.Date == theDate.Date);
                var totalTicketDemand = ticketDemand.Any() ? ticketDemand.Sum(x => x.EstTotalHours) : 0;

                result.Add(new DailyEquipmentCapaityOverview
                {
                    FacilityId = equipmentDetails.FacilityId,
                    FacilityName = equipmentDetails.FacilityName,
                    ValueStreamId = equipmentDetails.ValueStreamId,
                    ValueStreamName = equipmentDetails.ValueStreamName,
                    WorkcenterId = equipmentDetails.WorkcenterId,
                    WorkcenterName = equipmentDetails.WorkcenterName,
                    EquipmentId = equipmentDetails.EquipmentId,
                    EquipmentName = equipmentDetails.EquipmentName,
                    TheDate = theDate,
                    IsAvailable = false,
                    TotalDemandHours = startDate == theDate ? totalTicketDemand + totalLateTaskhours : totalTicketDemand,
                    TotalAvailableCapacity = (0 - (startDate == theDate ? totalTicketDemand + totalLateTaskhours : totalTicketDemand))
                });
                theDate = theDate.AddDays(1);
            }

            return result;
        }

        private static bool CalculateAvailabilityOfEquipment(float availableCapacity, int availabilityThreshold)
        {
            return availableCapacity > availabilityThreshold;
        }

        private static bool CalculateAvailabilityOfEquipment(DailyEquipmentCapacity capacity)
        {
            var availableCapacity = capacity.IsHoliday ? 0 : capacity.ActualCapacityHours - (capacity.DemandHours + capacity.DowntimeHours);
            return availableCapacity > capacity.AvailabilityThreshold;
        }

        private static List<CapacityOutlookOverTime> TranslateToCapacityOutLookOverTime(List<DailyEquipmentCapacityOutlook> dailyEquipmentCapacityOutlooks
            , List<ReservationEventDto> reservationEvents, DashboardFilter filter)
        {
            var capacityOutlook = dailyEquipmentCapacityOutlooks.GroupBy(x => x.TheDate)
                .Select(capacityGroup => new CapacityOutlookOverTime
                {
                    Date = capacityGroup.Key,
                    TotalCapacity = capacityGroup.Sum(x => x.CapacityHours),
                    TicketDemand = capacityGroup.Sum(x => x.TicketDemand),
                    DowntimeHours = capacityGroup.Sum(x => x.DowntimeHours),
                    ReservedDemand = capacityGroup.Sum(x => x.ReservedDemand),
                    TotalDemand = capacityGroup.Sum(x => x.TotalDemand),
                    UnplannedAllowance = capacityGroup.Sum(x => x.UnplannedAllowanceHours),
                    UnstaffedHours = capacityGroup.Sum(x => x.UnstaffedHours),
                    HolidayHours = capacityGroup.Sum(x => x.HolidayHours),
                    UnavailableCapacity = capacityGroup.Sum(x => x.UnavailableCapacityHours),
                    AvailableCapacityHours = capacityGroup.Sum(x => x.AvailableCapacityHours),
                    TotalCumulativeAvailableCapacity = capacityGroup.Sum(x => x.CumulativeAvailableCapacityHours)
                }).OrderBy(x => x.Date).ToList();

            if (!filter.Equipments.Any())
            {
                float previoueCumulativeAvailableCapacity = 0;
                foreach (var item in capacityOutlook)
                {
                    var netReservedDemand = reservationEvents.Any() ? (float)reservationEvents
                        .Where(x => x.Date == item.Date && x.EquipmentId == null)
                        .Sum(x => x.NetReservedDemand) : 0;

                    item.ReservedDemand += netReservedDemand;
                    item.TotalDemand += netReservedDemand;
                    item.AvailableCapacityHours -= netReservedDemand;
                    item.TotalCumulativeAvailableCapacity = previoueCumulativeAvailableCapacity + item.AvailableCapacityHours;
                    previoueCumulativeAvailableCapacity = item.TotalCumulativeAvailableCapacity;
                }
            }
            return capacityOutlook;
        }



        private static List<DailyEquipmentCapacityOutlook> MapDemandAndDowntimeHoursToOutlook(List<EquipmentCapacityOutlook> dailyCapacityOutlook,
            List<TicketsDemand> ticketsDemand, List<ReservationEventDto> reservationEvents)
        {
            var result = new List<DailyEquipmentCapacityOutlook>();
            var ticketsDemandData = DedupeTicketDemandData(ticketsDemand);

            var ticketDemandByDateAndEquipment = ticketsDemandData.Where(x => x.ShipByDate.HasValue)
                .GroupBy(x => new { ShipByDate = x.ShipByDate.Value.Date, x.EquipmentId })
                .ToDictionary(g => g.Key, g => g.Sum(x => x.EstTotalHours));

            var equipmentWiseLateTasksHours = ticketsDemandData.Where(x => x.ShipByDate == null || x.ShipByDate < DateTime.Today)
                                .GroupBy(x => x.EquipmentId).ToDictionary(g => g.Key, g => g.Sum(x => x.EstTotalHours));

            var dailyCapacityOutlookWithGroupedShifts = GroupShiftTimesOfCapacityOutlookData(dailyCapacityOutlook);

            using (Tracer.Benchmark("leadtime-provider-calculate-daily-downtime-hours"))
                foreach (var group in dailyCapacityOutlookWithGroupedShifts.GroupBy(x => x.EquipmentId))
                {
                    var demandForLateTasks = equipmentWiseLateTasksHours.GetValueOrDefault(group.Key);
                    group.First().TicketDemand = demandForLateTasks;
                    float previousCumulativeAvailableCapacity = 0;
                    foreach (var capacity in group)
                    {
                        var netReservedDemand = reservationEvents.Any() ? (float)reservationEvents.Where(x => x.Date == capacity.TheDate && x.EquipmentId == capacity.EquipmentId)
                            .Sum(x => x.NetReservedDemand) : 0;
                        capacity.ReservedDemand = netReservedDemand;

                        if (capacity.DowntimeEnd != null || capacity.DowntimeStart != null)
                            foreach (var shiftTime in capacity.ShiftTimes)
                                capacity.DowntimeHours += GetDownTimeHoursForDay(capacity.TheDate, capacity.DowntimeStart, capacity.DowntimeEnd, shiftTime.ShiftStartTime, shiftTime.ShiftEndTime);

                        capacity.TicketDemand += ticketDemandByDateAndEquipment.TryGetValue(new { ShipByDate = capacity.TheDate.Date, capacity.EquipmentId }, out var totalHours)
                                                    ? totalHours : 0;
                        capacity.TotalDemand = capacity.TicketDemand + netReservedDemand;

                        var totalCapacity = capacity.IsHoliday ? 0 : capacity.CapacityHours - (capacity.UnplannedAllowanceHours);
                        var unavailableShift = capacity.IsHoliday ? 24 : (24 - (capacity.CapacityHours + capacity.DowntimeHours));
                        var unavailableCapacity = capacity.IsHoliday ? 24 : unavailableShift + capacity.DowntimeHours + capacity.UnplannedAllowanceHours;

                        capacity.HolidayHours = capacity.IsHoliday ? 24 : 0;
                        capacity.UnavailableCapacityHours = unavailableCapacity;
                        capacity.AvailableCapacityHours = capacity.IsHoliday ? (0 - capacity.TicketDemand) :
                            (totalCapacity - (capacity.DowntimeHours + capacity.TicketDemand + capacity.ReservedDemand));

                        capacity.UnstaffedHours = unavailableShift;
                        capacity.CapacityHours = totalCapacity;

                        capacity.CumulativeAvailableCapacityHours = previousCumulativeAvailableCapacity + capacity.AvailableCapacityHours;
                        previousCumulativeAvailableCapacity = capacity.CumulativeAvailableCapacityHours;

                        result.Add(capacity);
                    }

                }
            return result;
        }

        private static float GetDownTimeHoursForDay(DateTime theDate, DateTime? DowntimeStart, DateTime? DowntimeEnd, TimeSpan? ShiftStart, TimeSpan? ShiftEnd)
        {
            var todaysShiftStart = theDate.AddMinutes(ShiftStart.HasValue ? ShiftStart.Value.TotalMinutes : 0);
            var todaysShiftEnd = theDate.AddMinutes(ShiftEnd.HasValue ? ShiftEnd.Value.TotalMinutes : 0);

            var todaysDowntimeStart = todaysShiftStart < DowntimeStart ? DowntimeStart : todaysShiftStart;
            var todaysDowntimeEnd = todaysShiftEnd < DowntimeEnd ? todaysShiftEnd : DowntimeEnd;

            var downtimeHours = (float)(todaysDowntimeEnd - todaysDowntimeStart).Value.TotalHours;
            return downtimeHours > 0 ? downtimeHours : 0;
        }

        private static List<DailyEquipmentCapacityOutlook> GroupShiftTimesOfCapacityOutlookData(List<EquipmentCapacityOutlook> dailyCapacityOutlook)
        {
            return dailyCapacityOutlook.GroupBy(x => new { x.EquipmentId, x.TheDate })
                .Select(x => new DailyEquipmentCapacityOutlook()
                {
                    TheDate = x.First().TheDate,
                    EquipmentId = x.First().EquipmentId,
                    SourceEquipmentId = x.First().SourceEquipmentId,
                    IsHoliday = x.First().IsHoliday,
                    UnplannedAllowanceHours = x.First().UnplannedAllowanceHours,
                    ShiftTimes = x.Select(t => new ShiftTime { ShiftStartTime = t.ShiftStart, ShiftEndTime = t.ShiftEnd }).ToList(),
                    FacilityId = x.First().FacilityId,
                    DowntimeStart = x.First().DowntimeStart,
                    DowntimeEnd = x.First().DowntimeEnd,
                    CapacityHours = x.Sum(c => c.CapacityHours),
                    TicketDemand = x.First().TicketDemand,
                }).ToList();
        }

        private static List<CapacitySummary> GetValueStreamLevelCapacitySummary(IGrouping<string, CapacitySummaryDto> group,
            List<DailyEquipmentCapacity> allEquipmentsCapacityOverMaxDate,
            List<DailyEquipmentCapacity> equipmentCapacityForDateRange, List<PlannedDowntimeHours> plannedDowntimes,
            List<EquipmentWiseNextAvailableDate> equipmentWiseNextAvailableDate, List<WorkcenterWiseNextAvailableDate> workcenterWiseNextAvailableDates,
            List<ReservationEventDto> reservationEvents,
            List<FacilityWiseHolidays> facilityWiseHolidays)
        {
            return group.GroupBy(vs => vs.ValueStreamId).Select(valueStreamGroup => new CapacitySummary
            {
                Id = valueStreamGroup.Key,
                Name = valueStreamGroup.FirstOrDefault()?.ValueStreamName,
                Type = Constants.EquipmentLevel.ValueStream,
                CapacitySummaryData = CalculateGroupedCapacityConfigData(valueStreamGroup, allEquipmentsCapacityOverMaxDate, equipmentCapacityForDateRange, plannedDowntimes, equipmentWiseNextAvailableDate, reservationEvents, facilityWiseHolidays),
                DownStreamSummary = GetWorkcenterLevelCapacitySummary(valueStreamGroup, allEquipmentsCapacityOverMaxDate, equipmentCapacityForDateRange, plannedDowntimes, equipmentWiseNextAvailableDate, workcenterWiseNextAvailableDates, reservationEvents, facilityWiseHolidays)
            }).ToList();
        }

        private static List<CapacitySummary> GetWorkcenterLevelCapacitySummary(IGrouping<string, CapacitySummaryDto> valueStreamGroup,
            List<DailyEquipmentCapacity> allEquipmentsCapacityOverMaxDate,
            List<DailyEquipmentCapacity> equipmentCapacityForDateRange, List<PlannedDowntimeHours> plannedDowntimes,
            List<EquipmentWiseNextAvailableDate> equipmentWiseNextAvailableDate, List<WorkcenterWiseNextAvailableDate> workcenterWiseNextAvailableDates,
            List<ReservationEventDto> reservationEvents,
            List<FacilityWiseHolidays> facilityWiseHolidays)
        {
            return valueStreamGroup.GroupBy(w => w.WorkcenterId).Select(workcenterGroup => new CapacitySummary
            {
                Id = workcenterGroup.Key,
                Name = workcenterGroup.FirstOrDefault()?.WorkcenterName,
                Type = Constants.EquipmentLevel.Workcenter,
                CapacitySummaryData = CalculateWorkcenterLevelCapacityConfigData(workcenterGroup, allEquipmentsCapacityOverMaxDate, equipmentCapacityForDateRange, plannedDowntimes, workcenterWiseNextAvailableDates, reservationEvents, facilityWiseHolidays),
                DownStreamSummary = GetEquipmentLevelCapacitySummary(workcenterGroup, allEquipmentsCapacityOverMaxDate, equipmentCapacityForDateRange, plannedDowntimes, equipmentWiseNextAvailableDate, reservationEvents, facilityWiseHolidays)
            }).ToList();
        }

        private static List<CapacitySummary> GetEquipmentLevelCapacitySummary(IGrouping<string, CapacitySummaryDto> workcenterGroup,
            List<DailyEquipmentCapacity> allEquipmentsCapacityOverMaxDate,
            List<DailyEquipmentCapacity> equipmentCapacityForDateRange, List<PlannedDowntimeHours> plannedDowntimes,
            List<EquipmentWiseNextAvailableDate> equipmentWiseNextAvailableDate,
            List<ReservationEventDto> reservationEvents,
            List<FacilityWiseHolidays> facilityWiseHolidays)
        {
            return workcenterGroup.Any() ? workcenterGroup.Select(equipment => new CapacitySummary
            {
                Id = equipment.EquipmentId,
                Name = equipment.EquipmentName,
                Type = Constants.EquipmentLevel.Equipment,
                CapacitySummaryData = CalculateEquipmentsCapacityConfigData(equipment, allEquipmentsCapacityOverMaxDate, equipmentCapacityForDateRange, plannedDowntimes, equipmentWiseNextAvailableDate, reservationEvents, facilityWiseHolidays)
            }).ToList() : new List<CapacitySummary>();
        }

        private static CapacityConfig CalculateGroupedCapacityConfigData(IGrouping<string, CapacitySummaryDto> groupLevelData,
            List<DailyEquipmentCapacity> allEquipmentsCapacityOverMaxDate,
            List<DailyEquipmentCapacity> equipmentCapacityForDateRange,
            List<PlannedDowntimeHours> plannedDowntimes,
            List<EquipmentWiseNextAvailableDate> equipmentWiseNextAvailableDate,
            List<ReservationEventDto> reservationEvents,
            List<FacilityWiseHolidays> facilityWiseHolidays)
        {
            var group = OmmitDuplicateEquipmentsFromTicketsDemandData(groupLevelData.ToList());
            var holidayDates = facilityWiseHolidays.Any(x => x.FacilityId == groupLevelData.First().FacilityId) ?
                                            facilityWiseHolidays.Where(x => x.FacilityId == groupLevelData.First().FacilityId).First().Holidays : new List<DateTime>();
            var netReservedDemand = GetNetReservedDemand(reservationEvents, Constants.EquipmentLevel.Workcenter, group.Select(wc => wc.WorkcenterId).ToList());
            var currentGroupEquipments = group.Select(x => x.EquipmentId).ToList();

            return new CapacityConfig
            {
                TotalTickets = group.SelectMany(x => x.Tickets).Distinct().Count(),
                TotalCapacity = GetTotalCapacity(equipmentCapacityForDateRange, currentGroupEquipments),
                UnplannedAllowance = GetTotalUnplannedAllowance(equipmentCapacityForDateRange, currentGroupEquipments),
                AvailableCapacity = GetAvailableCapacity(equipmentCapacityForDateRange, currentGroupEquipments, group.Sum(s => s.TicketDemand))
                                   - netReservedDemand,
                TotalDemand = group.Sum(s => s.TicketDemand) + netReservedDemand,
                TicketDemand = group.Sum(s => s.TicketDemand),
                DownTimeHolidays = GetEquipmentDownTime(plannedDowntimes, currentGroupEquipments),
                ReservedDemand = netReservedDemand,
                ExternalLeadTimeDays = group.Max(x => x.ExternalLeadTimeDays),
                ExternalNextAvailableDate = AddAvailableDaysToDate(DateTime.Today, group.Max(x => x.ExternalLeadTimeDays), allEquipmentsCapacityOverMaxDate, currentGroupEquipments),
                NextAvailableDate = GetMaxNextAvailableDate(equipmentWiseNextAvailableDate, currentGroupEquipments),
                ActualLeadTimeDays = GetMaxLeadTimeDays(equipmentWiseNextAvailableDate, currentGroupEquipments),
            };
        }

        private static CapacityConfig CalculateWorkcenterLevelCapacityConfigData(IGrouping<string, CapacitySummaryDto> groupLevelData,
            List<DailyEquipmentCapacity> allEquipmentsCapacityOverMaxDate,
            List<DailyEquipmentCapacity> equipmentCapacityForDateRange,
            List<PlannedDowntimeHours> plannedDowntimes,
            List<WorkcenterWiseNextAvailableDate> workcenterWiseNextAvailableDates,
            List<ReservationEventDto> reservationEvents,
            List<FacilityWiseHolidays> facilityWiseHolidays)
        {
            var group = OmmitDuplicateEquipmentsFromTicketsDemandData(groupLevelData.ToList());
            var holidayDates = facilityWiseHolidays.Any(x => x.FacilityId == group.First().FacilityId) ?
                                            facilityWiseHolidays.Where(x => x.FacilityId == group.First().FacilityId).First().Holidays : new List<DateTime>();
            var netReservedDemand = GetNetReservedDemand(reservationEvents, Constants.EquipmentLevel.Workcenter, group.Select(wc => wc.WorkcenterId).ToList());

            var currentGroupEquipments = group.Select(x => x.EquipmentId).ToList();

            return new CapacityConfig
            {
                TotalTickets = group.SelectMany(x => x.Tickets).Distinct().Count(),
                TotalCapacity = GetTotalCapacity(equipmentCapacityForDateRange, currentGroupEquipments),
                UnplannedAllowance = GetTotalUnplannedAllowance(equipmentCapacityForDateRange, currentGroupEquipments),
                AvailableCapacity = GetAvailableCapacity(equipmentCapacityForDateRange, currentGroupEquipments, group.Sum(s => s.TicketDemand))
                                            - netReservedDemand,
                TotalDemand = group.Sum(s => s.TicketDemand) + netReservedDemand,
                TicketDemand = group.Sum(s => s.TicketDemand),
                DownTimeHolidays = GetEquipmentDownTime(plannedDowntimes, currentGroupEquipments),
                ReservedDemand = netReservedDemand,
                ExternalLeadTimeDays = group.Max(x => x.ExternalLeadTimeDays),
                ExternalNextAvailableDate = AddAvailableDaysToDate(DateTime.Today, group.Max(x => x.ExternalLeadTimeDays), allEquipmentsCapacityOverMaxDate, currentGroupEquipments),
                NextAvailableDate = workcenterWiseNextAvailableDates.Any(x => x.WorkcenterId == group.First().WorkcenterId) ?
                                    workcenterWiseNextAvailableDates.Where(x => x.WorkcenterId == group.First().WorkcenterId).First().NextAvailableDate : null,
                ActualLeadTimeDays = workcenterWiseNextAvailableDates.Any(x => x.WorkcenterId == group.First().WorkcenterId) ?
                                    workcenterWiseNextAvailableDates.Where(x => x.WorkcenterId == group.First().WorkcenterId).First().LeadTimeDays : 0,
            };
        }

        private static CapacityConfig CalculateEquipmentsCapacityConfigData(CapacitySummaryDto equipmentSummary,
            List<DailyEquipmentCapacity> allEquipmentsCapacityOverMaxDate,
            List<DailyEquipmentCapacity> equipmentCapacityForDateRange,
            List<PlannedDowntimeHours> plannedDowntimes,
            List<EquipmentWiseNextAvailableDate> equipmentWiseNextAvailableDate,
            List<ReservationEventDto> reservationEvents,
            List<FacilityWiseHolidays> facilityWiseHolidays)
        {
            var netReservedDemand = GetNetReservedDemand(reservationEvents, Constants.EquipmentLevel.Equipment, new List<string> { equipmentSummary.EquipmentId });
            var holidayDates = facilityWiseHolidays.Any(x => x.FacilityId == equipmentSummary.FacilityId) ?
                                            facilityWiseHolidays.Where(x => x.FacilityId == equipmentSummary.FacilityId).First().Holidays : new List<DateTime>();

            var currentGroupEquipments = new List<string> { equipmentSummary.EquipmentId };

            return new CapacityConfig
            {
                TotalTickets = equipmentSummary.TotalTickets,
                TotalCapacity = GetTotalCapacity(equipmentCapacityForDateRange, currentGroupEquipments),
                UnplannedAllowance = GetTotalUnplannedAllowance(equipmentCapacityForDateRange, currentGroupEquipments),
                AvailableCapacity = GetAvailableCapacity(equipmentCapacityForDateRange, currentGroupEquipments, equipmentSummary.TicketDemand)
                                        - netReservedDemand,
                TotalDemand = equipmentSummary.TicketDemand + netReservedDemand,
                TicketDemand = equipmentSummary.TicketDemand,
                DownTimeHolidays = GetEquipmentDownTime(plannedDowntimes, currentGroupEquipments),
                ReservedDemand = netReservedDemand,
                ExternalLeadTimeDays = equipmentSummary.ExternalLeadTimeDays,
                ExternalNextAvailableDate = AddAvailableDaysToDate(DateTime.Today, equipmentSummary.ExternalLeadTimeDays, allEquipmentsCapacityOverMaxDate, currentGroupEquipments),
                NextAvailableDate = GetMaxNextAvailableDate(equipmentWiseNextAvailableDate, currentGroupEquipments),
                ActualLeadTimeDays = GetMaxLeadTimeDays(equipmentWiseNextAvailableDate, currentGroupEquipments),
            };
        }

        private static int GetEquipmentDownTime(List<PlannedDowntimeHours> plannedDowntimes, List<string> equipments)
        {
            return (int)Math.Ceiling(plannedDowntimes.Where(x => equipments.Contains(x.EquipmentId))
                .Sum(x => x.PlannedDowntime));
        }

        private static float GetTotalCapacity(List<DailyEquipmentCapacity> equipmentCapacityForDateRange, List<string> equipments)
        {
            return equipmentCapacityForDateRange.Where(x => equipments.Contains(x.EquipmentId)).Sum(x => x.ActualCapacityHours);
        }

        private static int GetTotalUnplannedAllowance(List<DailyEquipmentCapacity> equipmentCapacityForDateRange, List<string> equipments)
        {
            return (int)Math.Ceiling(equipmentCapacityForDateRange.Where(x => equipments.Contains(x.EquipmentId)).Sum(x => x.UnplannedAllowanceHours));
        }
        private static float GetAvailableCapacity(List<DailyEquipmentCapacity> equipmentCapacityForDateRange, List<string> equipments, float totalDemand)
        {
            return equipmentCapacityForDateRange.Where(x => equipments.Contains(x.EquipmentId)).Sum(x => x.ActualCapacityHours)
                                                                         - totalDemand;
        }
        private static DateTime? GetMaxNextAvailableDate(List<EquipmentWiseNextAvailableDate> equipmentWiseNextAvailableDate, List<string> equipments)
        {
            if (equipmentWiseNextAvailableDate == null || equipments == null)
                return null;

            return equipmentWiseNextAvailableDate.Any(ewnd => equipments.Contains(ewnd.EquipmentId)) ?
                 equipmentWiseNextAvailableDate.Where(ewnd => equipments.Contains(ewnd.EquipmentId)).Max(x => x.NextAvailableDate) : null;
        }
        private static int GetMaxLeadTimeDays(List<EquipmentWiseNextAvailableDate> equipmentWiseNextAvailableDate, List<string> equipments)
        {

            if (equipmentWiseNextAvailableDate == null || equipments == null)
                return 0;

            return equipmentWiseNextAvailableDate.Any(ewnd => equipments.Contains(ewnd.EquipmentId)) ?
                 equipmentWiseNextAvailableDate.Where(ewnd => equipments.Contains(ewnd.EquipmentId)).Max(x => x.LeadTimeDays) : 0;
        }

        private static List<CapacitySummaryDto> OmmitDuplicateEquipmentsFromTicketsDemandData(List<CapacitySummaryDto> demandForSelectedDateRange)
        {
            return demandForSelectedDateRange.GroupBy(x => x.EquipmentId).Select(x => new CapacitySummaryDto
            {
                FacilityId = x.FirstOrDefault()?.FacilityId,
                FacilityName = x.FirstOrDefault()?.FacilityName,
                ValueStreamId = x.FirstOrDefault()?.ValueStreamId,
                ValueStreamName = x.FirstOrDefault()?.ValueStreamName,
                WorkcenterId = x.FirstOrDefault()?.WorkcenterId,
                WorkcenterName = x.FirstOrDefault()?.WorkcenterName,
                EquipmentId = x.FirstOrDefault()?.EquipmentId,
                EquipmentName = x.FirstOrDefault()?.EquipmentName,
                TotalTickets = x.FirstOrDefault().TotalTickets,
                TicketDemand = x.FirstOrDefault().TicketDemand,
                UnplannedAllowance = (int)x.FirstOrDefault()?.UnplannedAllowance,
                ExternalLeadTimeDays = (int)x.FirstOrDefault()?.ExternalLeadTimeDays,
                Tickets = x.FirstOrDefault().Tickets,
            }).ToList();
        }
        private static List<TicketsDemand> DedupeTicketDemandData(List<TicketsDemand> demandForSelectedDateRange)
        {
            return demandForSelectedDateRange.GroupBy(x => new { x.TicketId, x.EquipmentId })
                 .Select(x => x.First()).ToList();
        }

        private static LeadTimeManagerKpi CalculateKpiValues(List<TicketsDemand> ticketsDemand,
            List<DailyEquipmentCapacity> allEquipmentsCapacity,
            List<FacilityHolidaysCount> facilityHolidaysCounts,
            DashboardFilter filter,
            DateTime tenantLocalDateTime,
            List<ReservationEventDto> reservationEvents,
            List<EquipmentDetails> equipmentDetails,
            List<FacilityWiseHolidays> facilityWiseHolidays)
        {
            ticketsDemand = DedupeTicketDemandData(ticketsDemand);
            var demandForSelectedDateRange = ticketsDemand
                .Where(x => x.ShipByDate <= filter.EndDate && (filter.Tickets.Count == 0 || filter.Tickets.Contains(x.SourceTicketId))).ToList();
            var equipments = demandForSelectedDateRange.Select(x => x.EquipmentId).Distinct().ToList();
            var equipmentsWithFacility = demandForSelectedDateRange.GroupBy(x => x.EquipmentId)
                .Select(g => new EquipmentDto { Id = g.Key, FacilityId = g.First().FacilityId }).ToList();
            var currentEquipmentsCapacity = allEquipmentsCapacity.Where(x => equipments.Contains(x.EquipmentId)).ToList();
            var equipmentCapacityForDateRange = currentEquipmentsCapacity.Where(x => x.TheDate >= filter.StartDate && x.TheDate <= filter.EndDate).ToList();

            var filteredEquipmentDetails = ApplyDashboardFilter(filter, equipmentDetails);
            var reservationEventsForDateRange = reservationEvents.Where(x => x.Date >= filter.StartDate && x.Date <= filter.EndDate).ToList();
            var workcentersApplicable = filteredEquipmentDetails.Select(x => x.WorkcenterId).ToList();
            var filteredReservationEvents = reservationEventsForDateRange.Where(x => workcentersApplicable.Contains(x.WorkcenterId)).ToList();

            var totalTickets = demandForSelectedDateRange.Select(x => x.TicketId).Distinct().Count();
            var reservedDemand = filteredReservationEvents.Any() ? (float)filteredReservationEvents.Sum(x => x.NetReservedDemand) : 0;
            var totalDemandHours = demandForSelectedDateRange.Select(x => x.EstTotalHours).Sum() + reservedDemand;
            var totalCapacityHours = equipmentCapacityForDateRange.Count > 0 ? equipmentCapacityForDateRange.Sum(x => x.ActualCapacityHours) : 0;
            var availableCapacity = totalCapacityHours - totalDemandHours;

            filteredEquipmentDetails = CalculateEquipmentsExternalNextAvailableDate(filteredEquipmentDetails, currentEquipmentsCapacity);
            var externalLeadTimeDays = filteredEquipmentDetails.Count > 0 ? filteredEquipmentDetails.Max(x => x.MinLeadTime) : 0;
            var externalNextAvailableDate = filteredEquipmentDetails.Count > 0 ? filteredEquipmentDetails.Max(x => x.ExternalNextAvailableDate) : null;

            var equipmentDowntimes = CalculateDayWiseDowntimes(equipmentCapacityForDateRange);

            var plannedDowntimes = CalculatePlannedDowntimeHours(equipmentsWithFacility, equipmentDowntimes, facilityHolidaysCounts);
            var totalDowntimes = plannedDowntimes.Sum(x => x.PlannedDowntime);


            var nextAvailableDateInfo = ticketsDemand.Count > 0 ? GetNextAvailableDateInfo(ticketsDemand, currentEquipmentsCapacity, tenantLocalDateTime, reservationEvents) : new();

            var nextAvailableDate = new DateTime?();
            if (filter.Equipments != null && filter.Equipments.Count > 0)
                nextAvailableDate = nextAvailableDateInfo.EquipmentWiseNextAvailableDate.Max(x => x.NextAvailableDate);
            else
                nextAvailableDate = nextAvailableDateInfo.WorkcenterWiseNextAvailableDate.Max(x => x.NextAvailableDate);

            var leadTimeDays = nextAvailableDate.HasValue ? GetAvailableBusinessDays(DateTime.Today, nextAvailableDate, currentEquipmentsCapacity, equipments) : 0;

            return new LeadTimeManagerKpi()
            {
                TotalTickets = totalTickets,
                AvailableCapacity = availableCapacity,
                DowntimeHours = (int)Math.Ceiling(totalDowntimes),
                ExternalLeadTimeDays = externalLeadTimeDays,
                Reservations = reservedDemand,
                ActualLeadTimeDays = leadTimeDays,
                NextAvailableDate = nextAvailableDate,
                ExternalNextAvailableDate = externalNextAvailableDate,
            };
        }

        private static List<EquipmentDowntimeDto> CalculateDayWiseDowntimes(List<DailyEquipmentCapacity> equipmentCapacityForDateRange)
        {
            return equipmentCapacityForDateRange.GroupBy(x => x.EquipmentId)
                    .Select(x => new EquipmentDowntimeDto
                    {
                        EquipmentId = x.Key,
                        DownTimeHours = x.Sum(x => x.DowntimeHours),
                        FacilityId = x.First().FacilityId
                    }).ToList();
        }

        private static List<EquipmentDetails> CalculateEquipmentsExternalNextAvailableDate(List<EquipmentDetails> equipemntDetails, List<DailyEquipmentCapacity> dailyEquipmentCapacities)
        {
            foreach (var item in equipemntDetails)
            {
                //var holidayDates = facilityWiseHolidays.Any(x => x.FacilityId == item.FacilityId) ?
                //                            facilityWiseHolidays.Where(x => x.FacilityId == item.FacilityId).First().Holidays : new List<DateTime>();
                item.ExternalNextAvailableDate = AddAvailableDaysToDate(DateTime.Today, item.MinLeadTime, dailyEquipmentCapacities, new List<string> { item.EquipmentId });
            }
            return equipemntDetails;

        }

        private static NextAvailableDateInfo GetNextAvailableDateInfo(List<TicketsDemand> ticketsDemandData,
            List<DailyEquipmentCapacity> currentEquipmentsCapacity,
            DateTime tenantLocalDateTime,
            List<ReservationEventDto> reservationEvents)
        {
            using (Tracer.Benchmark("leadTime-provider-get-next-available-date"))
            {
                ticketsDemandData = DedupeTicketDemandData(ticketsDemandData);
                using (Tracer.Benchmark("map-daily-demand-against-capacity"))
                {
                    var ticketDemandByDateAndEquipment = ticketsDemandData.Where(x => x.ShipByDate.HasValue)
                    .GroupBy(x => new { ShipByDate = x.ShipByDate.Value.Date, x.EquipmentId })
                    .ToDictionary(g => g.Key, g => g.Sum(x => x.EstTotalHours));

                    Parallel.ForEach(currentEquipmentsCapacity, ec =>
                    {
                        if (ticketDemandByDateAndEquipment.TryGetValue(new { ShipByDate = ec.TheDate.Date, ec.EquipmentId }, out var totalHours))
                            ec.DemandHours = totalHours + CalculateNetReservedDemand(reservationEvents, ec.TheDate, ec.WorkcenterId, ec.EquipmentId);
                    });
                }

                var equipmentWiseLateTasksHours = ticketsDemandData.Where(x => x.ShipByDate == null || x.ShipByDate < tenantLocalDateTime.Date)
                                .GroupBy(x => x.EquipmentId).ToDictionary(g => g.Key, g => g.Sum(x => x.EstTotalHours));

                var workcenterWiseLateTaskHours = ticketsDemandData.Where(x => x.ShipByDate == null || x.ShipByDate < tenantLocalDateTime.Date)
                                .GroupBy(x => x.WorkcenterId).ToDictionary(g => g.Key, g => g.Sum(x => x.EstTotalHours));

                var equipmentWiseNextAvailableDate = CalculateEqupimentWiseNextAvailableDate(currentEquipmentsCapacity, equipmentWiseLateTasksHours, tenantLocalDateTime);
                var workcenterWiseNextAvailableDate = CalculateWorkceterWiseNextAvailableDate(currentEquipmentsCapacity, workcenterWiseLateTaskHours, tenantLocalDateTime, reservationEvents);
                return new NextAvailableDateInfo
                {
                    EquipmentWiseNextAvailableDate = equipmentWiseNextAvailableDate,
                    WorkcenterWiseNextAvailableDate = workcenterWiseNextAvailableDate
                };

            }

        }

        private static List<WorkcenterWiseNextAvailableDate> CalculateWorkceterWiseNextAvailableDate(List<DailyEquipmentCapacity> currentEquipmentsCapacity,
           Dictionary<string, float> workcenterWiseLateHours, DateTime tenantLocalTime, List<ReservationEventDto> reservationEvents)
        {
            var workcenterWiseNextAvailableDate = currentEquipmentsCapacity.GroupBy(wc => wc.WorkcenterId)
                    .Select(wc => new WorkcenterWiseNextAvailableDate
                    {
                        WorkcenterId = wc.Key,
                        AvailabilityThreshold = wc.Max(x => x.AvailabilityThreshold),
                        equipments = wc.Select(x => x.EquipmentId).ToList(),
                        TicketTaskCumulativeData = CalculateRunningValues(wc.GroupBy(x => x.TheDate).Select(x => new TicketTaskCumulativeData
                        {
                            TheDate = x.Key,
                            CapacityHours = x.Sum(a => (a.ActualCapacityHours - a.DowntimeHours)),
                            DemandHours = x.Sum(x => x.DemandHours) + CalculateNetReservedDemand(reservationEvents, x.Key, wc.Key, null),
                        }).OrderBy(x => x.TheDate).ToList(), workcenterWiseLateHours.GetValueOrDefault(wc.Key))
                    }).ToList();

            using (Tracer.Benchmark("calculate-availability-and-next-available-date"))
                workcenterWiseNextAvailableDate.ForEach(x =>
                {
                    x.TicketTaskCumulativeData.ForEach(tt => tt.IsAvailable = CalculateEquipmentAvailabilityOnDate(tt, x.AvailabilityThreshold));
                    var nextAvailableDate = CalcuateEquipmentsNextAvailableDate(x.TicketTaskCumulativeData, currentEquipmentsCapacity, x.equipments);
                    x.NextAvailableDate = nextAvailableDate.NextAvailableDate;
                    x.LeadTimeDays = nextAvailableDate.LeadTimeDays;
                });
            return workcenterWiseNextAvailableDate;
        }

        private static List<EquipmentWiseNextAvailableDate> CalculateEqupimentWiseNextAvailableDate(List<DailyEquipmentCapacity> currentEquipmentsCapacity,
            Dictionary<string, float> equipmentWiseLateHours, DateTime tenantLocalTime)
        {
            var equipmentWiseNextAvailableDate = currentEquipmentsCapacity.GroupBy(x => x.EquipmentId)
                    .Select(x => new EquipmentWiseNextAvailableDate
                    {
                        EquipmentId = x.Key,
                        AvailabilityThreshold = x.First().AvailabilityThreshold,
                        TicketTaskCumulativeData = CalculateRunningValues(x.Select(x => new TicketTaskCumulativeData
                        {
                            TheDate = x.TheDate,
                            CapacityHours = x.ActualCapacityHours - x.DowntimeHours,
                            DemandHours = x.DemandHours,
                        }).OrderBy(x => x.TheDate).ToList(), equipmentWiseLateHours.GetValueOrDefault(x.Key))
                    }).ToList();

            using (Tracer.Benchmark("calculate-availability-and-next-available-date"))
                equipmentWiseNextAvailableDate.ForEach(x =>
                {
                    x.TicketTaskCumulativeData.ForEach(tt => tt.IsAvailable = CalculateEquipmentAvailabilityOnDate(tt, x.AvailabilityThreshold));
                    var nextAvailableDate = CalcuateEquipmentsNextAvailableDate(x.TicketTaskCumulativeData, currentEquipmentsCapacity, new List<string> { x.EquipmentId });
                    x.NextAvailableDate = nextAvailableDate.NextAvailableDate;
                    x.LeadTimeDays = nextAvailableDate.LeadTimeDays;
                });
            return equipmentWiseNextAvailableDate;
        }

        private static float CalculateNetReservedDemand(List<ReservationEventDto> reservationEvents, DateTime theDate, string workcenterId, string equipmentId)
        {
            if (equipmentId != null)
                return reservationEvents.Where(x => x.Date.Date == theDate.Date && x.EquipmentId == equipmentId).Any()
                    ? (float)reservationEvents.Where(x => x.Date.Date == theDate.Date && x.EquipmentId == equipmentId).Sum(x => x.NetReservedDemand) : 0;
            else
                return (float)(reservationEvents.Any(re => re.WorkcenterId == workcenterId && re.Date.Date == theDate.Date && re.EquipmentId == null)
                                                ? reservationEvents.Where(re => re.WorkcenterId == workcenterId).Sum(x => x.NetReservedDemand) : 0);

        }

        private static bool CalculateEquipmentAvailabilityOnDate(TicketTaskCumulativeData data, int availabilityThreshold)
        {
            return (data.RunningCapacity >= data.RunningDemand + availabilityThreshold);
        }

        private static NextAvailableDateDto CalcuateEquipmentsNextAvailableDate(List<TicketTaskCumulativeData> cumulativeData, List<DailyEquipmentCapacity> dailyEquipmentCapacities, List<string> equipments)
        {
            var firstDateWithAllAvailable = cumulativeData.FirstOrDefault(data => cumulativeData.SkipWhile(d => d.TheDate != data.TheDate).All(d => d.IsAvailable));
            return new NextAvailableDateDto
            {
                NextAvailableDate = firstDateWithAllAvailable?.TheDate,
                LeadTimeDays = GetAvailableBusinessDays(DateTime.Today, firstDateWithAllAvailable?.TheDate, dailyEquipmentCapacities, equipments)
            };
        }
        private static List<TicketTaskCumulativeData> CalculateRunningValues(List<TicketTaskCumulativeData> dataList, float lateHours)
        {
            float runningDemand = lateHours;
            float runningCapacity = 0;

            foreach (var data in dataList)
            {
                runningDemand += data.DemandHours;
                runningCapacity += data.CapacityHours;

                data.RunningDemand = runningDemand;
                data.RunningCapacity = runningCapacity;
            }
            return dataList;
        }
        private static List<LeadTimeDashboardFilter> ToLeadTimeReportFilterData(List<EquipmentTicket> equipmentTickets, List<FilterData> equipmentFilterData)
        {
            return equipmentFilterData.Select(t => ToLeadTimeReportFilter(equipmentTickets, t)).ToList();
        }

        private static LeadTimeDashboardFilter ToLeadTimeReportFilter(List<EquipmentTicket> equipmentTickets, FilterData filter)
        {
            return new LeadTimeDashboardFilter
            {
                EquipmentId = filter.EquipmentId,
                EquipmentName = filter.EquipmentName,
                FacilityId = filter.FacilityId,
                FacilityName = filter.FacilityName,
                WorkcenterId = filter.WorkcenterId,
                WorkcenterName = filter.WorkcenterName,
                ValueStreams = filter.ValueStreams,
                Tickets = GetEquipmentTickets(filter.EquipmentId, equipmentTickets)
            };
        }

        private static List<TicketFilter> GetEquipmentTickets(string equipmentId, List<EquipmentTicket> equipmentTickets)
        {
            var thisEquipmentTickets = equipmentTickets.FirstOrDefault(t => t.EquipmentId == equipmentId);
            return thisEquipmentTickets?.Tickets ?? new List<TicketFilter>();
        }

        private static int GetAvailableBusinessDays(DateTime startDate, DateTime? endDate, List<DailyEquipmentCapacity> dailyCapacity, List<string> equipments)
        {
            int businessDays = 0;
            DateTime currentDate = startDate.AddDays(1);
            if (equipments.Count == 0 || !dailyCapacity.Any(x => equipments.Contains(x.EquipmentId)))
                return 0;
            var currentEquipemtsCapacity = dailyCapacity.Where(x => equipments.Contains(x.EquipmentId)).ToList();
            while (currentDate <= endDate)
            {
                var currentDayCapacity = currentEquipemtsCapacity.Where(x => x.TheDate.Date == currentDate.Date)
                                                  .Select(x => (x.TotalCapacityHours - x.DowntimeHours))
                                                  .DefaultIfEmpty(0).Sum();

                if (currentDayCapacity > 0)
                    businessDays++;

                currentDate = currentDate.AddDays(1);
            }
            return businessDays;
        }

        private static DateTime? AddAvailableDaysToDate(DateTime startDate, int externalLeadTimedays, List<DailyEquipmentCapacity> dailyCapacity, List<string> equipments)
        {
            DateTime currentDate = startDate;
            var days = externalLeadTimedays;
            if (equipments.Count == 0 || !dailyCapacity.Any(x => equipments.Contains(x.EquipmentId)))
                return null;
            var currentEquipemtsCapacity = dailyCapacity.Where(x => equipments.Contains(x.EquipmentId)).ToList();

            while (days > 0)
            {
                currentDate = currentDate.AddDays(1);
                var currentDayCapacity = currentEquipemtsCapacity.Where(x => x.TheDate.Date == currentDate.Date)
                                                  .Select(x => (x.TotalCapacityHours - x.DowntimeHours))
                                                  .DefaultIfEmpty(0).Sum();

                if (currentDayCapacity > 0)
                {
                    days--;
                }
            }
            return currentDate;
        }
        private static List<PlannedDowntimeHours> CalculatePlannedDowntimeHours(List<EquipmentDto> equipments, List<EquipmentDowntimeDto> equipmentDowntimes, List<FacilityHolidaysCount> facilityHolidaysCount)
        {
            var result = equipments.Select(x => new PlannedDowntimeHours
            {
                EquipmentId = x.Id,
                FacilityId = x.FacilityId,
                PlannedDowntime = equipmentDowntimes.Any(dt => dt.EquipmentId == x.Id) ?
                                    equipmentDowntimes.Where(dt => dt.EquipmentId == x.Id).Sum(x => x.DownTimeHours) : 0,
            }).ToList();

            if (facilityHolidaysCount.Count > 0)
                Parallel.ForEach(result, x =>
                {
                    if (facilityHolidaysCount.Any(f => f.FacilityId == x.FacilityId))
                        x.PlannedDowntime += facilityHolidaysCount.FirstOrDefault(f => f.FacilityId == x.FacilityId).TotalHolidays * 24;
                });
            return result;
        }

        private static List<EquipmentDetails> flattenEquipmentDetails(List<EquipemntDetailsData> equipmentDetailsdata)
        {
            var equipmentDetailsList = new List<EquipmentDetails>();

            foreach (var data in equipmentDetailsdata)
            {
                var valueStreams = data.ValueStreams.Count == 0 ? new List<ValueStreamDto>() { new ValueStreamDto() } : data.ValueStreams;
                foreach (var valueStream in valueStreams)
                {
                    equipmentDetailsList.Add(new EquipmentDetails
                    {
                        FacilityId = data.FacilityId,
                        FacilityName = data.FacilityName,
                        ValueStreamId = valueStream.Id,
                        ValueStreamName = valueStream.Name,
                        WorkcenterId = data.WorkcenterId,
                        WorkcenterName = data.WorkcenterName,
                        EquipmentId = data.EquipmentId,
                        EquipmentName = data.EquipmentName,
                        MinLeadTime = data.MinLeadTime,
                    });
                }
            }
            return equipmentDetailsList;
        }

        private static List<CapacitySummaryDto> MapTicketDemandToEquipmentDetails(List<EquipmentDetails> equipmentDetails, List<TicketsDemand> ticketdemand, DashboardFilter filter)
        {
            var demandData = ticketdemand.GroupBy(x => new { x.TicketId, x.EquipmentId, x.ValueStreamId }).Select(x => x.First()).ToList();
            var capacitySummary = new List<CapacitySummaryDto>();

            using (Tracer.Benchmark("leadTimeProvider-map-ticket-damend-to-equipment-daily-capacity"))
                foreach (var equipment in equipmentDetails)
                {
                    capacitySummary.Add(new CapacitySummaryDto()
                    {
                        FacilityId = equipment.FacilityId,
                        FacilityName = equipment.FacilityName,
                        ValueStreamId = equipment.ValueStreamId,
                        ValueStreamName = equipment.ValueStreamName,
                        WorkcenterId = equipment.WorkcenterId,
                        WorkcenterName = equipment.WorkcenterName,
                        EquipmentId = equipment.EquipmentId,
                        EquipmentName = equipment.EquipmentName,
                        TotalTickets = demandData.Where(x => x.EquipmentId == equipment.EquipmentId).Select(x => x.TicketId).Distinct().Count(),
                        Tickets = demandData.Any(x => x.EquipmentId == equipment.EquipmentId) ?
                                        demandData.Where(x => x.EquipmentId == equipment.EquipmentId)
                                        .Select(x => x.TicketId).Distinct().ToList() : new List<string>(),
                        TicketDemand = demandData.Any(x => x.EquipmentId == equipment.EquipmentId) ?
                                            demandData.Where(x => x.EquipmentId == equipment.EquipmentId)
                                            .GroupBy(x => new { x.EquipmentId, x.ValueStreamId }).First()
                                            .Sum(x => x.EstTotalHours) : 0,
                        UnplannedAllowance = demandData.Any(x => x.EquipmentId == equipment.EquipmentId) ?
                                                demandData.FirstOrDefault(x => x.EquipmentId == equipment.EquipmentId).UnplannedAllowance : 0,
                        ExternalLeadTimeDays = equipment.MinLeadTime,
                    });
                }

            var result = ApplyDashboardFilter(filter, capacitySummary);
            return result;
        }

        private static List<CapacitySummaryDto> ApplyDashboardFilter(DashboardFilter filter, List<CapacitySummaryDto> capacitySummary)
        {
            using (Tracer.Benchmark("leadTimeProvider-apply-dashboard-filter"))
                return (from cs in capacitySummary
                        where (filter.Facilities.Count == 0 || filter.Facilities.Contains(cs.FacilityId))
                                          && (filter.ValueStreams.Count == 0 || filter.ValueStreams.Contains(cs.ValueStreamId))
                                          && (filter.Workcenters.Count == 0 || filter.Workcenters.Contains(cs.WorkcenterId))
                                          && (filter.Equipments.Count == 0 || filter.Equipments.Contains(cs.EquipmentId))
                        select cs).ToList();
        }

        private static List<EquipmentDetails> ApplyDashboardFilter(DashboardFilter filter, List<EquipmentDetails> equipmentDetails)
        {
            using (Tracer.Benchmark("leadTimeProvider-apply-dashboard-filter"))
                return (from cs in equipmentDetails
                        where (filter.Facilities.Count == 0 || filter.Facilities.Contains(cs.FacilityId))
                                          && (filter.ValueStreams.Count == 0 || filter.ValueStreams.Contains(cs.ValueStreamId))
                                          && (filter.Workcenters.Count == 0 || filter.Workcenters.Contains(cs.WorkcenterId))
                                          && (filter.Equipments.Count == 0 || filter.Equipments.Contains(cs.EquipmentId))
                        select cs).ToList();
        }
    }
}

using Batched.Common;
using Batched.Reporting.Contracts;
using contracts = Batched.Reporting.Contracts.Models;
using Microsoft.EntityFrameworkCore;
using Commons = Batched.Common.Data.Tenants.Sql.Models;
using Batched.Reporting.Contracts.Models.LeadTimeManager;
using Batched.Reporting.Contracts.Models.StagingRequirement;

namespace Batched.Reporting.Data
{
    public class EquipmentRepository : IEquipmentRepository
    {
        private readonly UnitOfWorkFactory _unitOfWorkFactory;

        public EquipmentRepository(UnitOfWorkFactory unitOfWorkFactory)
        {
            _unitOfWorkFactory = unitOfWorkFactory;
        }

        public async Task<List<EquipmentValueStreams>> GetEquipmentValueStreams()
        {
            using (var unitOfWork = _unitOfWorkFactory.BeginUnitOfWork(DBContextLevel.Tenant, DbAccessMode.read))
            {
                return await unitOfWork.Repository<Commons.EquipmentValueStream>()
                    .GetQueryable().GroupBy(x => x.EquipmentId)
                    .Select(x => new EquipmentValueStreams { EquipmentId = x.Key, ValueStreams = x.Select(x => x.ValueStreamId).ToList() })
                    .ToListAsync();
            }
        }

        public async Task<List<FilterData>> GetFilterDataAsync(DashboardFilter filter, CancellationToken cancellationToken)
        {
            using (Tracer.Benchmark("equipment-repo-filter-data"))
            using (var unitOfWork = _unitOfWorkFactory.BeginUnitOfWork(DBContextLevel.Tenant, DbAccessMode.read))
            {
                var valueStreams = unitOfWork.Repository<Commons.ValueStream>().GetQueryable();
                var equipmentValueStreams = unitOfWork.Repository<Commons.EquipmentValueStream>().GetQueryable();
                var equipments = unitOfWork.Repository<Commons.EquipmentMaster>().GetQueryable();
                var facilities = unitOfWork.Repository<Commons.Facility>().GetQueryable();


                var valueStreamsQuery = from evs in equipmentValueStreams
                                        join vs in valueStreams on evs.ValueStreamId equals vs.Id into vsGroup
                                        from vs in vsGroup.DefaultIfEmpty()
                                        select new { evs.EquipmentId, ValueStream = vs };


                var filterData = await (from em in equipments
                                        where em.IsEnabled
                                        && (em.AvailableForPlanning || em.AvailableForScheduling)
                                        && (filter.Facilities.Count == 0 || filter.Facilities.Contains(em.FacilityId))
                                        join facility in facilities on em.FacilityId equals facility.Id
                                        join vsData in valueStreamsQuery on em.Id equals vsData.EquipmentId into vsDataGroup
                                        from vsd in vsDataGroup.DefaultIfEmpty()
                                        group vsd by new { EquipmentId = em.Id, em.Name, em.FacilityId, FacilityName = facility.Name, em.WorkcenterTypeId, em.WorkCenterName } into g
                                        select new FilterData
                                        {
                                            FacilityId = g.Key.FacilityId,
                                            FacilityName = g.Key.FacilityName,
                                            WorkcenterId = g.Key.WorkcenterTypeId,
                                            WorkcenterName = g.Key.WorkCenterName,
                                            EquipmentId = g.Key.EquipmentId,
                                            EquipmentName = g.Key.Name,
                                            ValueStreams = g.Select(vs => new ValueStreamDto
                                            {
                                                Id = vs.ValueStream.Id,
                                                Name = vs.ValueStream.Name
                                            }).Where(vs => vs.Name != null).ToList()
                                        }).ToListAsync(cancellationToken);

                return filterData;
            }
        }

        public async Task<List<EquipemntDetailsData>> GetAllEquipmentsDataAsync(DashboardFilter filter, CancellationToken cancellationToken)
        {
            using (Tracer.Benchmark("equipment-repo-get-equipments-data"))
            using (var unitOfWork = _unitOfWorkFactory.BeginUnitOfWork(DBContextLevel.Tenant, DbAccessMode.read))
            {
                var valueStreams = unitOfWork.Repository<Commons.ValueStream>().GetQueryable();
                var equipmentValueStreams = unitOfWork.Repository<Commons.EquipmentValueStream>().GetQueryable();
                var equipments = unitOfWork.Repository<Commons.EquipmentMaster>().GetQueryable();
                var facilities = unitOfWork.Repository<Commons.Facility>().GetQueryable();
                var capacityConfiguration = unitOfWork.Repository<Commons.CapacityConfiguration>().GetQueryable();


                var valueStreamsQuery = from evs in equipmentValueStreams
                                        join vs in valueStreams on evs.ValueStreamId equals vs.Id into vsGroup
                                        from vs in vsGroup.DefaultIfEmpty()
                                        select new { evs.EquipmentId, ValueStream = vs };


                var equipmentsData = from em in equipments
                                        where em.IsEnabled
                                        && (em.AvailableForPlanning || em.AvailableForScheduling)
                                        && (filter.Facilities.Count == 0 || filter.Facilities.Contains(em.FacilityId))
                                        join facility in facilities on em.FacilityId equals facility.Id
                                        join vsData in valueStreamsQuery on em.Id equals vsData.EquipmentId into vsDataGroup
                                        from vsd in vsDataGroup.DefaultIfEmpty()
                                        join ccg in capacityConfiguration on em.Id equals ccg.EquipmentId into ccGroup
                                        from cc in ccGroup.DefaultIfEmpty()
                                        group vsd by new { EquipmentId = em.Id, em.Name, em.FacilityId, FacilityName = facility.Name, em.WorkcenterTypeId, em.WorkCenterName } into g
                                        select new EquipemntDetailsData
                                        {
                                            FacilityId = g.Key.FacilityId,
                                            FacilityName = g.Key.FacilityName,
                                            WorkcenterId = g.Key.WorkcenterTypeId,
                                            WorkcenterName = g.Key.WorkCenterName,
                                            EquipmentId = g.Key.EquipmentId,
                                            EquipmentName = g.Key.Name,
                                            ValueStreams = g.Select(vs => new ValueStreamDto
                                            {
                                                Id = vs.ValueStream.Id,
                                                Name = vs.ValueStream.Name
                                            }).Where(vs => vs.Name != null).ToList(),
                                        };

                var result = await (from e in equipmentsData
                                    join ccg in capacityConfiguration on e.EquipmentId equals ccg.EquipmentId into ccGroup
                                    from cc in ccGroup.DefaultIfEmpty()
                                    select new EquipemntDetailsData
                                    {
                                        FacilityId = e.FacilityId,
                                        FacilityName = e.FacilityName,
                                        WorkcenterId = e.WorkcenterId,
                                        WorkcenterName = e.WorkcenterName,
                                        EquipmentId = e.EquipmentId,
                                        EquipmentName = e.EquipmentName,
                                        ValueStreams = e.ValueStreams,
                                        MinLeadTime = cc!= null ? cc.MinLeadTime : 0,
                                    }).ToListAsync(cancellationToken);

                return result;
            }
        }

        public async Task<List<EquipmentTicket>> GetEquipmentWiseTicketsAysnc(DashboardFilter filter, CancellationToken cancellationToken)
        {
            using (Tracer.Benchmark("equipment-repo-get-tickets"))
            using (var unitOfWork = _unitOfWorkFactory.BeginUnitOfWork(DBContextLevel.Tenant, DbAccessMode.read))
            {

                var equipments = unitOfWork.Repository<Commons.EquipmentMaster>().GetQueryable();
                var ticketMasters = unitOfWork.Repository<Commons.TicketMaster>().GetQueryable();
                var ticketShippings = unitOfWork.Repository<Commons.TicketShipping>().GetQueryable();
                var ticketTasks = unitOfWork.Repository<Commons.TicketTask>().GetQueryable();
                var scheduleReports = unitOfWork.Repository<Commons.ScheduleReport>().GetQueryable();

                var equipmentWiseTickets = await (from tm in ticketMasters
                                                  join ts in ticketShippings on tm.Id equals ts.TicketId
                                                  join tt in ticketTasks on tm.Id equals tt.TicketId into ttGroup
                                                  from tt in ttGroup.DefaultIfEmpty()
                                                  join em in equipments on tt.OriginalEquipmentId equals em.Id into emGroup
                                                  from em in emGroup.DefaultIfEmpty()
                                                  join sr in scheduleReports on new { tm.SourceTicketId, tt.TaskName } equals new { sr.SourceTicketId, sr.TaskName } into srGroup
                                                  from scheduledTicket in srGroup.DefaultIfEmpty()
                                                  where (ts.ShipByDateTime == null || ts.ShipByDateTime <= filter.EndDate) &&
                                                        (tt == null || !tt.IsComplete)
                                                  group new { tm.Id, tm.SourceTicketId, scheduledTicket } 
                                                  by new { Id = scheduledTicket != null ? scheduledTicket.EquipmentId : em.Id } into g
                                                  select new EquipmentTicket
                                                  {
                                                      EquipmentId = g.Key.Id,
                                                      Tickets = g.Select(x => new TicketFilter
                                                      {
                                                          SourceTicketId = x.SourceTicketId,
                                                          IsScheduled = x.scheduledTicket != null
                                                      }).ToList()
                                                  }).ToListAsync(cancellationToken);

                return equipmentWiseTickets;
            }
        }

        public async Task<List<contracts.LeadTimeManager.DailyEquipmentCapacity>> GetEquipmentsCapacityAsync(DateTime startDate, DateTime endDate, CancellationToken token)
        {
            using (Tracer.Benchmark("repo-equipments-daily-capacity-details"))
            using (var unitOfWork = _unitOfWorkFactory.BeginUnitOfWork(DBContextLevel.Tenant, DbAccessMode.read))
            {
                var equipments = unitOfWork.Repository<Commons.EquipmentMaster>().GetQueryable();
                var capacityConfiguration = unitOfWork.Repository<Commons.CapacityConfiguration>().GetQueryable();
                var shiftCalendarSchedule = unitOfWork.Repository<Commons.ShiftCalendarScheduleV2>().GetQueryable();
                var equipmentScheduleMapping = unitOfWork.Repository<Commons.EquipmentScheduleMapping>().GetQueryable();
                var shiftCalendar = unitOfWork.Repository<Commons.ShiftCalendarV2>().GetQueryable();
                var shiftCalendarDates = unitOfWork.Repository<Commons.ShiftCalendarDatesV2>().GetQueryable();
                var shiftCalendarPattern = unitOfWork.Repository<Commons.ShiftCalendarPatternV2>().GetQueryable();
                var calendar = unitOfWork.Repository<Commons.Calendar>().GetQueryable();
                var shiftOverrides = unitOfWork.Repository<Commons.ShiftOverride>().GetQueryable();
                var shiftOverrideTimes = unitOfWork.Repository<Commons.ShiftOverrideTime>().GetQueryable();
                var facilityHoliday = unitOfWork.Repository<Commons.FacilityHoliday>().GetQueryable().Include(x => x.Holiday);
                var equipmentDowntimes = unitOfWork.Repository<Commons.EquipmentDowntime>().GetQueryable();

                var result = await (from c in calendar
                                    from scd in shiftCalendarDates.Where(scd => scd.StartDate <= c.TheDateTime && c.TheDateTime <= scd.EndDate)
                                    join scg in shiftCalendar on scd.ShiftCalendarId equals scg.Id into scGroup
                                    from sc in scGroup.DefaultIfEmpty()
                                    join scpg in shiftCalendarPattern on new { sc.Id, Week = c.TheDayName } equals new { Id = scpg.ShiftCalendarId, Week = scpg.DayOfWeek } into scpGroup
                                    from scp in scpGroup.DefaultIfEmpty()
                                    join ssg in shiftCalendarSchedule on sc.ShiftCalendarScheduleId equals ssg.Id into ssGroup
                                    from ss in ssGroup.DefaultIfEmpty()
                                    join esm in equipmentScheduleMapping on ss.Id equals esm.ShiftCalendarScheduleId
                                    join em in equipments on esm.EquipmentId equals em.Id
                                    join cc in capacityConfiguration on em.Id equals cc.EquipmentId
                                    join sog in shiftOverrides on c.TheDateTime equals sog.ExceptionDate into soGroup
                                    from so in soGroup.DefaultIfEmpty()
                                    join sotg in shiftOverrideTimes on so.Id equals sotg.ShiftOverrideId into sotGroup
                                    from sot in sotGroup.DefaultIfEmpty()
                                    from ed in equipmentDowntimes.Where(x => x.EquipmentId == em.Id && c.TheDateTime.Value.Date >= x.StartsOn.Date && c.TheDateTime.Value.Date <= x.EndsAt.Date).DefaultIfEmpty()
                                    from fh in facilityHoliday.Where(x => x.FacilityId == em.FacilityId && c.TheDate == x.Holiday.Date).DefaultIfEmpty()
                                    where
                                    c.TheDateTime >= startDate && c.TheDateTime <= endDate
                                    select new contracts.LeadTimeManager.DailyEquipmentCapacity
                                    {
                                        EquipmentId = em.Id,
                                        WorkcenterId = em.WorkcenterTypeId,
                                        UnplannedAllowance = cc.UnplannedAllowance,
                                        UnplannedAllowanceHours = fh != null ? 0 :
                                                        (scp == null ? 0 : (((so.Id != null ? (float)(sot.EndTime - sot.StartTime).TotalMinutes :
                                                    (float)(scp.EndTime - scp.StartTime).TotalMinutes) / 60) * (cc.UnplannedAllowance / 100F))),
                                        AvailabilityThreshold = cc.AvailabilityThreshold,
                                        TheDate = c.TheDate,
                                        FacilityId = em.FacilityId,
                                        TotalCapacityHours = fh != null ? 0 : (scp == null ? 0 : ((so.Id != null ? (float)(sot.EndTime - sot.StartTime).TotalMinutes :
                                                    (float)(scp.EndTime - scp.StartTime).TotalMinutes) / 60)),
                                        InternalLeadTime = cc.MinLeadTime,
                                        ActualCapacityHours = fh != null ? 0 : (((100F - cc.UnplannedAllowance) / 100F) * ((float)(scp == null ? 0 : ((so.Id != null ? (float)(sot.EndTime - sot.StartTime).TotalMinutes :
                                                    (float)(scp.EndTime - scp.StartTime).TotalMinutes) / 60)))),
                                        ShiftStart = so.Id != null ? sot.StartTime : (scp != null ? scp.StartTime : null),
                                        ShiftEnd = so.Id != null ? sot.EndTime : (scp != null ? scp.EndTime : null),
                                        DowntimeStart = ed != null ? ed.StartsOn : null,
                                        DowntimeEnd = ed != null ? ed.EndsAt : null,
                                        IsHoliday = fh != null,

                                    }).Distinct().OrderBy(x => x.EquipmentId).ThenBy(x => x.TheDate).ToListAsync(cancellationToken: token);

                var responseGroupedByShifts = result.GroupBy(x => new { x.EquipmentId, x.TheDate })
                    .Select(x => new contracts.LeadTimeManager.DailyEquipmentCapacity
                    {
                        EquipmentId = x.First().EquipmentId,
                        WorkcenterId = x.First().WorkcenterId,
                        UnplannedAllowance = x.First().UnplannedAllowance,
                        UnplannedAllowanceHours = x.Sum(x => x.UnplannedAllowanceHours),
                        AvailabilityThreshold = x.First().AvailabilityThreshold,
                        TheDate = x.First().TheDate,
                        FacilityId = x.First().FacilityId,
                        TotalCapacityHours = x.Sum(x => x.TotalCapacityHours),
                        ActualCapacityHours = x.Sum(x => x.ActualCapacityHours),
                        InternalLeadTime = x.First().InternalLeadTime,
                        DowntimeHours = CalculateDownTimeHours(x.ToList()),
                        IsHoliday = x.First().IsHoliday,
                    }).ToList();

                return responseGroupedByShifts;
            }
        }

        private static float CalculateDownTimeHours(List<contracts.LeadTimeManager.DailyEquipmentCapacity> capacity)
        {
            if (capacity.Any(x => x.IsHoliday))
                return 0;

            float downtime = 0f;
            foreach (var c in capacity)
            {
                if (c.DowntimeStart != null)
                {
                    downtime += GetDownTimeHoursForDay(c.TheDate, c.DowntimeStart, c.DowntimeEnd, c.ShiftStart, c.ShiftEnd);
                }
            }
            return downtime;
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

        public async Task<List<EquipmentCapacityOutlook>> GetDailyEquipmentCapacityOutlookAsync(DashboardFilter filter, CancellationToken cancellationToken)
        {
            using (Tracer.Benchmark("Equipment-repo-get-daily-equipment-capacity-outlook"))
            using (var unitOfWork = _unitOfWorkFactory.BeginUnitOfWork(DBContextLevel.Tenant, DbAccessMode.read))
            {
                var equipments = unitOfWork.Repository<Commons.EquipmentMaster>().GetQueryable();
                var capacityConfiguration = unitOfWork.Repository<Commons.CapacityConfiguration>().GetQueryable();
                var shiftCalendarSchedule = unitOfWork.Repository<Commons.ShiftCalendarScheduleV2>().GetQueryable();
                var equipmentScheduleMapping = unitOfWork.Repository<Commons.EquipmentScheduleMapping>().GetQueryable();
                var shiftCalendar = unitOfWork.Repository<Commons.ShiftCalendarV2>().GetQueryable();
                var shiftCalendarDates = unitOfWork.Repository<Commons.ShiftCalendarDatesV2>().GetQueryable();
                var shiftCalendarPattern = unitOfWork.Repository<Commons.ShiftCalendarPatternV2>().GetQueryable();
                var calendar = unitOfWork.Repository<Commons.Calendar>().GetQueryable();
                var shiftOverrides = unitOfWork.Repository<Commons.ShiftOverride>().GetQueryable();
                var shiftOverrideTimes = unitOfWork.Repository<Commons.ShiftOverrideTime>().GetQueryable();
                var equipmentDowntimes = unitOfWork.Repository<Commons.EquipmentDowntime>().GetQueryable();
                var equipmentValueStreams = unitOfWork.Repository<Commons.EquipmentValueStream>().GetQueryable();
                var valueStreams = unitOfWork.Repository<Commons.ValueStream>().GetQueryable();
                var facilityHoliday = unitOfWork.Repository<Commons.FacilityHoliday>().GetQueryable().Include(x => x.Holiday);

                var result = await (from c in calendar
                                    from scd in shiftCalendarDates.Where(scd => scd.StartDate <= c.TheDateTime && c.TheDateTime <= scd.EndDate)
                                    join scg in shiftCalendar on scd.ShiftCalendarId equals scg.Id into scGroup
                                    from sc in scGroup.DefaultIfEmpty()
                                    join scpg in shiftCalendarPattern on new { sc.Id, Week = c.TheDayName } equals new { Id = scpg.ShiftCalendarId, Week = scpg.DayOfWeek } into scpGroup
                                    from scp in scpGroup.DefaultIfEmpty()
                                    join ssg in shiftCalendarSchedule on sc.ShiftCalendarScheduleId equals ssg.Id into ssGroup
                                    from ss in ssGroup.DefaultIfEmpty()
                                    join esm in equipmentScheduleMapping on ss.Id equals esm.ShiftCalendarScheduleId
                                    join em in equipments on esm.EquipmentId equals em.Id
                                    join evsg in equipmentValueStreams on em.Id equals evsg.EquipmentId into evsGroup
                                    from evs in evsGroup.DefaultIfEmpty()
                                    join vsg in valueStreams on evs.ValueStreamId equals vsg.Id into vsGroup
                                    from vs in vsGroup.DefaultIfEmpty()
                                    join cc in capacityConfiguration on em.Id equals cc.EquipmentId
                                    join sog in shiftOverrides on c.TheDateTime equals sog.ExceptionDate into soGroup
                                    from so in soGroup.DefaultIfEmpty()
                                    join sotg in shiftOverrideTimes on so.Id equals sotg.ShiftOverrideId into sotGroup
                                    from sot in sotGroup.DefaultIfEmpty()
                                    from ed in equipmentDowntimes.Where(x => x.EquipmentId == em.Id && c.TheDateTime.Value.Date >= x.StartsOn.Date && c.TheDateTime.Value.Date <= x.EndsAt.Date).DefaultIfEmpty()
                                    from fh in facilityHoliday.Where(x => x.FacilityId == em.FacilityId && c.TheDate == x.Holiday.Date).DefaultIfEmpty()
                                    where
                                    c.TheDateTime >= filter.StartDate && c.TheDateTime <= filter.EndDate
                                    && (filter.Facilities.Count == 0 || filter.Facilities.Contains(em.FacilityId))
                                    && (filter.ValueStreams.Count == 0 || filter.ValueStreams.Contains(vs.Id))
                                    && (filter.Workcenters.Count == 0 || filter.Workcenters.Contains(em.WorkcenterTypeId))
                                    && (filter.Equipments.Count == 0 || filter.Equipments.Contains(em.Id))
                                    select new EquipmentCapacityOutlook
                                    {
                                        TheDate = c.TheDate,
                                        EquipmentId = em.Id,
                                        FacilityId = em.FacilityId,
                                        SourceEquipmentId = em.SourceEquipmentId,
                                        ShiftStart = so.Id != null ? sot.StartTime : (scp != null ? scp.StartTime : null),
                                        ShiftEnd = so.Id != null ? sot.EndTime : (scp != null ? scp.EndTime : null),
                                        CapacityHours = scp == null ? 0 : ((so.Id != null ? (float)(sot.EndTime - sot.StartTime).TotalMinutes :
                                                          (float)(scp.EndTime - scp.StartTime).TotalMinutes) / 60),
                                        UnplannedAllowance = cc.UnplannedAllowance,
                                        UnplannedAllowanceHours = scp == null ? 0 : (((so.Id != null ? (float)(sot.EndTime - sot.StartTime).TotalMinutes :
                                                          (float)(scp.EndTime - scp.StartTime).TotalMinutes) / 60) * (cc.UnplannedAllowance / 100F)),
                                        DowntimeStart = ed != null ? ed.StartsOn : null,
                                        DowntimeEnd = ed != null ? ed.EndsAt : null,
                                        IsHoliday = fh != null,

                                    }).Distinct().OrderBy(x => x.EquipmentId).ThenBy(x => x.TheDate).ToListAsync(cancellationToken: cancellationToken);
                return result;
            }
        }

        public async Task<DateTime> GetMaxEquipmentCalendarDate()
        {
            using (Tracer.Benchmark("equipment-repo-get-max-equipment-calendar-date"))
            using (var unitOfWork = _unitOfWorkFactory.BeginUnitOfWork(DBContextLevel.Tenant, DbAccessMode.read))
            {
                return await unitOfWork.Repository<Commons.EquipmentCalendar>().GetQueryable()
                    .Select(x => x.TheDateTime).MaxAsync();
            }
        }

        public async Task<List<EquipmentStagingTickets>> GetEquipmentWiseStagingTicketsAysnc(StagingRequirementFilterDataPayload filter, CancellationToken cancellationToken)
        {
            using (Tracer.Benchmark("repo-equipment-getEquipmentWiseTicketsAysnc"))
            using (var unitOfWork = _unitOfWorkFactory.BeginUnitOfWork(DBContextLevel.Tenant, DbAccessMode.read))
            {
                var scheduleReport = unitOfWork.Repository<Commons.ScheduleReport>().GetQueryable();
                var equipmentMaster = unitOfWork.Repository<Commons.EquipmentMaster>().GetQueryable();

                var equipmentTickets = await (from sr in scheduleReport
                                              join em in equipmentMaster on sr.EquipmentId equals em.Id

                                              where em.IsEnabled && (em.AvailableForScheduling || em.AvailableForPlanning)
                                                    && (filter.UserAssignedFacilities.Count == 0 || filter.UserAssignedFacilities.Contains(em.FacilityId))
                                                    && (filter.StartDate == null || filter.EndDate == null
                                                        || (sr.StartsAt >= filter.StartDate && sr.StartsAt <= filter.EndDate)
                                                        || (sr.EndsAt >= filter.StartDate && sr.EndsAt <= filter.EndDate))

                                              group sr by new { sr.EquipmentId } into groupedEquipments

                                              select new EquipmentStagingTickets
                                              {
                                                  EquipmentId = groupedEquipments.Key.EquipmentId,
                                                  Tickets = groupedEquipments.Select(x => x.SourceTicketId).ToList()
                                              })
                                              .ToListAsync(cancellationToken);
                return equipmentTickets;
            }
        }

        public async Task<List<StagingReportFilterData>> GetStagingFilterDataAsync(StagingRequirementFilterDataPayload filter, CancellationToken cancellationToken)
        {
            using (Tracer.Benchmark("equipment-repo-filter-data"))
            using (var unitOfWork = _unitOfWorkFactory.BeginUnitOfWork(DBContextLevel.Tenant, DbAccessMode.read))
            {
                var valueStreams = unitOfWork.Repository<Commons.ValueStream>().GetQueryable();
                var equipmentValueStreams = unitOfWork.Repository<Commons.EquipmentValueStream>().GetQueryable();
                var equipments = unitOfWork.Repository<Commons.EquipmentMaster>().GetQueryable();
                var facilities = unitOfWork.Repository<Commons.Facility>().GetQueryable();
                var stagingRequirements = unitOfWork.Repository<Commons.StagingRequirement>().GetQueryable();
                var stagingRequirementGroups = unitOfWork.Repository<Commons.StagingRequirementGroup>().GetQueryable();

                var query = from em in equipments

                            join f in facilities on em.FacilityId equals f.Id

                            join evs in equipmentValueStreams on em.Id equals evs.EquipmentId into evsGroup
                            from evs in evsGroup.DefaultIfEmpty()

                            join vs in valueStreams on evs.ValueStreamId equals vs.Id into vsGroup
                            from vs in vsGroup.DefaultIfEmpty()

                            join srg in stagingRequirementGroups on em.WorkcenterTypeId equals srg.WorkcenterTypeId into srgGroup
                            from srg in srgGroup.DefaultIfEmpty()
                            
                            join sr in stagingRequirements on srg.StagingRequirementId equals sr.Id into srGroup
                            from sr in srGroup.DefaultIfEmpty()

                            where em.IsEnabled && (em.AvailableForScheduling || em.AvailableForPlanning)
                                    && (filter.UserAssignedFacilities.Count == 0 || filter.UserAssignedFacilities.Contains(em.FacilityId))

                            select new
                            {
                                Equipment = em,
                                Facility = f,
                                ValueStream = vs,
                                StagingRequirement = sr
                            };

                var groupedEquipments = await query
                    .GroupBy(x => new
                    {
                        EquipmentId = x.Equipment.Id,
                        EquipmentName = x.Equipment.Name,
                        FacilityId = x.Facility.Id,
                        FacilityName = x.Facility.Name,
                        WorkcenterId = x.Equipment.WorkcenterTypeId,
                        WorkcenterName = x.Equipment.WorkCenterName
                    })
                    .Select(g => new StagingReportFilterData
                    {
                        EquipmentId = g.Key.EquipmentId,
                        EquipmentName = g.Key.EquipmentName,
                        FacilityId = g.Key.FacilityId,
                        FacilityName = g.Key.FacilityName,
                        WorkcenterId = g.Key.WorkcenterId,
                        WorkcenterName = g.Key.WorkcenterName,

                        ValueStreams = g.Where(x => x.ValueStream != null)
                                            .Select(x => new contracts.DataDTO
                                            {
                                                Id = x.ValueStream.Id,
                                                Name = x.ValueStream.Name
                                            }).Distinct().ToList(),

                        StagingRequirements = g.Where(x => x.StagingRequirement != null)
                                                    .Select(x => new contracts.DataDTO
                                                    {
                                                        Id = x.StagingRequirement.Id,
                                                        Name = x.StagingRequirement.Name
                                                    }).Distinct().ToList()
                    }).ToListAsync(cancellationToken);

                return groupedEquipments;
            }
        }
    }
}
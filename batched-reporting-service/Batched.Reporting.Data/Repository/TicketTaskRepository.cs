using Batched.Common;
using Batched.Common.Data.Sql.Extensions;
using Batched.Common.Data.Tenants.Sql.Models;
using Batched.Reporting.Contracts;
using Batched.Reporting.Contracts.Interfaces;
using Batched.Reporting.Contracts.Models.LeadTimeManager;
using Batched.Reporting.Data.Contracts;
using Microsoft.EntityFrameworkCore;
using System.Data;
using ContractModels = Batched.Reporting.Contracts.Models;
using static Batched.Reporting.Shared.BatchedConstants;
using Microsoft.Data.SqlClient;
using Dapper;

namespace Batched.Reporting.Data
{
    public class TicketTaskRepository : ITicketTaskRepository
    {
        private readonly UnitOfWorkFactory _unitOfWorkFactory;
        private readonly IConnectionStringService _connectionStringService;

        public TicketTaskRepository(UnitOfWorkFactory unitOfWorkFactory, IConnectionStringService connectionStringService)
        {
            _unitOfWorkFactory = unitOfWorkFactory;
            _connectionStringService = connectionStringService;
        }

        public async Task<List<ContractModels.TicketsDemand>> GetTicketsDemandAsync(DashboardFilter filter, DateTime endDate, CancellationToken cancellationToken)
        {
            using (Tracer.Benchmark("ticketTask-repo-get-tickets-demand"))
            using (IUnitOfWork unitOfWork = _unitOfWorkFactory.BeginUnitOfWork(DBContextLevel.Tenant, DbAccessMode.read))
            {
                var ticketTasks = unitOfWork.Repository<TicketTask>().GetQueryable().Include(x => x.Ticket);
                var equipmentMaster = unitOfWork.Repository<EquipmentMaster>().GetQueryable();
                var facilities = unitOfWork.Repository<Facility>().GetQueryable();
                var valueStreams = unitOfWork.Repository<ValueStream>().GetQueryable();
                var ticketShippings = unitOfWork.Repository<TicketShipping>().GetQueryable();
                var equipmentValueStreams = unitOfWork.Repository<EquipmentValueStream>().GetQueryable();
                var capacityConfiguration = unitOfWork.Repository<CapacityConfiguration>().GetQueryable();
                var scheduleReport = unitOfWork.Repository<ScheduleReport>().GetQueryable();

                var response = await (from tt in ticketTasks
                                      join tsg in ticketShippings on tt.TicketId equals tsg.TicketId into tsGroup
                                      from ts in tsGroup.DefaultIfEmpty()
                                      join srg in scheduleReport on new { tt.Ticket.SourceTicketId, tt.TaskName } equals new { srg.SourceTicketId, srg.TaskName } into srGroup
                                      from sr in srGroup.DefaultIfEmpty()
                                      join em in equipmentMaster on sr != null ? sr.EquipmentId : tt.OriginalEquipmentId equals em.Id
                                      join evsg in equipmentValueStreams on sr != null ? sr.EquipmentId : em.Id equals evsg.EquipmentId into evsGroup
                                      from evs in evsGroup.DefaultIfEmpty()
                                      join vsg in valueStreams on evs.ValueStreamId equals vsg.Id into vsGroup
                                      from vs in vsGroup.DefaultIfEmpty()
                                      join facility in facilities on em.FacilityId equals facility.Id
                                      join cc in capacityConfiguration on em.Id equals cc.EquipmentId
                                      where (filter.Facilities.Count == 0 || filter.Facilities.Contains(em.FacilityId))
                                          && (filter.ValueStreams.Count == 0 || filter.ValueStreams.Contains(vs.Id))
                                          && (filter.Workcenters.Count == 0 || filter.Workcenters.Contains(em.WorkcenterTypeId))
                                          && (filter.Equipments.Count == 0 || filter.Equipments.Contains(em.Id))
                                          && !tt.IsComplete
                                          && (filter.ScheduleStatus == "" || (filter.ScheduleStatus == "Scheduled" && sr != null) ||
                                             (filter.ScheduleStatus == "Unscheduled" && sr == null))
                                          && (ts.ShipByDateTime <= endDate || ts.ShipByDateTime == null)
                                      select new ContractModels.TicketsDemand
                                      {
                                          FacilityId = em.FacilityId,
                                          FacilityName = facility.Name,
                                          ValueStreamId = evs.ValueStreamId,
                                          ValueStreamName = vs.Name,
                                          WorkcenterName = em.WorkCenterName,
                                          WorkcenterId = em.WorkcenterTypeId,
                                          EquipmentId = em.Id,
                                          EquipmentName = em.Name,
                                          TicketId = tt.TicketId,
                                          SourceTicketId = tt.Ticket.SourceTicketId,
                                          EstTotalHours = tt.ActualEstTotalHours ?? 0F,
                                          UnplannedAllowance = cc.UnplannedAllowance,
                                          MinLeadTime = cc.MinLeadTime,
                                          ShipByDate = ts.ShipByDateTime,
                                      }).ToListAsync(cancellationToken: cancellationToken);
                return response;

            }
        }

        public async Task<List<dynamic>> GetOpenTicketsLTMAsync(LeadTimeManagerFilters filter, List<string> availableAttributes, List<ContractModels.ReportViewField> columns, CancellationToken cancellationToken)
        {
            var query = BuildDynamicQueryForLTM(columns, availableAttributes, filter.EndDate);
            var connectionString = await _connectionStringService.GetTenantConnectionString();

            using (Tracer.Benchmark("get-spGetOpenTicketsLTM"))
            using (var connection = new SqlConnection(connectionString))
            {
                var openTickets = (await connection.QueryAsync<dynamic>(query)).ToList();
                return openTickets;
            }
        }

        public async Task<List<string>> GetTicketAttributesAvailableInCacheTable()
        {
            var query = @"SELECT COLUMN_NAME 
                          FROM INFORMATION_SCHEMA.COLUMNS 
                          WHERE TABLE_NAME = 'CVTicketAttributesCache' and COLUMN_NAME <> 'TicketId'"
            ;

            var connectionString = await _connectionStringService.GetTenantConnectionString();

            using (Tracer.Benchmark("get-ticket-attribute-cache-columns"))
            using (var connection = new SqlConnection(connectionString))
            {
                return (await connection.QueryAsync<string>(query)).ToList();
            }
        }


        public async Task<List<LastRunInfo>> GetLastJobRunInfoAsync(CancellationToken cancellationToken)
        {
            using (Tracer.Benchmark("ticketTask-repo-get-last-run-info"))
            using (IUnitOfWork unitOfWork = _unitOfWorkFactory.BeginUnitOfWork(DBContextLevel.Tenant, DbAccessMode.read))
            {
                var timecardInfo = unitOfWork.Repository<TimecardInfo>().GetQueryable();

                var timeCard = await (from tci in timecardInfo
                                      where tci.StartedOn > DateTime.Now.AddDays(-15)
                                      select new TimeCard
                                      {
                                          EquipmentId = tci.EquipmentId,
                                          TicketId = tci.TicketId,
                                          SourceTicketId = tci.SourceTicketId,
                                          StartDateTime = tci.StartedOn
                                      }).ToListAsync(cancellationToken: cancellationToken);

                var lastRunTime = timeCard.GroupBy(x => x.EquipmentId).Select(x => new LastRunTime
                {
                    LastRunEquipmentId = x.Key,
                    MaxStartDateTime = x.Max(t => t.StartDateTime),
                }).ToList();

                var lastRunData = (from lrt in lastRunTime
                                   join tc in timeCard on new { EquipmentId = lrt.LastRunEquipmentId, StartDate = lrt.MaxStartDateTime }
                                                         equals new { tc.EquipmentId, StartDate = tc.StartDateTime }
                                   select new LastRunInfo
                                   {
                                       LastRunEquipmentId = lrt.LastRunEquipmentId,
                                       SourceTicketId = tc.SourceTicketId
                                   }).ToList();
                return lastRunData;
            }
        }


        private static string BuildDynamicQueryForLTM(List<ContractModels.ReportViewField> columns, List<string> availableAttributes, DateTime? endDate)
        {
            var baseQuery = @"
                SELECT {0}
                FROM [dbo].[TicketDataCache] SMC
                    LEFT JOIN [dbo].[ScheduleReport] SR ON [SMC].[TicketNumber] = [SR].[SourceTicketId] AND [SMC].[TaskName] = [SR].[TaskName]
                    LEFT JOIN [dbo].[EquipmentMaster] ScheduledEM ON [ScheduledEM].[ID] = [SR].[EquipmentId]
                    LEFT JOIN [dbo].[CVTicketAttributesCache] SMTA ON [SMC].[TicketId] = [SMTA].[TicketId]
                WHERE [SMC].[TaskName] IS NOT NULL AND [SMC].[IsComplete] = 0";

            var columnSelections = new List<string>();
            columnSelections.AddRange(ConfigurableViewsReportConstant.MandatoryColumnList);

            foreach (var column in columns)
            {
                if (column.Category.Equals("Ticket") && !ConfigurableViewsReportConstant.ExcludedColumnList.Contains(column.FieldName))
                {
                    if (ConfigurableViewsReportConstant.ColumnsOtherThanCacheTable.TryGetValue(column.FieldName, out string columnSelectionValue))
                        columnSelections.Add(columnSelectionValue);
                    else
                        columnSelections.Add($"[SMC].[{column.JsonName}]");
                }
                else if (column.Category.Equals("TicketAttribute") && availableAttributes.Contains(column.JsonName))
                {
                    columnSelections.Add($"[SMTA].[{column.JsonName}]");
                }
            }

            var columnsQuery = string.Join(", ", columnSelections);

            if (endDate == null)
                return string.Format(baseQuery, columnsQuery);

            baseQuery += @" AND ([SMC].[ShipByDate] IS NULL OR [SMC].[ShipByDate] <= '{1}');";

            return string.Format(baseQuery, columnsQuery, endDate);
        }
    }
}

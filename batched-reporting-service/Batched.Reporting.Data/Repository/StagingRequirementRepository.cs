using Batched.Common;
using Batched.Common.Data.Sql.Extensions;
using Batched.Common.Data.Tenants.Sql.Models;
using Batched.Reporting.Contracts.Interfaces;
using Batched.Reporting.Contracts.Models.StagingRequirement;
using Batched.Reporting.Data.Contracts;
using Batched.Reporting.Data.Translators;
using Microsoft.EntityFrameworkCore;
using System.Data;
using Batched.Common.Data.Sql.Models;
using Batched.Reporting.Shared.Helper;
using static Batched.Reporting.Shared.Extensions;
using static Batched.Reporting.Shared.BatchedConstants;
using CommonTicketAttributeValue = Batched.Common.Data.Tenants.Sql.Models.TicketAttributeValue;
using ServiceTicketAttributeValue = Batched.Reporting.Contracts.Models.StagingRequirement.TicketAttributeValue;
using Batched.Reporting.Shared;

namespace Batched.Reporting.Data.Repository
{
    public class StagingRequirementRepository : IStagingRequirementRepository
    {
        private readonly UnitOfWorkFactory _unitOfWorkFactory;
        private readonly IConnectionStringService _connectionStringService;

        public StagingRequirementRepository(UnitOfWorkFactory unitOfWorkFactory, IConnectionStringService connectionStringService)
        {
            _unitOfWorkFactory = unitOfWorkFactory;
            _connectionStringService = connectionStringService;
        }

        public async Task<List<StagingRequirements>> GetAllStagingRequirementsAsync()
        {
            using (Tracer.Benchmark("get-all-staging-requirements"))
            using (var unitOfWork = _unitOfWorkFactory.BeginUnitOfWork(DBContextLevel.Tenant, DbAccessMode.read))
            {
                var stagingRequirements = await unitOfWork.Repository<StagingRequirement>().GetQueryable()
                                                .Select(x => new StagingRequirements
                                                {
                                                    StagingRequirementId = x.Id,
                                                    StagingRequirementName = x.Name
                                                })
                                                .ToListAsync();
                return stagingRequirements;
            }
        }

        public async Task<List<string>> GetApplicableStagingRequirementsForTicketTaskAsync(TicketTaskStagingInfoPayload stagingPayload, CancellationToken cancellationToken)
        {
            using (Tracer.Benchmark("get-TicketTaskStagingRequirements"))
            using (var unitOfWork = _unitOfWorkFactory.BeginUnitOfWork(DBContextLevel.Tenant, DbAccessMode.read))
            {
                var scheduleReport = unitOfWork.Repository<ScheduleReport>().GetQueryable();
                var equipmentMaster = unitOfWork.Repository<EquipmentMaster>().GetQueryable();
                var stagingRequirementGroup = unitOfWork.Repository<StagingRequirementGroup>().GetQueryable();
                var stagingRequirement = unitOfWork.Repository<StagingRequirement>().GetQueryable();

                return await (
                        from sr in scheduleReport
                        where sr.SourceTicketId == stagingPayload.TicketNumber && sr.TaskName == stagingPayload.TaskName
                        join em in equipmentMaster on sr.EquipmentId equals em.Id
                        join srg in stagingRequirementGroup on em.WorkcenterTypeId equals srg.WorkcenterTypeId into srgGroup
                        from srg in srgGroup.DefaultIfEmpty()
                        join srq in stagingRequirement on srg.StagingRequirementId equals srq.Id into srqGroup
                        from srq in srqGroup.DefaultIfEmpty()
                        where srq.Name != null
                        select srq.Name
                    ).ToListAsync(cancellationToken);
            }
        }

        public async Task<List<TicketTaskStagingData>> GetTicketTaskStagingInfoAsync(StagingRequirementFilter filter, CancellationToken cancellationToken)
        {
            using (Tracer.Benchmark("get-TicketTaskStagingInfo"))
            using (var unitOfWork = _unitOfWorkFactory.BeginUnitOfWork(DBContextLevel.Tenant, DbAccessMode.read))
            {
                var spName = "spGetStagingRequirementKPI";
                string connectionString = await _connectionStringService.GetTenantConnectionString();
                var parameters = GetStagingRequirementKPIParameters(filter).ToList();

                var dataTables = RepositoryHelper.ExecuteCommand(spName, connectionString, parameters);

                return StagingRequirementTranslator.TranslateToKPIData(dataTables);
            }
        }

        public async Task<StagingRequirementData> GetStagingRequirementDataAsync(StagingRequirementReportFilter filter, List<string> ticketAttributes,
            DateTime tenantLocalDateTime, List<StagingRequirements> stagingRequirements, List<string> configurableViewTicketAttributes, CancellationToken cancellationToken)
        {
            using (Tracer.Benchmark("get-StagingRequirementData"))
            using (var unitOfWork = _unitOfWorkFactory.BeginUnitOfWork(DBContextLevel.Tenant, DbAccessMode.read))
            {
                var spName = "spGetStagingRequirementsData";
                string connectionString = await _connectionStringService.GetTenantConnectionString();
                var parameters = GetStagingRequirementReportParameters(filter, tenantLocalDateTime).ToList();
                parameters.Add(new SPParam() { Name = "ticketAttributeNames", SqlDbType = SqlDbType.Structured, Value = RepositoryHelper.GetSingleValueDataTable(ticketAttributes) });
                parameters.Add(new SPParam() { Name = "currentLocalDate", SqlDbType = SqlDbType.DateTime, Value = this.GetTenantCurrentTime(filter.TenantId) });

                var dataTables = RepositoryHelper.ExecuteCommand(spName, connectionString, parameters);
                return StagingRequirementTranslator.TranslateToReportData(dataTables, tenantLocalDateTime, stagingRequirements, filter, configurableViewTicketAttributes);
            }
        }

        public async Task UpdateTicketTaskStagingStateAsync(List<TicketTaskStagingPayload> ticketTaskStagingData, CancellationToken cancellationToken)
        {
            using (Tracer.Benchmark("mark-ticket-task-staged-unstaged"))
            {
                var connectionString = await _connectionStringService.GetTenantConnectionString();
                foreach (var stagingData in ticketTaskStagingData)
                {
                    await AddTicketTaskStagingInfoIfNotExists(stagingData, cancellationToken);

                    var baseQuery = @"UPDATE TicketTaskStagingInfo SET {0}, ModifiedOnUtc = GETUTCDATE()
                                            WHERE TicketId = '{1}' AND Taskname = '{2}'";

                    var columnSelections = new List<string>();

                    foreach (var stagingComponent in stagingData.StagingComponents)
                        columnSelections.Add(string.Concat(stagingComponent.Name.GetStagingNameKey(), "=", stagingComponent.IsStaged == true ? "1" : "0"));

                    var columnsQuery = string.Join(", ", columnSelections);
                    var finalQuery = string.Format(baseQuery, columnsQuery, stagingData.TicketId, stagingData.TaskName);

                    using (var unitOfWork = _unitOfWorkFactory.BeginUnitOfWork(DBContextLevel.Tenant, DbAccessMode.write))
                    {
                        await unitOfWork.ExecuteAsync(finalQuery);
                        unitOfWork.Complete();
                    }
                }
            }
        }

        public async Task UpdateStagingStatusInTicketDataCache(List<string> tickets, CancellationToken cancellationToken)
        {
            using (Tracer.Benchmark("update-staging-status-ticket-data-cache"))
            using (var unitOfWork = _unitOfWorkFactory.BeginUnitOfWork(DBContextLevel.Tenant, DbAccessMode.read))
            {
                var spName = "spUpdateStagingStatusInTicketDataCache";
                string connectionString = await _connectionStringService.GetTenantConnectionString();

                var parameters = new List<SPParam>
                    {
                        new SPParam { Name = "TicketIds", SqlDbType = SqlDbType.Structured, Value = RepositoryHelper.GetSingleValueDataTable(tickets)},
                        new SPParam { Name = "TenantId", SqlDbType = SqlDbType.NVarChar, Value = ApplicationContext.Current.TenantId},
                        new SPParam { Name = "CorelationId", SqlDbType = SqlDbType.VarChar, Value = ApplicationContext.Current.CorrelationId}
                    };

                var dataTables = RepositoryHelper.ExecuteCommand(spName, connectionString, parameters);
            }
        }

        public async Task<List<TicketLevelAttributeValues>> GetTicketAttributeValuesAsync(List<string> ticketIds, List<string> ticketAttributes, CancellationToken cancellationToken)
        {
            using (Tracer.Benchmark("get-ticket-task-staging-info"))
            using (var unitOfWork = _unitOfWorkFactory.BeginUnitOfWork(DBContextLevel.Tenant, DbAccessMode.read))
            {
                var ticketAttributesData = await unitOfWork.Repository<CommonTicketAttributeValue>()
                    .GetQueryable()
                    .Where(x => (ticketAttributes.Count == 0 || ticketAttributes.Contains(x.Name))
                        && (ticketIds.Count == 0 || ticketIds.Contains(x.TicketId)))
                    .GroupBy(x => x.TicketId)
                    .Select(x => new TicketLevelAttributeValues
                    {
                        TicketId = x.Key,
                        TicketAttributeValues = x.Select(z => new ServiceTicketAttributeValue
                        {
                            Name = z.Name,
                            Value = z.Value
                        }).ToList()
                    }).ToListAsync(cancellationToken);

                return ticketAttributesData;
            }
        }


        private async Task AddTicketTaskStagingInfoIfNotExists(TicketTaskStagingPayload stagingData, CancellationToken cancellationToken)
        {
            using (var unitOfWork = _unitOfWorkFactory.BeginUnitOfWork(DBContextLevel.Tenant, DbAccessMode.write))
            {
                var ticketStagingInfo = await unitOfWork.Repository<TicketTaskStagingInfo>().GetQueryable()
                                        .Where(x => x.TicketId == stagingData.TicketId && x.Taskname == stagingData.TaskName)
                                        .FirstOrDefaultAsync(cancellationToken: cancellationToken);

                if (ticketStagingInfo == null)
                {
                    ticketStagingInfo = CreateDefaultTicketTaskStagingInfo(stagingData);
                    await unitOfWork.Repository<TicketTaskStagingInfo>().AddAsync(ticketStagingInfo);
                }
                unitOfWork.Complete();
            }
        }


        private static TicketTaskStagingInfo CreateDefaultTicketTaskStagingInfo(TicketTaskStagingPayload stagingData)
        {
            return new TicketTaskStagingInfo
            {
                Id = Guid.NewGuid().ToString(),
                TicketId = stagingData.TicketId,
                Taskname = stagingData.TaskName,
                CreatedOnUtc = DateTime.UtcNow,
                ModifiedOnUtc = DateTime.UtcNow,
            };
        }

        private DateTime GetTenantCurrentTime(string tenantId)
        {
            using (var unitOfWork = _unitOfWorkFactory.BeginUnitOfWork(DBContextLevel.Batched, DbAccessMode.read))
            {
                var tenantDB = unitOfWork.Repository<Tenant>().GetQueryable();

                var result = tenantDB.FirstOrDefault(m => m.Id == tenantId);

                DateTimeWithZone timeZone = new DateTimeWithZone(result.TimeZone);

                return timeZone.LocalTime;
            };
        }

        private IEnumerable<SPParam> GetStagingRequirementKPIParameters(StagingRequirementFilter filter)
        {
            var spPrameters = SpParameters.Create
                .Add("startDate", filter.StartDate, SqlDbType.DateTime)
                .Add("endDate", filter.EndDate, SqlDbType.DateTime)
                .Add("facilities", RepositoryHelper.GetSingleValueDataTable(filter.Facilities), SqlDbType.Structured)
                .Add("ticketNumbers", RepositoryHelper.GetSingleValueDataTable(filter.Tickets), SqlDbType.Structured)
                .Add("equipments", RepositoryHelper.GetSingleValueDataTable(filter.Equipments), SqlDbType.Structured)
                .Add("workcenters", RepositoryHelper.GetSingleValueDataTable(filter.Workcenters), SqlDbType.Structured)
                .Add("valuestreams", RepositoryHelper.GetSingleValueDataTable(filter.ValueStreams), SqlDbType.Structured)
                .Add("components", RepositoryHelper.GetSingleValueDataTable(filter.Components), SqlDbType.Structured);

            return spPrameters;
        }

        private IEnumerable<SPParam> GetStagingRequirementReportParameters(StagingRequirementReportFilter filter, DateTime tenantLocalDateTime)
        {
            var spPrameters = SpParameters.Create
                .Add("startDate", filter.StartDate, SqlDbType.DateTime)
                .Add("endDate", filter.EndDate, SqlDbType.DateTime)
                .Add("facilities", RepositoryHelper.GetSingleValueDataTable(filter.Facilities), SqlDbType.Structured)
                .Add("sourceTicketNumbers", RepositoryHelper.GetSingleValueDataTable(filter.Tickets), SqlDbType.Structured)
                .Add("equipments", RepositoryHelper.GetSingleValueDataTable(filter.Equipments), SqlDbType.Structured)
                .Add("workcenters", RepositoryHelper.GetSingleValueDataTable(filter.Workcenters), SqlDbType.Structured)
                .Add("valuestreams", RepositoryHelper.GetSingleValueDataTable(filter.ValueStreams), SqlDbType.Structured)
                .Add("components", RepositoryHelper.GetSingleValueDataTable(filter.Components), SqlDbType.Structured)
                .Add("SortingColumn", filter.SortBy != "" ? filter.SortBy : null, SqlDbType.VarChar)
                .Add("TenantId", filter.TenantId, SqlDbType.VarChar)
                .Add("RowsOfPage", filter.PageSize, SqlDbType.Int)
                .Add("PageNumber", filter.PageNumber, SqlDbType.Int)
                .Add("stagingComponentNames", RepositoryHelper.GetSingleValueDataTable(StagingRequirementReportConstant.StagingRequirementAttributes.Keys.ToList()), SqlDbType.Structured);

            return spPrameters;
        }
    }
}
using Batched.Reporting.Contracts;
using Batched.Reporting.Contracts.Interfaces;
using Batched.Reporting.Contracts.Models;
using Batched.Reporting.Contracts.Models.Export;
using Batched.Reporting.Contracts.Models.StagingRequirement;
using Batched.Reporting.Core.Translators;
using Batched.Reporting.Shared;
using Newtonsoft.Json;
using static Batched.Reporting.Shared.BatchedConstants;

namespace Batched.Reporting.Core.Services
{
    public class ExportService : IExportService
    {
        private readonly Common.Export.IExportService _exportService;
        private readonly IAwsSetting _awsSetting;
        private readonly ITicketTaskRepository _ticketTaskRepository;
        private readonly ILeadTimeProvider _leadTimeReportProvider;
        private readonly ILeadTimeExceptionsProvider _leadTimeExceptionsProvider;
        private readonly IConfigurableViewsProvider _configurableViewsProvider;
        private readonly IStagingRequirementProvider _stagingRequirementProvider;

        public ExportService(
            Common.Export.IExportService exportService,
            IAwsSetting awsSetting,
            ITicketTaskRepository ticketTaskRepository,
            ILeadTimeProvider leadTimeReportProvider,
            ILeadTimeExceptionsProvider leadTimeExceptionsProvider,
            IConfigurableViewsProvider configurableViewsProvider,
            IStagingRequirementProvider stagingRequirementProvider)
        {
            _exportService = exportService;
            _awsSetting = awsSetting;
            _ticketTaskRepository = ticketTaskRepository;
            _leadTimeReportProvider = leadTimeReportProvider;
            _leadTimeExceptionsProvider = leadTimeExceptionsProvider;
            _configurableViewsProvider = configurableViewsProvider;
            _stagingRequirementProvider = stagingRequirementProvider;
        }

        public async Task<ExportData> ExportAsync(ExportLeadTimeTableRequest exportRequest, CancellationToken cancellationToken)
        {
            // Temporary implementation.
            // Will change once all the LTM tables gets converted into Configurable views.
            // There will be no need of If-Else block.

            List<List<string>> convertedData;

            if (exportRequest.ExportMetadata.EntityName.Equals(ReportName.OpenTickets))
            {
                var configurableViewColumns = await _configurableViewsProvider.GetConfigurableViewFieldsAsync(exportRequest.Filters.ViewId, exportRequest.Filters.ReportName, cancellationToken);

                if (configurableViewColumns.NoViewFound)
                {
                    return new ExportData
                    {
                        Status = new Status
                        {
                            Code = "400",
                            Error = true,
                            Message = "No view found.",
                            Type = "failure"
                        },
                        Url = string.Empty
                    };
                }

                convertedData = await GetDataAsync(exportRequest, configurableViewColumns.Columns, cancellationToken);
            }
            else
            {
                convertedData = await GetDataAsync(exportRequest.Filters, exportRequest.ExportMetadata.EntityName, exportRequest.ExportMetadata.RequiredColumns, cancellationToken);
            }

            var url = _exportService.CreateAndExportFile(ApplicationContext.Current.TenantName, exportRequest.ExportMetadata.Translate(), _awsSetting.GetAwsSettings(), convertedData, null);
            return new ExportData
            {
                Url = url
            };
        }

        public async Task<ExportData> ExportAsync(ExportStagingRequirementReportRequest exportRequest, CancellationToken cancellationToken)
        {
            var configurableViewColumns = await _configurableViewsProvider.GetConfigurableViewFieldsAsync(exportRequest.Filters.ViewId, exportRequest.Filters.ReportName, cancellationToken);

            if (configurableViewColumns.NoViewFound)
            {
                return new ExportData
                {
                    Status = new Status
                    {
                        Code = "400",
                        Error = true,
                        Message = "No view found.",
                        Type = "failure"
                    },
                    Url = string.Empty
                };
            }

            var convertedData = await GetDataAsync(exportRequest.Filters, exportRequest.ExportMetadata.EntityName, configurableViewColumns.Columns, exportRequest.ExportMetadata.RequiredColumns, cancellationToken);
            var url = _exportService.CreateAndExportFile(ApplicationContext.Current.TenantName, exportRequest.ExportMetadata.Translate(), _awsSetting.GetAwsSettings(), convertedData, null);

            return new ExportData
            {
                Url = url
            };
        }


        async Task<List<List<string>>> GetDataAsync(StagingRequirementReportFilter filter, string reportName, List<ReportViewField> reportFields, List<string> requiredColumns, CancellationToken cancellationToken)
        {
            switch (reportName)
            {
                case ReportName.StagingRequirement:
                    var stagingData = await _stagingRequirementProvider.GetStagingRequirementReportAsync(filter, cancellationToken);
                    return stagingData.ScheduledTasksStagingData.ConvertToExportableTemplate(reportFields, requiredColumns);

                default:
                    return new List<List<string>>();
            }
        }

        async Task<List<List<string>>> GetDataAsync(ExportLeadTimeTableRequest exportRequest, List<ReportViewField> reportFields, CancellationToken cancellationToken)
        {
            switch (exportRequest.ExportMetadata.EntityName)
            {
                case ReportName.OpenTickets:
                    var openTicketsData = await _leadTimeReportProvider.GetOpenTicketsLTMAsync(exportRequest.Filters, cancellationToken);
                    return openTicketsData.OpenTickets.ConvertToExportableTemplate(reportFields, exportRequest.ExportMetadata.RequiredColumns);

                default:
                    return new();
            }
        }

        async Task<List<List<string>>> GetDataAsync(DashboardFilter filter, string tableName, List<string> requiredColumns, CancellationToken cancellationToken)
        {
            string columnStr;
            List<ExportTableColumns> columns;

            switch (tableName)
            {
                case TableNames.CapacitySummary:
                    columnStr = File.ReadAllText("Data/CapacitySummaryColumns.json");
                    columns = JsonConvert.DeserializeObject<List<ExportTableColumns>>(columnStr);
                    var capacitySummaryData = await _leadTimeReportProvider.GetCapacitySummaryAsync(filter, cancellationToken);
                    return capacitySummaryData.ConvertToExportableTemplate(columns, requiredColumns);

                case TableNames.LeadTimeExceptions:
                    columnStr = File.ReadAllText("Data/LeadTimeExceptionsColumns.json");
                    columns = JsonConvert.DeserializeObject<List<ExportTableColumns>>(columnStr);
                    var exceptionsData = await _leadTimeExceptionsProvider.GetLeadTimeExceptionsAsync(cancellationToken);
                    return exceptionsData.Exceptions.ConvertToExportableTemplate(columns, requiredColumns);

                default:
                    return new();
            }
        }
    }
}
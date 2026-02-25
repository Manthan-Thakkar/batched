using Batched.Reporting.Contracts.Models.Export;

namespace Batched.Reporting.Contracts.Interfaces
{
    public interface IExportService
    {
        Task<ExportData> ExportAsync(ExportLeadTimeTableRequest exportRequest, CancellationToken cancellationToken);
        Task<ExportData> ExportAsync(ExportStagingRequirementReportRequest exportRequest, CancellationToken cancellationToken);
    }
}
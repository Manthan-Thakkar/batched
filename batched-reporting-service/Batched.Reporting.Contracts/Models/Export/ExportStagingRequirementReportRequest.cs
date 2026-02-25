using Batched.Reporting.Contracts.Models.StagingRequirement;

namespace Batched.Reporting.Contracts.Models.Export
{
    public class ExportStagingRequirementReportRequest
    {
        public StagingRequirementReportFilter Filters { get; set; }
        public ExportMetadata ExportMetadata { get; set; }
    }
}
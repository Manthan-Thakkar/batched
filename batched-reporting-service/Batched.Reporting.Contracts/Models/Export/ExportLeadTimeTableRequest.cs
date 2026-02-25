using Batched.Reporting.Contracts.Models.LeadTimeManager;

namespace Batched.Reporting.Contracts.Models.Export
{
    public class ExportLeadTimeTableRequest
    {
        public LeadTimeManagerFilters Filters { get; set; }
        public ExportMetadata ExportMetadata { get; set; }
    }
}
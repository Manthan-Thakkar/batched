namespace Batched.Reporting.Contracts.Models.StagingRequirement
{
    public class StagingRequirementFilter
    {
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
        public List<string> Facilities { get; set; }
        public List<string> ValueStreams { get; set; }
        public List<string> Workcenters { get; set; }
        public List<string> Equipments { get; set; }
        public List<string> Tickets { get; set; }
        public List<string> Components { get; set; }
    }

    public class StagingRequirementReportFilter : StagingRequirementFilter 
    {
        public string TenantId { get; set; }
        public int PageNumber { get; set; }
        public int PageSize { get; set; }
        public string SortBy { get; set; }
        public string ReportName { get; set; }
        public string ViewId { get; set; }
    }
}
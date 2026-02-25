namespace Batched.Reporting.Contracts.Models.LeadTimeManager
{
    public class LeadTimeManagerFilters : DashboardFilter
    {
        public string ReportName { get; set; }
        public string SortField { get; set; }
        public string SortBy { get; set; }
        public string ViewId { get; set; }
    }
}

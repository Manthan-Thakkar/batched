namespace Batched.Reporting.Web.Models.LeadTimeManager
{
    /// <summary>
    /// Filter object for filter the API response based on ReportName, ViewId, Facilities, From date and To date and add required sorting based on SortField.
    /// </summary>
    public class LeadTimeManagerFilters: DashboardFilter
    {
        /// <summary>
        /// Name of the report.
        /// </summary>
        /// <example>"OpenTicketsLTM"</example>
        public string ReportName { get; set; }

        /// <summary>
        /// Field on which the report should be sorted with.
        /// </summary>
        /// <example>"ticketNumber"</example>
        public string SortField { get; set; }

        /// <summary>
        /// Sort method by which the report should be sorted with.
        /// </summary>
        /// <example>"asc"</example>
        public string SortBy { get; set; }

        /// <summary>
        /// Id of the view.
        /// </summary>
        /// <example>"4233c3a8-c524-4a2f-88c2-5b177955baf6"</example>
        public string ViewId { get; set; }
    }
}

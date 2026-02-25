namespace Batched.Reporting.Web.Models.StagingRequirement
{
    /// <summary>
    /// Filter object for filter the API response based on User Assigned Facilities, From date and To date.
    /// </summary>
    public class StagingRequirementFilter
    {
        /// <summary>
        /// Selected Facilities if any or Facilities assigned to the user.
        /// </summary>
        /// <example>["4233c3a8-c524-4a2f-88c2-5b177955baf6"]</example>
        public List<string> Facilities { get; set; }

        /// <summary>
        /// Selected Value Streams.
        /// </summary>
        /// <example>["4233c3a8-c524-4a2f-88c2-5b177955baf6"]</example>
        public List<string> ValueStreams { get; set; }

        /// <summary>
        /// Selected Workcenters.
        /// </summary>
        /// <example>["4233c3a8-c524-4a2f-88c2-5b177955baf6"]</example>
        public List<string> Workcenters { get; set; }

        /// <summary>
        /// Selected Equipments.
        /// </summary>
        /// <example>["4233c3a8-c524-4a2f-88c2-5b177955baf6"]</example>
        public List<string> Equipments { get; set; }

        /// <summary>
        /// Selected Tickets.
        /// </summary>
        /// <example>["80107", "81203"]</example>
        public List<string> Tickets { get; set; }

        /// <summary>
        /// Selected Staging Requirements.
        /// </summary>
        /// <example>["4233c3a8-c524-4a2f-88c2-5b177955baf6"]</example>
        public List<string> Components { get; set; }

        /// <summary>
        /// From date to filter the data.
        /// </summary>
        /// <example>"2024-03-15T00:00:00"</example>
        public DateTime? StartDate { get; set; }

        /// <summary>
        /// To date to filter the data.
        /// </summary>
        /// <example>"2024-10-15T00:00:00"</example>
        public DateTime? EndDate { get; set; }
    }

    /// <summary>
    /// Filter object for filter the API response of Staging requirement report paginated data.
    /// </summary>

    public class StagingRequirementReportFilter : StagingRequirementFilter
    {

        /// <summary>
        /// Tenant Id of the client.
        /// </summary>
        /// <example>["4233c3a8-c524-4a2f-88c2-5b177955baf6"]</example>
        public string TenantId { get; set; }

        /// <summary>
        /// Page number for fetching report records.
        /// </summary>
        /// <example>2</example>
        public int PageNumber { get; set; }

        /// <summary>
        /// Page size for fetching report records in single page.
        /// </summary>
        /// <example>25</example>
        public int PageSize { get; set; }

        /// <summary>
        /// Field json name to sort the report records.
        /// </summary>
        /// <example>+TicketNumber</example>
        public string SortBy { get; set; }

        /// <summary>
        /// Report Name for the configurable view.
        /// </summary>
        /// <example>["Staging"]</example>
        public string ReportName { get; set; }

        /// <summary>
        /// Report Name for the configurable view.
        /// </summary>
        /// <example>["451B5F87-6B3A-4961-9C40-D9FE6964F68E"]</example>
        public string ViewId { get; set; }

    }
}
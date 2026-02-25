namespace Batched.Reporting.Web.Models.StagingRequirement
{
    /// <summary>
    /// Filter object for filter the API response based on User Assigned Facilities, From date and To date.
    /// </summary>
    public class StagingRequirementFilterDataPayload
    {
        /// <summary>
        /// Facilities assigned to the User.
        /// </summary>
        /// <example>["4233c3a8-c524-4a2f-88c2-5b177955baf6"]</example>
        public List<string> UserAssignedFacilities { get; set; }

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
}
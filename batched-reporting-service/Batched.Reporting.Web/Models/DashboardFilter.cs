namespace Batched.Reporting.Web.Models
{
    /// <summary>
    /// Filter object for filter the API response based on Facilities, From date and To date.
    /// </summary>
    public class DashboardFilter
    {
        /// <summary>
        /// Assign default values
        /// </summary>
        public DashboardFilter()
        {
            Facilities = new List<string>();
        }

        /// <summary>
        /// Either facilities chosen from the filters or user assigned facilities.
        /// </summary>
        /// <example>["4233c3a8-c524-4a2f-88c2-5b177955baf6"]</example>
        public List<string> Facilities { get; set; }

        /// <summary>
        /// ValueStreams to be selected from the filters.
        /// </summary>
        /// <example>["cd63d911-1d72-4618-8d1f-5049fb610993"]</example>
        public List<string> ValueStreams { get; set; }

        /// <summary>
        /// Workcenters to be selected from the filters.
        /// </summary>
        /// <example>["8dbb8703-38c2-49f5-aa08-bc441e0fbb28"]</example>
        public List<string> Workcenters { get; set; }

        /// <summary>
        /// Equipments to be selected from the filters.
        /// </summary>
        /// <example>["03BBD2A1-3608-44D7-97D1-AADBE2CA2546"]</example>
        public List<string> Equipments { get; set; }

        /// <summary>
        /// Tickets to be selected from the filters.
        /// </summary>
        /// <example>["2DCA4FB7-8BBA-4F75-8BBA-983CBF3A626B"]</example>
        public List<string> Tickets { get; set; }

        /// <summary>
        /// From date to filter the data.
        /// </summary>
        /// <example>"2024-03-15T00:00:00"</example>
        public DateTime StartDate { get; set; }

        /// <summary>
        /// To date to filter the data.
        /// </summary>
        /// <example>"2024-10-15T00:00:00"</example>
        public DateTime EndDate { get; set; }

        /// <summary>
        /// To filter the date based on if ticket is scheduled or unscheduled.
        /// </summary>
        /// <example>"Scheduled"</example>
        public string ScheduleStatus { get; set; }
    }
}

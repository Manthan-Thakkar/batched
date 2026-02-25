namespace Batched.Reporting.Web.Models.StagingRequirement
{
    /// <summary>
    /// Next schedule run time wrt facilities and value streams.
    /// </summary>
    public class FacilityScheduledTime
    {
        /// <summary>
        /// Time for next scheduled run.
        /// </summary>
        /// <example>"2024-10-15T00:00:00"</example>
        public string NextScheduledTime { get; set; }

        /// <summary>
        /// Facilities for which, the next schedule will run.
        /// </summary>
        public List<ScheduledFacility> ScheduledFacilities { get; set; }
    }

    /// <summary>
    /// Facility object for which, the next schedule will run.
    /// </summary>
    public class ScheduledFacility
    {
        /// <summary>
        /// Id of the facility.
        /// </summary>
        /// <example>"4233c3a8-c524-4a2f-88c2-5b177955baf6"</example>
        public string FacilityId { get; set; }

        /// <summary>
        /// Name of the facility.
        /// </summary>
        /// <example>"Demo Facility"</example>
        public string FacilityName { get; set; }

        /// <summary>
        /// Timezone of the facility.
        /// </summary>
        /// <example>"Pacific Standard Time"</example>
        public string TimeZone { get; set; }

        /// <summary>
        /// Value streams associated with the facility.
        /// </summary>
        public List<DataDTO> ValueStreams { get; set; }

        /// <summary>
        /// Timespan in the local time of the facility.
        /// </summary>
        /// <example>"4233c3a8-c524-4a2f-88c2-5b177955baf6"</example>
        public TimeSpan FacilityTimeStamp { get; set; }

        /// <summary>
        /// Timespan in the UTC time.
        /// </summary>
        /// <example>"4233c3a8-c524-4a2f-88c2-5b177955baf6"</example>
        public TimeSpan UTCTimeStamp { get; set; }
    }
}

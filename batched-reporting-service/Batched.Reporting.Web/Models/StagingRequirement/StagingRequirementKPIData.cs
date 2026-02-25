namespace Batched.Reporting.Web.Models.StagingRequirement
{
    /// <summary>
    /// Response object for KPI.
    /// </summary>
    public class StagingRequirementKPIData
    {
        /// <summary>
        /// Count of distinct ticket tasks within selected time-range.
        /// </summary>
        /// <example>10</example>
        public int TotalTicketTasks { get; set; }

        /// <summary>
        /// Count of distinct Unstaged ticket tasks within 4 hrs from current time.
        /// </summary>
        /// <example>10</example>
        public int UrgentTicketTasks { get; set; }

        /// <summary>
        /// Count of distinct ticket tasks that have Unstaged ArtProofs requirement within selected time-range.
        /// </summary>
        /// <example>10</example>
        public int UnstagedArtProofs { get; set; }

        /// <summary>
        /// Count of distinct ticket tasks that have Unstaged Plates requirement within selected time-range.
        /// </summary>
        /// <example>10</example>
        public int UnstagedPlates { get; set; }

        /// <summary>
        /// Count of distinct ticket tasks that have Unstaged Inks requirement within selected time-range.
        /// </summary>
        /// <example>10</example>
        public int UnstagedInks { get; set; }

        /// <summary>
        /// Count of distinct ticket tasks that have Unstaged Cylinders requirement within selected time-range.
        /// </summary>
        /// <example>10</example>
        public int UnstagedCylinders { get; set; }

        /// <summary>
        /// Count of distinct ticket tasks that have Unstaged Tools requirement within selected time-range.
        /// </summary>
        /// <example>10</example>
        public int UnstagedTools { get; set; }

        /// <summary>
        /// Count of distinct ticket tasks that have Unstaged Substrates requirement within selected time-range.
        /// </summary>
        /// <example>10</example>
        public int UnstagedSubstrates { get; set; }

        /// <summary>
        /// Count of distinct ticket tasks that have Unstaged Cores requirement within selected time-range.
        /// </summary>
        /// <example>10</example>
        public int UnstagedCores { get; set; }

        /// <summary>
        /// Next schedule run time wrt facilities and value streams.
        /// </summary>
        public FacilityScheduledTime NextFacilityScheduledTime { get; set; }
    }
}
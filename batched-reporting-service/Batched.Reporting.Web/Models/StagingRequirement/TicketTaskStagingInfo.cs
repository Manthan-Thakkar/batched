namespace Batched.Reporting.Web.Models.StagingRequirement
{
    /// <summary>
    /// Resposne of fetching ticket task staging info
    /// </summary>
    public class TicketStagingInfo
    {
        /// <summary>
        /// Id of the Ticket.
        /// </summary>
        /// <example>"451B5F87-6B3A-4961-9C40-D9FE6964F68E"</example>

        public string TicketId { get; set; }

        /// <summary>
        /// Number of the Ticket.
        /// </summary>
        /// <example>"45879"</example>
        public string TicketNumber { get; set; }

        /// <summary>
        /// Task name of the Ticket.
        /// </summary>
        /// <example>"REWINDER"</example>
        public string TaskName { get; set; }

        /// <summary>
        /// Staging info of the Ticket.
        /// </summary>
        public List<StagingInfo> StagingInfo { get; set; }
    }

    /// <summary>
    /// Response of fetching staging info of the ticket.
    /// </summary>
    public class StagingInfo
    {
        /// <summary>
        /// Name of the staging requreiment.
        /// </summary>
        /// <example>"Cores"</example>
        public string StagingRequirement { get; set; }

        /// <summary>
        /// Staging status of the requirement.
        /// </summary>
        /// <example>True</example>
        public bool IsStaged { get; set; }

        /// <summary>
        /// Applicability of the requirement.
        /// </summary>
        /// <example>False</example>
        public bool IsRequirementApplicable { get; set; }

        /// <summary>
        /// Staging data - Ticket attribute values related to the requirement.
        /// </summary>
        public List<TicketAttributeValue> StagingData { get; set; }
    }
}
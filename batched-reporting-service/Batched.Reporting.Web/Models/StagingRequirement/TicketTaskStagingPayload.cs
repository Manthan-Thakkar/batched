namespace Batched.Reporting.Web.Models.StagingRequirement
{
    /// <summary>
    /// Payload to mark the Task as staged or unstaged.
    /// </summary>
    public class TicketTaskStagingPayload
    {
        /// <summary>
        /// Id of the Ticket.
        /// </summary>
        /// <example>["451B5F87-6B3A-4961-9C40-D9FE6964F68E"]</example>
        public string TicketId { get; set; }

        /// <summary>
        /// Task name of the Ticket.
        /// </summary>
        /// <example>["Equip"]</example>
        public string TaskName { get; set; }

        /// <summary>
        /// Report Name for the configurable view.
        /// </summary>
        /// <example>["451B5F87-6B3A-4961-9C40-D9FE6964F68E"]</example>
        public List<StagingComponent> StagingComponents { get; set; }  = new List<StagingComponent>(); 
    }

    /// <summary>
    /// Payload to fetch staging info of the ticket.
    /// </summary>
    public class TicketTaskStagingInfoPayload
    {
        /// <summary>
        /// Id of the Ticket.
        /// </summary>
        /// <example>"451B5F87-6B3A-4961-9C40-D9FE6964F68E"</example>
        public string TicketId { get; set; }

        /// <summary>
        /// Number of the Ticket.
        /// </summary>
        /// <example>"84472"</example>
        public string TicketNumber { get; set; }

        /// <summary>
        /// Task name of the Ticket.
        /// </summary>
        /// <example>"Equip"</example>
        public string TaskName { get; set; }
    }
}

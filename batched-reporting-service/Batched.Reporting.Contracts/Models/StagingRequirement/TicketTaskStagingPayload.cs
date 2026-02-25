namespace Batched.Reporting.Contracts.Models.StagingRequirement
{
    public class TicketTaskStagingPayload
    {
        public string TicketId { get; set; }
        public string TaskName { get; set; }
        public List<StagingComponent> StagingComponents { get; set; } = new List<StagingComponent>();
    }

    public class TicketTaskStagingInfoPayload
    {
        public string TicketId { get; set; }
        public string TicketNumber { get; set; }
        public string TaskName { get; set; }
    }
}

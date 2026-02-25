namespace Batched.Reporting.Contracts.Models.StagingRequirement
{
    public class TicketTaskStagingData
    {
        public string TicketId { get; set; }
        public string TicketNumber { get; set; }
        public string TaskName { get; set; }
        public List<StagingStatus> StagingStatus { get; set; }
        public string StagingReq { get; set; }
        public DateTime StartsAt { get; set; }
        public DateTime EndsAt { get; set; }
    }

    public class StagingStatus
    {
        public string StagingNameKey { get; set; }
        public bool? IsStaged { get; set; }
    }

    public class TicketLevelAttributeValues
    {
        public string TicketId { get; set; }
        public List<TicketAttributeValue> TicketAttributeValues { get; set; }
    }
}
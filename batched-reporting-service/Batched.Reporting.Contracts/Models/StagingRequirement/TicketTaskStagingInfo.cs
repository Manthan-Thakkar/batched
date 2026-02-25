namespace Batched.Reporting.Contracts.Models.StagingRequirement
{
    public class TicketStagingInfo
    {
        public string TicketId { get; set; }
        public string TicketNumber { get; set; }
        public string TaskName { get; set; }
        public List<StagingInfo> StagingInfo { get; set; }
    }

    public class StagingInfo
    {
        public string StagingRequirement { get; set; }
        public bool IsStaged { get; set; }
        public bool IsRequirementApplicable { get; set; }
        public List<TicketAttributeValue> StagingData { get; set; }
    }
}
namespace Batched.Reporting.Contracts.Models
{
    public class TicketsDemand
    {
        public string TicketId { get; set; }
        public string SourceTicketId { get; set; }
        public string FacilityId { get; set; }
        public string FacilityName { get; set; }
        public string ValueStreamId { get; set; }
        public string ValueStreamName { get; set; }
        public string WorkcenterId { get; set; }
        public string WorkcenterName { get; set; }
        public string EquipmentId { get; set; }
        public string EquipmentName { get; set; }
        public int UnplannedAllowance { get; set; }
        public int MinLeadTime { get; set; }
        public DateTime? ShipByDate { get; set; }
        public float EstTotalHours { get; set; }
    }
}

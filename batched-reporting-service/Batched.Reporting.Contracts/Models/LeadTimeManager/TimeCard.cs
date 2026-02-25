namespace Batched.Reporting.Contracts.Models.LeadTimeManager
{
    public class TimeCard
    {
        public string EquipmentId { get; set; }
        public string TicketId { get; set; }
        public string SourceTicketId { get; set;}
        public DateTime? StartDateTime { get; set; }
    }
}

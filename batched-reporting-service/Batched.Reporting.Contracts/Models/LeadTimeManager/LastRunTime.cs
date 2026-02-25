namespace Batched.Reporting.Contracts.Models.LeadTimeManager
{
    public class LastRunTime
    {
        public string LastRunEquipmentId { get; set; }
        public DateTime? MaxStartDateTime { get; set; }
    }
}

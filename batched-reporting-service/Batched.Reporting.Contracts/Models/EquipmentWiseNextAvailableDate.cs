namespace Batched.Reporting.Contracts.Models
{
    public class NextAvailableDateData
    {
        public List<TicketTaskCumulativeData> TicketTaskCumulativeData { get; set; } = new List<TicketTaskCumulativeData>();
        public DateTime? NextAvailableDate { get; set; }
        public int LeadTimeDays { get; set; }
        public int AvailabilityThreshold { get; set; }

    }

    public class EquipmentWiseNextAvailableDate : NextAvailableDateData
    {
        public string EquipmentId { get; set; }

    }

    public class WorkcenterWiseNextAvailableDate : NextAvailableDateData
    {
        public string WorkcenterId { get; set; }
        public List<string> equipments { get; set; } = new();

    }

    public class NextAvailableDateInfo
    {
        public List<EquipmentWiseNextAvailableDate> EquipmentWiseNextAvailableDate { get; set; } = new List<EquipmentWiseNextAvailableDate>();
        public List<WorkcenterWiseNextAvailableDate> WorkcenterWiseNextAvailableDate { get; set; } = new List<WorkcenterWiseNextAvailableDate>();
    }
    

    public class NextAvailableDateDto
    {
        public DateTime? NextAvailableDate { get; set; }
        public int LeadTimeDays { get; set; }
    }
}

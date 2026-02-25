namespace Batched.Reporting.Contracts.Models.LeadTimeManager
{
    public class CapacityOutlookData
    {
        public string EquipmentId { get; set; }
        public string SourceEquipmentId { get; set; }
        public DateTime TheDate { get; set; }
        public DateTime? DowntimeStart { get; set; }
        public DateTime? DowntimeEnd { get; set; }
        public float DowntimeHours { get; set; }
        public float CapacityHours { get; set; }
        public string FacilityId { get; set; }
        public int UnplannedAllowance { get; set; }
        public float UnplannedAllowanceHours { get; set; }
        public float UnstaffedHours { get; set; }
        public float TicketDemand { get; set; }
        public float TotalDemand { get; set; }
        public float ReservedDemand { get; set; }
        public float AvailableCapacityHours { get; set; }
        public float CumulativeTotalDemand { get; set; }
        public float CumulativeAvailableCapacityHours { get; set; }
        public bool IsHoliday { get; set; }
        public int HolidayHours { get; set; }
        public float UnavailableCapacityHours { get; set; }

    }
    public class EquipmentCapacityOutlook : CapacityOutlookData
    {
        public TimeSpan? ShiftStart { get; set; }
        public TimeSpan? ShiftEnd { get; set; }
    }

    public class DailyEquipmentCapacityOutlook : CapacityOutlookData
    {
        public List<ShiftTime> ShiftTimes { get; set; } = new List<ShiftTime>();
    }

    public class ShiftTime
    {
        public TimeSpan? ShiftStartTime { get; set; }
        public TimeSpan? ShiftEndTime { get; set; }   
    }

}

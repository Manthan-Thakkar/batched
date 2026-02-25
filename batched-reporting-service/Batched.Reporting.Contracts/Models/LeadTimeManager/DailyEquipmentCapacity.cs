namespace Batched.Reporting.Contracts.Models.LeadTimeManager
{
    public class DailyEquipmentCapacity
    {
        public string EquipmentId { get; set; }
        public string WorkcenterId { get; set; }
        public int UnplannedAllowance { get; set; }
        public float UnplannedAllowanceHours { get; set; }
        public int AvailabilityThreshold { get; set; }
        public DateTime TheDate { get; set; }
        public string FacilityId { get; set; }
        public float TotalCapacityHours { get; set; }
        public int InternalLeadTime { get; set; }
        public float ActualCapacityHours { get; set; }
        public float DemandHours { get; set; }
        public TimeSpan? ShiftStart { get; set; }
        public TimeSpan? ShiftEnd { get; set; } 
        public DateTime? DowntimeStart { get; set; }
        public DateTime? DowntimeEnd { get; set; }
        public float DowntimeHours { get; set; }
        public bool IsHoliday { get; set; }
    }

}

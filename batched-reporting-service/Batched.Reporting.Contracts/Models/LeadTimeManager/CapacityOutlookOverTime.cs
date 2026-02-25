namespace Batched.Reporting.Contracts.Models.LeadTimeManager
{
    public class CapacityOutlookOverTime
    {
        public DateTime Date { get; set; }
        public float TotalDemand { get; set; }
        public float TicketDemand { get; set; }
        public float ReservedDemand { get; set; }
        public float TotalCapacity { get; set; }
        public float UnavailableCapacity { get; set; }
        public float UnstaffedHours { get; set; }
        public float DowntimeHours { get; set; }
        public float HolidayHours { get; set; }
        public float UnplannedAllowance { get; set; }
        public float AvailableCapacityHours { get; set; }
        public float TotalCumulativeAvailableCapacity { get; set; }
    }
}

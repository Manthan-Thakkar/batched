namespace Batched.Reporting.Contracts
{
    public class LeadTimeManagerKpi
    {
        public int TotalTickets { get; set; }
        public float Reservations { get; set; }
        public int DowntimeHours { get; set; }
        public float AvailableCapacity { get; set; }
        public int ActualLeadTimeDays { get; set; }
        public int ExternalLeadTimeDays { get; set; }
        public DateTime? NextAvailableDate { get; set; }
        public DateTime? ExternalNextAvailableDate { get; set; }
    }
}

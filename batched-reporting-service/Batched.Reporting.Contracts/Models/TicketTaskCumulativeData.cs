namespace Batched.Reporting.Contracts.Models
{
    public class TicketTaskCumulativeData
    {
        public DateTime? TheDate { get; set; }
        public float DemandHours { get; set; }
        public float CapacityHours { get; set; }
        public float RunningDemand { get; set; }
        public float RunningCapacity { get; set; }
        public bool IsAvailable { get; set; }
    }
}

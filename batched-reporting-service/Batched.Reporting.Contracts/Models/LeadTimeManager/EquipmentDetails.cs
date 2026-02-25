namespace Batched.Reporting.Contracts
{
    public class EquipmentDetails
    {
        public string FacilityId { get; set; }
        public string FacilityName { get; set; }
        public string ValueStreamId { get; set; }
        public string ValueStreamName { get; set; }
        public string WorkcenterId { get; set; }
        public string WorkcenterName { get; set; }
        public string EquipmentId { get; set; }
        public string EquipmentName { get; set; }
        public int MinLeadTime { get; set; }
        public DateTime? ExternalNextAvailableDate { get; set; }
    }

    public class DailyEquipmentCapaityOverview : EquipmentDetails
    {
        public int AvailabilityThreshold { get; set; }
        public DateTime TheDate { get; set; }
        public float TotalCapacityHours { get; set; }
        public float ActualCapacityHours { get; set; }
        public float TotalDemandHours { get; set; }
        public float TotalAvailableCapacity { get; set; }
        public bool IsAvailable { get; set; }
    }

}


namespace Batched.Reporting.Contracts
{
    public class CapacityOverview
    {
        public string Id { get; set; }
        public string Name { get; set; }
        public string Type { get; set; }
        public List<CapacityOverviewData> CapacityOverviewData { get; set; }
        public List<CapacityOverview> DownStreamOverview { get; set; } = new List<CapacityOverview>();
    }
    public class CapacityOverviewData
    {
        public DateTime TheDate { get; set; }
        public float AvailableCapacity { get; set; }
        public float TotalCapacity { get; set; }
        public int AvailabilityThreshold { get; set; }
        public float TotalDemandHours { get; set; }
        public bool IsAvailable { get; set; }
    }

    public class CapacityOverviewResponse
    {
        public List<CapacityOverview> CapacityOverviews { get; set; } = new List<CapacityOverview>();

    }
}
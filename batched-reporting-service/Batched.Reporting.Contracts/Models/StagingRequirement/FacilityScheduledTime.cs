namespace Batched.Reporting.Contracts.Models.StagingRequirement
{
    public class FacilityScheduledTime
    {
        public string NextScheduledTime { get; set; }
        public List<ScheduledFacility> ScheduledFacilities { get; set; }
    }

    public class ScheduledFacility
    {
        public string FacilityId { get; set; }
        public string FacilityName { get; set; }
        public string TimeZone { get; set; }
        public string ValueStreamName { get; set; }
        public string ValueStreamId { get; set; }
        public TimeSpan FacilityTimeStamp { get; set; }
        public TimeSpan UTCTimeStamp { get; set; }
    }
}

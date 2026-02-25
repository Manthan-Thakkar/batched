namespace Batched.Reporting.Web.Models.StagingRequirement
{
    public class StagingRequirementData
    {
        public List<ScheduledTasksStagingData> ScheduledTasksStagingData { get; set; } = new List<ScheduledTasksStagingData>();
        public int TotalCount { get; set; }
    }
}

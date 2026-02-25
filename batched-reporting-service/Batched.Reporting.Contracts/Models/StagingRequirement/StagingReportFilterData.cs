namespace Batched.Reporting.Contracts.Models.StagingRequirement
{
    public class StagingReportFilterData : FilterData
    {
        public StagingReportFilterData()
        {
            Tickets = new();
            StagingRequirements = new();
        }

        public List<string> Tickets { get; set; }
        public List<DataDTO> StagingRequirements { get; set; }
        public new List<DataDTO> ValueStreams { get; set; }
    }
}
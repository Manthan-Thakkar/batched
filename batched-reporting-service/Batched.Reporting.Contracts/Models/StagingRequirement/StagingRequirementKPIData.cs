namespace Batched.Reporting.Contracts.Models.StagingRequirement
{
    public class StagingRequirementKPIData
    {
        public int TotalTicketTasks { get; set; }
        public int UrgentTicketTasks { get; set; }
        public int UnstagedArtProofs { get; set; }
        public int UnstagedPlates { get; set; }
        public int UnstagedInks { get; set; }
        public int UnstagedCylinders { get; set; }
        public int UnstagedTools { get; set; }
        public int UnstagedSubstrates { get; set; }
        public int UnstagedCores { get; set; }
        public FacilityScheduledTime NextFacilityScheduledTime { get; set; }
    }
}
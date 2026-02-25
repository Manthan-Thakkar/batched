namespace Batched.Reporting.Contracts.Models.StagingRequirement;

public class StagingRequirementFilterDataPayload
{
    public List<string> UserAssignedFacilities { get; set; }
    public DateTime? StartDate { get; set; }
    public DateTime? EndDate { get; set; }
}
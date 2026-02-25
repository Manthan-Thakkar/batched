using Batched.Reporting.Contracts.Models;

namespace Batched.Reporting.Web.Models.StagingRequirement
{
    /// <summary>
    /// Response object for staging requirements components
    /// </summary>
    public class StagingRequirementComponents
    {
        /// <summary>
        /// The object of Status representing status of the export process.
        /// </summary>
        public Status Status { get; set; } = new();

        /// <summary>
        /// Staging requirements data
        /// </summary>
        public List<StagingRequirements> StagingRequirements { get; set; }
    }

    /// <summary>
    /// Response object for staging requirements
    /// </summary>
    public class StagingRequirements
    {
        /// <summary>
        /// The object of Status representing status of the export process.
        /// </summary>
        /// <example>["4233c3a8-c524-4a2f-88c2-5b177955baf6"]</example>
        public string StagingRequirementId { get; set; }

        /// <summary>
        /// The object of Status representing status of the export process.
        /// </summary>
        /// <example>["Plates"]</example>
        public string StagingRequirementName { get; set; }
    }
}
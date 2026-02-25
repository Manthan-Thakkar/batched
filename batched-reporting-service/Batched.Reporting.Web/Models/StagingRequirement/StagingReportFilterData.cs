namespace Batched.Reporting.Web.Models.StagingRequirement
{
    /// <summary>
    /// Filter data response consisting of Facility, Workcenter, Equipment, ValueStreams, Tickets and Staging Requirements fields in given date range and assigned facilities.
    /// </summary>
    public class StagingReportFilterData
    {
        /// <summary>
        /// Id of the facility associated with the equipment.
        /// </summary>
        /// <example>"4233c3a8-c524-4a2f-88c2-5b177955baf6"</example>
        public string FacilityId { get; set; }

        /// <summary>
        /// Name of the facility associated with the equipment.
        /// </summary>
        /// <example>"Demo Facility"</example>
        public string FacilityName { get; set; }

        /// <summary>
        /// Id of the workcenter associated with the equipment.
        /// </summary>
        /// <example>"4233c3a8-c524-4a2f-88c2-5b177955baf6"</example>
        public string WorkcenterId { get; set; }

        /// <summary>
        /// Name of the workcenter associated with the equipment.
        /// </summary>
        /// <example>"Rewinder"</example>
        public string WorkcenterName { get; set; }

        /// <summary>
        /// Id of the equipment.
        /// </summary>
        /// <example>"4233c3a8-c524-4a2f-88c2-5b177955baf6"</example>
        public string EquipmentId { get; set; }

        /// <summary>
        /// Name of the equipment.
        /// </summary>
        /// <example>"12B"</example>
        public string EquipmentName { get; set; }

        /// <summary>
        /// Tickets associated with the equipment.
        /// </summary>
        /// <example>["15111103", "15111213"]</example>
        public List<string> Tickets { get; set; }

        /// <summary>
        /// Value streams associated with the equipment.
        /// </summary>
        public List<DataDTO> ValueStreams { get; set; }

        /// <summary>
        /// Staging Requirements associated with the equipment.
        /// </summary>
        public List<DataDTO> StagingRequirements { get; set; }
    }
}
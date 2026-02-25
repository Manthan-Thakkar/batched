using Batched.Reporting.Web.Models.StagingRequirement;

namespace Batched.Reporting.Web.Models.Export
{
    /// <summary>
    /// Export Request object for exporting staging requirement report.
    /// </summary>
    public class ExportStagingRequirementReportRequest
    {
        /// <summary>
        /// Filter object for filtering the data by Facilities, ValueStreams, Workcenters, Equipments, Tickets, ScheduleStatus, StartDate & EndDate.
        /// </summary>
        public StagingRequirementReportFilter Filters { get; set; }

        /// <summary>
        /// Metadata object which consists of fields FileFormat, FileName, RequiredColumns and EntityName
        /// </summary>
        public ExportMetadata ExportMetadata { get; set; }
    }
}
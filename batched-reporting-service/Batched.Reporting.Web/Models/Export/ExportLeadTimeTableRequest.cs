using Batched.Reporting.Web.Models.LeadTimeManager;

namespace Batched.Reporting.Web.Models.Export
{
    /// <summary>
    /// Export Request object for exporting tables on Lead Time Manager dashboard.
    /// </summary>
    public class ExportLeadTimeTableRequest
    {
        /// <summary>
        /// Filter object for filtering the data by Facilities, ValueStreams, Workcenters, Equipments, Tickets, ScheduleStatus, StartDate & EndDate.
        /// </summary>
        public LeadTimeManagerFilters Filters { get; set; }

        /// <summary>
        /// Metadata object which consists of fields FileFormat, FileName, RequiredColumns and EntityName
        /// </summary>
        public ExportMetadata ExportMetadata { get; set; }
    }
}
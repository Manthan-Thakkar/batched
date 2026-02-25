namespace Batched.Reporting.Web.Models.Export
{
    /// <summary>
    /// Metadata for a file, containing information about its format, name, required columns, and entity name.
    /// </summary>
    public class ExportMetadata
    {
        /// <summary>
        /// The format of the file.
        /// </summary>
        /// <example>"PDF"</example>
        public string FileFormat { get; set; }

        /// <summary>
        /// The name of the file.
        /// </summary>
        /// <example>"OpenTickets_19_Apr_2024"</example>
        public string FileName { get; set; }

        /// <summary>
        /// List of required columns in the file.
        /// </summary>
        /// <example>["ticketNumber", "taskName", "workcenterName"]</example>
        public List<string> RequiredColumns { get; set; }

        /// <summary>
        /// The name of entity (table/report) to export
        /// </summary>
        /// <example>"OpenTickets"</example>
        public string EntityName { get; set; }
    }
}
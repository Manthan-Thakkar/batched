using Batched.Reporting.Contracts.Models;

namespace Batched.Reporting.Web.Models.Export
{
    /// <summary>
    /// Represents response data for exporting.
    /// </summary>
    public class ExportData
    {
        /// <summary>
        /// The object of Status representing status of the export process.
        /// </summary>
        public Status Status { get; set; } = new();

        /// <summary>
        /// The URL where the exported file can be accessed.
        /// </summary>
        public string Url { get; set; } = string.Empty;
    }
}
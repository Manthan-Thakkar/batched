using Batched.Reporting.Contracts.Models.Export;

namespace Batched.Reporting.Web.Translators
{
    /// <summary>
    /// Trasnslator for Export object.
    /// </summary>
    public static class ExportTranslator
    {
        /// <summary>
        /// Trasnslator for Export request object for Lead Time Manager tables.
        /// </summary>
        public static ExportLeadTimeTableRequest Translate(this Models.Export.ExportLeadTimeTableRequest filter)
        {
            if (filter == null)
                return null;

            return new ExportLeadTimeTableRequest
            {
                Filters = filter.Filters.Translate(),
                ExportMetadata = filter.ExportMetadata.Translate()
            };
        }

        /// <summary>
        /// Trasnslator for Export request object for Staging Requirement report.
        /// </summary>
        public static ExportStagingRequirementReportRequest Translate(this Models.Export.ExportStagingRequirementReportRequest filter)
        {
            if (filter == null)
                return null;

            return new ExportStagingRequirementReportRequest
            {
                Filters = filter.Filters.Translate(),
                ExportMetadata = filter.ExportMetadata.Translate()
            };
        }

        private static ExportMetadata Translate(this Models.Export.ExportMetadata metadata)
        {
            if (metadata == null)
                return null;

            return new ExportMetadata
            {
                EntityName = metadata.EntityName,
                FileFormat = metadata.FileFormat,
                FileName = metadata.FileName,
                RequiredColumns = metadata.RequiredColumns
            };
        }

        /// <summary>
        /// Trasnslator for Export response object.
        /// </summary>
        public static Models.Export.ExportData Translate(this ExportData response)
        {
            if (response == null)
                return null;

            return new Models.Export.ExportData
            {
                Status = response.Status,
                Url = response.Url,
            };
        }
    }
}
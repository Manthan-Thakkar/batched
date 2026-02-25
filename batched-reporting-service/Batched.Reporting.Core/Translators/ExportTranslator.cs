using Batched.Common;
using Batched.Reporting.Contracts;
using Batched.Reporting.Contracts.Models;
using Batched.Reporting.Contracts.Models.Export;
using Batched.Reporting.Contracts.Models.LeadTimeManager;
using Batched.Reporting.Contracts.Models.StagingRequirement;
using Batched.Reporting.Shared.Helper;
using static Batched.Reporting.Shared.BatchedConstants;

namespace Batched.Reporting.Core.Translators
{
    public static class ExportTranslator
    {
        public static List<List<string>> ConvertToExportableTemplate(this List<dynamic> reportData, List<ReportViewField> columns, List<string> requiredColumns)
        {
            List<List<string>> responseList = new();

            using (Tracer.Benchmark("get-converted-staging-data"))
            {
                var filteredColumns = columns.Where(x => x.Type == "Table" &&
                                        (!requiredColumns.Any() || requiredColumns.Contains(x.JsonName)))?.OrderBy(x => x.Sequence);

                responseList.Add(filteredColumns.Select(x => string.IsNullOrEmpty(x.DisplayName) ? x.FieldName : x.DisplayName).ToList());

                foreach (var row in reportData)
                {
                    List<string> dataRow = new();

                    foreach (var col in filteredColumns)
                    {
                        var dataValue = ((IDictionary<string, object>)row)[col.JsonName];
                        dataRow.Add(dataValue == null ? string.Empty : dataValue.ToString());
                    }

                    responseList.Add(dataRow);
                }
            }

            return responseList;
        }

        public static List<List<string>> ConvertToExportableTemplate(this List<CapacitySummary> data, List<ExportTableColumns> columns, List<string> requiredColumns)
        {
            List<List<string>> responseList = new();

            using (Tracer.Benchmark("get-capacity-summary-data"))
            {
                List<string> staticColumns = new() { "facility", "valueStream", "workcenter", "equipment" };

                var filteredColumns = requiredColumns.Count == 0
                    ? columns
                    : columns.Where(x => staticColumns.Contains(x.FieldName) || requiredColumns.Contains(x.FieldName)).ToList();

                responseList.Add(filteredColumns.Select(x => string.IsNullOrEmpty(x.DisplayName) ? x.FieldName : x.DisplayName).ToList());

                List<CapacitySummaryFlatData> flatData = data.Flatten();

                foreach (var row in flatData)
                {
                    var dataRow = new List<string>();

                    foreach (var col in filteredColumns)
                    {
                        var mappedPair = new ExportCapacitySummaryDataPropertyMapper(row).First(x => x.Key.ToLower().Equals(col.FieldName.ToLower()));

                        var fieldValue = mappedPair.Equals(default(KeyValuePair<string, object>)) || mappedPair.Value == null
                                        ? string.Empty
                                        : mappedPair.Value.ToString();

                        dataRow.Add(fieldValue);
                    }

                    responseList.Add(dataRow);
                }
            }

            return responseList;
        }

        public static List<List<string>> ConvertToExportableTemplate(this List<LeadTimeException> data, List<ExportTableColumns> columns, List<string> requiredColumns)
        {
            List<List<string>> responseList = new();

            using (Tracer.Benchmark("get-converted-lead-time-exceptions-data"))
            {
                var filteredColumns = requiredColumns.Count == 0 ? columns : columns.Where(x => requiredColumns.Contains(x.FieldName)).ToList();

                responseList.Add(filteredColumns.Select(x => string.IsNullOrEmpty(x.DisplayName) ? x.FieldName : x.DisplayName).ToList());

                foreach (var row in data)
                {
                    var dataRow = new List<string>();

                    foreach (var col in filteredColumns)
                    {
                        var mappedPair = new ExportLeadTimeExceptionsDataPropertyMapper(row).First(x => x.Key.ToLower().Equals(col.FieldName.ToLower()));

                        var fieldValue = mappedPair.Equals(default(KeyValuePair<string, object>)) || mappedPair.Value == null
                                        ? string.Empty
                                        : mappedPair.Value.ToString();

                        dataRow.Add(fieldValue);
                    }

                    responseList.Add(dataRow);
                }
            }

            return responseList;
        }

        public static List<List<string>> ConvertToExportableTemplate(this List<ScheduledTasksStagingData> data, List<ReportViewField> columns, List<string> requiredColumns)
        {
            List<List<string>> responseList = new();

            using (Tracer.Benchmark("get-converted-staging-data"))
            {
                var filteredColumns = columns.Where(x => x.Type == "Table"
                                         && (requiredColumns.Count == 0 || requiredColumns.Contains(x.FieldName)))?.OrderBy(x => x.Sequence).ToList();

                for (int i = 0; i < filteredColumns.Count; i++)
                {
                    if (filteredColumns[i].Category == FieldCategory.StagingComponent)
                    {
                        var statusColumn = new ReportViewField()
                        {
                            Id = string.Empty,
                            ReportViewId = filteredColumns[i].ReportViewId,
                            FieldName = filteredColumns[i].FieldName,
                            DisplayName = (string.IsNullOrEmpty(filteredColumns[i].DisplayName) ? filteredColumns[i].FieldName : filteredColumns[i].DisplayName).GetStagingNameKey(),
                            JsonName = filteredColumns[i].JsonName,
                            Type = filteredColumns[i].Type,
                            Category = FieldCategory.ExportStagingStatus,
                            IsDefault = false,
                            Sequence = filteredColumns[i].Sequence + 1,
                            SortField = string.Empty,
                            Action = null
                        };

                        filteredColumns.Insert((i + 1), statusColumn);
                        i++;
                    }
                }

                responseList.Add(filteredColumns.Select(x => string.IsNullOrEmpty(x.DisplayName) ? x.FieldName : x.DisplayName).ToList());

                foreach (var row in data)
                {
                    var dataRow = new List<string>();

                    foreach (var col in filteredColumns)
                    {
                        var fieldValue = row.GetStagingFieldValue(col);
                        dataRow.Add(fieldValue != null ? fieldValue.ToString() : string.Empty);
                    }

                    responseList.Add(dataRow);
                }
            }

            return responseList;
        }


        public static Common.Export.FileMetadata Translate(this ExportMetadata metadata)
        {
            return new Common.Export.FileMetadata()
            {
                FileFormat = metadata.FileFormat,
                FileName = metadata.FileName
            };
        }

        private static object GetStagingFieldValue(this ScheduledTasksStagingData dataRow, ReportViewField column)
        {
            switch (column.Category)
            {
                case FieldCategory.Ticket:
                    return new ScheduledTasksStagingDataPropertyMapper(dataRow).First(x => x.Key.Equals(column.FieldName)).Value;

                case FieldCategory.TicketAttribute:
                    return dataRow.TicketAttribute?.Find(x => x.Name == column.FieldName)?.Value;

                case FieldCategory.StagingComponent:
                    return dataRow.StagingComponents?.Find(x => x.Name == column.FieldName)?.Value;

                case FieldCategory.ExportStagingStatus:
                    return dataRow.StagingComponents?.Find(x => x.Name == column.FieldName)?.IsStaged;

                default:
                    return null;
            }
        }
    }
}
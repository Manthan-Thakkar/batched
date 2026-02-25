using Batched.Reporting.Shared;
using Batched.Reporting.Web.Models;
using ContractModels = Batched.Reporting.Contracts.Models;

namespace Batched.Reporting.Web.Translators
{
    public static class ReportViewFieldTranslator
    {
        public static List<ReportViewField> Translate(this List<ContractModels.ReportViewField> reportViewFields)
        {
            if (reportViewFields.IsNullOrEmpty())
                return new();

            return reportViewFields.Select(reportViewField => new ReportViewField
            {
                Action = reportViewField.Action,
                Category = reportViewField.Category,
                DisplayName = reportViewField.DisplayName,
                FieldName = reportViewField.FieldName,
                Id = reportViewField.Id,
                IsDefault = reportViewField.IsDefault,
                JsonName = reportViewField.JsonName,
                ReportViewId = reportViewField.ReportViewId,
                Sequence = reportViewField.Sequence,
                SortField = reportViewField.SortField,
                Type = reportViewField.Type
            }).ToList();
        }
    }
}
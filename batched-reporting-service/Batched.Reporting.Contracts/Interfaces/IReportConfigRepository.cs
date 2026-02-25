using Batched.Reporting.Contracts.Models;

namespace Batched.Reporting.Contracts.Interfaces
{
    public interface IReportConfigRepository
    {
        Task<List<ReportViewField>> GetReportFields(string viewId, string reportName);
    }
}

using Batched.Reporting.Contracts.Models.LeadTimeManager;
using CommonModels = Batched.Common.Data.Tenants.Sql.Models;

namespace Batched.Reporting.Contracts
{
    public interface ILeadTimeExceptionsRepository
    {
        Task<List<LeadTimeException>> GetLeadTimeExceptionsAsync(CancellationToken cancellationToken);
        Task<CommonModels.LeadTimeException> GetLeadTimeExceptionByIdAsync(string exceptionId, CancellationToken cancellationToken);
        Task<List<CommonModels.LeadTimeException>> GetLeadTimeExceptionsByNameAsync(string exceptionName, CancellationToken cancellationToken);
        Task AddLeadTimeExceptionAsync(CommonModels.LeadTimeException exception);
        Task EditLeadTimeExceptionAsync(EditExceptionRequest exception);
        Task DeleteLeadTimeExceptionAsync(string exceptionId);
    }
}
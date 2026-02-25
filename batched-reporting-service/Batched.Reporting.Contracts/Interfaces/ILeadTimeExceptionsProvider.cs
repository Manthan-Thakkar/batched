using Batched.Reporting.Contracts.Models.LeadTimeManager;

namespace Batched.Reporting.Contracts
{
    public interface ILeadTimeExceptionsProvider
    {
        Task<GetExceptionsResponse> GetLeadTimeExceptionsAsync(CancellationToken cancellationToken);
        Task<AddExceptionsResponse> AddLeadTimeExceptionAsync(AddExceptionRequest exception, CancellationToken cancellationToken);
        Task<ExceptionResponse> EditLeadTimeExceptionAsync(EditExceptionRequest exception, CancellationToken cancellationToken);
        Task<ExceptionResponse> DeleteLeadTimeExceptionAsync(string exceptionId, CancellationToken cancellationToken);
    }
}
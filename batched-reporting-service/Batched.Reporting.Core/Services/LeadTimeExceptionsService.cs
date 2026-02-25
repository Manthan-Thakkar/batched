using Batched.Reporting.Contracts;
using Batched.Reporting.Contracts.Models.LeadTimeManager;

namespace Batched.Reporting.Core.Core
{
    public class LeadTimeExceptionsService : ILeadTimeExceptionsService
    {
        private readonly ILeadTimeExceptionsProvider _leadTimeExceptionsProvider;

        public LeadTimeExceptionsService(ILeadTimeExceptionsProvider leadTimeExceptionsProvider)
        {
            _leadTimeExceptionsProvider = leadTimeExceptionsProvider;
        }

        public async Task<GetExceptionsResponse> GetLeadTimeExceptionsAsync(CancellationToken cancellationToken)
        {
            return await _leadTimeExceptionsProvider.GetLeadTimeExceptionsAsync(cancellationToken);
        }

        public async Task<AddExceptionsResponse> AddLeadTimeExceptionAsync(AddExceptionRequest exception, CancellationToken cancellationToken)
        {
            return await _leadTimeExceptionsProvider.AddLeadTimeExceptionAsync(exception, cancellationToken);
        }

        public async Task<ExceptionResponse> EditLeadTimeExceptionAsync(EditExceptionRequest exception, CancellationToken cancellationToken)
        {
            return await _leadTimeExceptionsProvider.EditLeadTimeExceptionAsync(exception, cancellationToken);
        }

        public async Task<ExceptionResponse> DeleteLeadTimeExceptionAsync(string exceptionId, CancellationToken cancellationToken)
        {
            return await _leadTimeExceptionsProvider.DeleteLeadTimeExceptionAsync(exceptionId, cancellationToken);
        }
    }
}
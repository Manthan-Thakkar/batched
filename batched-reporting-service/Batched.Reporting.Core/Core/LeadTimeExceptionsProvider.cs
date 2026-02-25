using Batched.Reporting.Contracts;
using Batched.Reporting.Contracts.Errormap;
using Batched.Reporting.Contracts.Models;
using Batched.Reporting.Contracts.Models.LeadTimeManager;
using Batched.Reporting.Core.Translators;
using Batched.Reporting.Shared;

namespace Batched.Reporting.Core.Core
{
    public class LeadTimeExceptionsProvider : ILeadTimeExceptionsProvider
    {
        private readonly ILeadTimeExceptionsRepository _leadTimeExceptionsRepository;

        public LeadTimeExceptionsProvider(ILeadTimeExceptionsRepository leadTimeExceptionsRepository)
        {
            _leadTimeExceptionsRepository = leadTimeExceptionsRepository;
        }

        public async Task<GetExceptionsResponse> GetLeadTimeExceptionsAsync(CancellationToken cancellationToken)
        {
            var exceptions = await _leadTimeExceptionsRepository.GetLeadTimeExceptionsAsync(cancellationToken);
            return new GetExceptionsResponse
            {
                Exceptions = exceptions,
                Status = new Status()
            };
        }

        public async Task<AddExceptionsResponse> AddLeadTimeExceptionAsync(AddExceptionRequest exception, CancellationToken cancellationToken)
        {
            var expt = exception.Translate();
            await _leadTimeExceptionsRepository.AddLeadTimeExceptionAsync(expt);

            return new AddExceptionsResponse
            {
                ExceptionId = expt.Id,
                Status = new Status
                {
                    Code = "200",
                    Error = false,
                    Message = "Lead time exception added successfully.",
                    Type = "success"
                }
            };
        }

        public async Task<ExceptionResponse> EditLeadTimeExceptionAsync(EditExceptionRequest exception, CancellationToken cancellationToken)
        {
            await _leadTimeExceptionsRepository.EditLeadTimeExceptionAsync(exception);

            return new ExceptionResponse
            {
                Status = new Status
                {
                    Code = "200",
                    Error = false,
                    Message = "Lead time exception updated successfully.",
                    Type = "success"
                }
            };
        }

        public async Task<ExceptionResponse> DeleteLeadTimeExceptionAsync(string exceptionId, CancellationToken cancellationToken)
        {
            await _leadTimeExceptionsRepository.DeleteLeadTimeExceptionAsync(exceptionId);

            return new ExceptionResponse
            {
                Status = new Status
                {
                    Code = "200",
                    Error = false,
                    Message = "Lead time exception deleted successfully.",
                    Type = "success"
                }
            };
        }
    }
}
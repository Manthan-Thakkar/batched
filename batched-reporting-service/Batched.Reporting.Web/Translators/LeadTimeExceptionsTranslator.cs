using ContractModels = Batched.Reporting.Contracts.Models.LeadTimeManager;
using WebModels = Batched.Reporting.Web.Models.LeadTimeException;

namespace Batched.Reporting.Web.Translators
{
    /// <summary>
    /// Trasnslator for Lead Time Exception request and response objects.
    /// </summary>
    public static class LeadTimeExceptionsTranslator
    {
        /// <summary>
        /// Trasnslator for request object of AddExceptionRequest.
        /// </summary>
        public static ContractModels.AddExceptionRequest Translate(this WebModels.AddExceptionRequest request)
        {
            return new ContractModels.AddExceptionRequest
            {
                Name = request.Name,
                Reason = request.Reason,
                ReportedBy = request.ReportedBy,
                LeadTimeInDays = request.LeadTimeInDays
            };
        }

        /// <summary>
        /// Trasnslator for request object of EditExceptionRequest.
        /// </summary>
        public static ContractModels.EditExceptionRequest Translate(this WebModels.EditExceptionRequest request)
        {
            return new ContractModels.EditExceptionRequest
            {
                Id = request.Id,
                Name = request.Name,
                Reason = request.Reason,
                LeadTimeInDays = request.LeadTimeInDays
            };
        }

        /// <summary>
        /// Trasnslator for response object of GetExceptionsResponse.
        /// </summary>
        public static WebModels.GetExceptionsResponse Translate(this ContractModels.GetExceptionsResponse response)
        {
            if (response == null)
                return null;

            return new WebModels.GetExceptionsResponse
            {
                Exceptions = response.Exceptions.Translate(),
                Status = response.Status
            };
        }

        /// <summary>
        /// Trasnslator for response object of AddExceptionsResponse.
        /// </summary>
        public static WebModels.AddExceptionsResponse Translate(this ContractModels.AddExceptionsResponse response)
        {
            if (response == null)
                return null;

            return new WebModels.AddExceptionsResponse
            {
                ExceptionId = response.ExceptionId,
                Status = response.Status
            };
        }

        /// <summary>
        /// Trasnslator for response object of CommonExceptionsResponse.
        /// </summary>
        public static WebModels.ExceptionResponse Translate(this ContractModels.ExceptionResponse response)
        {
            if (response == null)
                return null;

            return new WebModels.ExceptionResponse
            {
                Status = response.Status
            };
        }

        private static List<WebModels.LeadTimeException> Translate(this List<ContractModels.LeadTimeException> exceptions)
        {
            if (exceptions == null)
                return null;

            List<WebModels.LeadTimeException> resposne = new();

            foreach (var expt in exceptions)
            {
                resposne.Add(new WebModels.LeadTimeException
                {
                    Id = expt.Id,
                    LeadTimeInDays = expt.LeadTimeInDays,
                    Name = expt.Name,
                    Reason = expt.Reason,
                    ReportedBy = expt.ReportedBy
                });
            }

            return resposne;
        }
    }
}
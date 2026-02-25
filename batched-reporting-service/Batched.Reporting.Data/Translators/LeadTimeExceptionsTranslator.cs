using Batched.Reporting.Contracts.Models.LeadTimeManager;
using Batched.Reporting.Shared;
using CommonModels = Batched.Common.Data.Tenants.Sql.Models;

namespace Batched.Reporting.Data.Translators
{
    public static class LeadTimeExceptionsTranslator
    {
        public static List<LeadTimeException> Translate(this List<CommonModels.LeadTimeException> exceptions)
        {
            if (exceptions.IsNullOrEmpty())
                return new List<LeadTimeException>();

            List<LeadTimeException> exceptionsList = new();

            foreach (var exception in exceptions)
                exceptionsList.Add(exception.Translate());

            return exceptionsList;
        }

        public static LeadTimeException Translate(this CommonModels.LeadTimeException exception)
        {
            if (exception == null)
                return null;

            return new LeadTimeException
            {
                Id = exception.Id,
                Name = exception.Name,
                Reason = exception.Reason,
                ReportedBy = exception.ModifiedBy,
                LeadTimeInDays = exception.LeadTimeInDays
            };
        }
    }
}
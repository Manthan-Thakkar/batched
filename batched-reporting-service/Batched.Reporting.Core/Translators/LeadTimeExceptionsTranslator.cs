using Batched.Reporting.Contracts.Models.LeadTimeManager;
using CommonModels = Batched.Common.Data.Tenants.Sql.Models;

namespace Batched.Reporting.Core.Translators
{
    public static class LeadTimeExceptionsTranslator
    {
        public static CommonModels.LeadTimeException Translate(this AddExceptionRequest exception)
        {
            return new CommonModels.LeadTimeException
            {
                Id = Guid.NewGuid().ToString(),
                Name = exception.Name,
                Reason = exception.Reason,
                LeadTimeInDays = exception.LeadTimeInDays,
                CreatedBy = exception.ReportedBy,
                ModifiedBy = exception.ReportedBy,
                CreatedOnUtc = DateTime.UtcNow,
                ModifiedOnUtc = DateTime.UtcNow
            };
        }
    }
}
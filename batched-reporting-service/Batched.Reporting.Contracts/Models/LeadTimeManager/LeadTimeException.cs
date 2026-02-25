using System.Collections;

namespace Batched.Reporting.Contracts.Models.LeadTimeManager
{
    public class LeadTimeException
    {
        public string Id { get; set; }
        public string Name { get; set; }
        public string Reason { get; set; }
        public string ReportedBy { get; set; }
        public int LeadTimeInDays { get; set; }
    }
    public class ExportLeadTimeExceptionsDataPropertyMapper : IEnumerable<KeyValuePair<string, object>>
    {
        private readonly LeadTimeException _exceptionData;
        public ExportLeadTimeExceptionsDataPropertyMapper(LeadTimeException exceptionData)
        {
            _exceptionData = exceptionData;
        }

        public IEnumerator<KeyValuePair<string, object>> GetEnumerator()
        {
            yield return new KeyValuePair<string, object>(nameof(LeadTimeException.Name), _exceptionData.Name);
            yield return new KeyValuePair<string, object>(nameof(LeadTimeException.Reason), _exceptionData.Reason);
            yield return new KeyValuePair<string, object>(nameof(LeadTimeException.ReportedBy), _exceptionData.ReportedBy);
            yield return new KeyValuePair<string, object>(nameof(LeadTimeException.LeadTimeInDays), _exceptionData.LeadTimeInDays);
        }

        IEnumerator IEnumerable.GetEnumerator()
        {
            return GetEnumerator();
        }
    }
}
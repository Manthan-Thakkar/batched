using Batched.Reporting.Contracts.Models;

namespace Batched.Reporting.Contracts
{
    public class ConfigurableViewField
    {
        public List<ReportViewField> Columns { get; set; }
        public bool NoViewFound { get; set; }
    }
}

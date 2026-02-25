using Batched.Common;
using Batched.Reporting.Contracts.Interfaces;
using Batched.Reporting.Contracts;

namespace Batched.Reporting.Core.Core
{
    public class ConfigurableViewsProvider : IConfigurableViewsProvider
    {
        private readonly IObjectProvider _objectProvider;

        public ConfigurableViewsProvider(IObjectProvider objectProvider)
        {
            _objectProvider = objectProvider;
        }

        public async Task<ConfigurableViewField> GetConfigurableViewFieldsAsync(string viewId, string reportName, CancellationToken cancellationToken)
        {
            var reportConfigRepository = _objectProvider.GetInstance<IReportConfigRepository>("cache");
            var reportFields = await reportConfigRepository.GetReportFields(viewId, reportName);

            ConfigurableViewField configurableViewFields = new() { Columns = reportFields, NoViewFound = reportFields == null || reportFields.Count == 0 };

            return configurableViewFields;
        }


    }
}

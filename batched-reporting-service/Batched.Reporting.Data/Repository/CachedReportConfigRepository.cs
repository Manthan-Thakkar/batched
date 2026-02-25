using Batched.Common;
using Batched.Reporting.Contracts.Interfaces;
using Batched.Reporting.Contracts.Models;
using Batched.Reporting.Shared;

namespace Batched.Reporting.Data.Repository
{
    public class CachedReportConfigRepository : IReportConfigRepository
    {
        private readonly ICache _cache;
        private readonly IReportConfigRepository _reportConfigRepository;

        public CachedReportConfigRepository(ICache cache, IReportConfigRepository reportConfigRepository)
        {
            _cache = cache;
            _reportConfigRepository = reportConfigRepository;
        }

        public async Task<List<ReportViewField>> GetReportFields(string viewId, string reportName)
        {
            using (Tracer.Benchmark($"cache-get-reportFields"))
            {
                if (!string.IsNullOrEmpty(viewId))
                {
                    var tenantId = ApplicationContext.Current.TenantId;
                    var reportFieldCacheKey = $"ConfigurableView_Fields_{tenantId}_{viewId}";

                    var reportViewFields = await _cache.GetAsync<List<ReportViewField>>(reportFieldCacheKey, null, CancellationToken.None, false);

                    if (reportViewFields.IsNullOrEmpty())
                    {
                        AppLogger.Log("cache miss", LogFields.Create.Add("cache-key", reportFieldCacheKey));
                        reportViewFields = await _reportConfigRepository.GetReportFields(viewId, reportName);
                        if (!reportViewFields.IsNullOrEmpty())
                        {
                            await _cache.SetAsync(reportFieldCacheKey, reportViewFields, null, new TimeSpan(0, 15, 0), CancellationToken.None, false);
                        }
                    }
                    return reportViewFields;
                }
                else
                {
                    return await _reportConfigRepository.GetReportFields(viewId, reportName);
                }
            }
        }
    }
}

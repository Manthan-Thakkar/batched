using Batched.Common;
using Batched.Reporting.Contracts;
using Batched.Reporting.Shared;

namespace Batched.Reporting.Data.Repository
{
    public class CachedEquipmentRepository : ICachedEquipmentRepository
    {
        private readonly IEquipmentRepository _equipmentRepository;
        private readonly ICache _cache;

        public CachedEquipmentRepository(IEquipmentRepository equipmentRepository, ICache cache)
        {
            _equipmentRepository = equipmentRepository;
            _cache = cache;
        }

        public async Task<List<FilterData>> GetFilterDataAsync(DashboardFilter filter, CancellationToken cancellationToken)
        {
            var tenantId = ApplicationContext.Current.TenantId;
            var cacheKey = GetKey(tenantId);
            using (Tracer.Benchmark("cached-equipment-repo-filter-data"))
            {
                List<FilterData> allFacilitiesData = await _cache.GetAsync<List<FilterData>>(cacheKey, cancellationToken: cancellationToken, appendAppName: false);
                if (allFacilitiesData == null)
                {
                    allFacilitiesData = await _equipmentRepository.GetFilterDataAsync(new() { Facilities = new() }, cancellationToken);
                    await _cache.SetAsync(cacheKey, allFacilitiesData, cancellationToken: cancellationToken, appendAppName: false, expiresIn: new TimeSpan(0, 15, 0));
                }
                var filterData = allFacilitiesData.Where(f => filter.Facilities.Count == 0 || filter.Facilities.Contains(f.FacilityId)).ToList();
                return filterData;
            }
        }

        private static string GetKey(string tenantId) => $"leadtime-filter-data-{tenantId}";
    }
}

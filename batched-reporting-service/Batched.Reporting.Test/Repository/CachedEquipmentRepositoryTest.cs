using Batched.Common;
using Batched.Reporting.Contracts;
using Batched.Reporting.Data.Repository;
using Batched.Reporting.Shared;
using Moq;
using Xunit;

namespace Batched.Reporting.Test.Repository
{
    public class CachedEquipmentRepositoryTest : BaseTest<CachedEquipmentRepository>
    {
        private readonly Mock<IEquipmentRepository> _equipmentRepository;
        private readonly Mock<ICache> _cache;

        public CachedEquipmentRepositoryTest() : base(typeof(IEquipmentRepository), typeof(ICache))
        {
            _cache = new Mock<ICache>();
            _equipmentRepository = new Mock<IEquipmentRepository>();
        }

        [Fact]
        public async Task GetFilterDataAsync_ShouldFetchDataFromCache()
        {
            using (new AmbientContextScope(new ApplicationContext("", "", "Tenant1", "", null, null)))
            {
                var filterData = new List<FilterData>
                {
                    new()
                    {
                        EquipmentId = "equipmentId1",
                        EquipmentName = "equipmentName1",
                        FacilityId = "facilityId1",
                        FacilityName = "facilityName1",
                        WorkcenterId = "workcenterId1",
                        WorkcenterName = "workcenterName1",
                    },
                    new()
                    {
                        EquipmentId = "equipmentId2",
                        EquipmentName = "equipmentName2",
                        FacilityId = "facilityId2",
                        FacilityName = "facilityName2",
                        WorkcenterId = "workcenterId2",
                        WorkcenterName = "workcenterName2",
                    }
                };
                _cache
                    .Setup(t => t.GetAsync<List<FilterData>>(It.IsAny<string>(), null, It.IsAny<CancellationToken>(), false))
                    .ReturnsAsync(filterData);

                var cachedEquipmentRepo = new CachedEquipmentRepository(_equipmentRepository.Object, _cache.Object);

                var filterDataResponse = await cachedEquipmentRepo.GetFilterDataAsync(new() { Facilities = new ()}, MockedCToken());

                Assert.NotNull(filterDataResponse);
                Assert.NotEmpty(filterDataResponse);
                Assert.Equal(filterData.Count, filterDataResponse.Count);

                _equipmentRepository.Verify(x => x.GetFilterDataAsync(It.IsAny<DashboardFilter>(), MockedCToken()), Times.Never());
                _cache.Verify(_ => _.GetAsync<List<FilterData>>(It.IsAny<string>(), null, It.IsAny<CancellationToken>(), false), Times.Once);
            }
        }

        [Fact]
        public async Task GetFilterDataAsync_ShouldFetchDataFromCache_FilteredByFacilities()
        {
            var facilityId = "facilityId2";
            using (new AmbientContextScope(new ApplicationContext("", "", "Tenant1", "", null, null)))
            {
                var filterData = new List<FilterData>
                {
                    new()
                    {
                        EquipmentId = "equipmentId1",
                        EquipmentName = "equipmentName1",
                        FacilityId = "facilityId1",
                        FacilityName = "facilityName1",
                        WorkcenterId = "workcenterId1",
                        WorkcenterName = "workcenterName1",
                    },
                    new()
                    {
                        EquipmentId = "equipmentId2",
                        EquipmentName = "equipmentName2",
                        FacilityId = "facilityId2",
                        FacilityName = "facilityName2",
                        WorkcenterId = "workcenterId2",
                        WorkcenterName = "workcenterName2",
                    }
                };
                _cache
                    .Setup(t => t.GetAsync<List<FilterData>>(It.IsAny<string>(), null, It.IsAny<CancellationToken>(), false))
                    .ReturnsAsync(filterData);

                var cachedEquipmentRepo = new CachedEquipmentRepository(_equipmentRepository.Object, _cache.Object);

                var filterDataResponse = await cachedEquipmentRepo.GetFilterDataAsync(new() { Facilities = new() { facilityId } }, MockedCToken());

                Assert.NotNull(filterDataResponse);
                Assert.NotEmpty(filterDataResponse);
                Assert.Contains(filterDataResponse, f => f.FacilityId == facilityId);
                Assert.Equal(filterData.Count(_ => _.FacilityId == facilityId), filterDataResponse.Count(_ => _.FacilityId == facilityId));

                _equipmentRepository.Verify(x => x.GetFilterDataAsync(It.IsAny<DashboardFilter>(), MockedCToken()), Times.Never());
                _cache.Verify(_ => _.GetAsync<List<FilterData>>(It.IsAny<string>(), null, It.IsAny<CancellationToken>(), false), Times.Once);
            }
        }

        [Fact]
        public async Task GetFilterDataAsync_ShouldFetchDataFromDatabase()
        {
            using (new AmbientContextScope(new ApplicationContext("", "", "Tenant1", "", null, null)))
            {
                List<FilterData> cachedFilterData = null;
                var filterData = new List<FilterData>
                {
                    new()
                    {
                        EquipmentId = "equipmentId1",
                        EquipmentName = "equipmentName1",
                        FacilityId = "facilityId1",
                        FacilityName = "facilityName1",
                        WorkcenterId = "workcenterId1",
                        WorkcenterName = "workcenterName1",
                    },
                    new()
                    {
                        EquipmentId = "equipmentId2",
                        EquipmentName = "equipmentName2",
                        FacilityId = "facilityId2",
                        FacilityName = "facilityName2",
                        WorkcenterId = "workcenterId2",
                        WorkcenterName = "workcenterName2",
                    }
                };
                _cache
                    .Setup(t => t.GetAsync<List<FilterData>>(It.IsAny<string>(), null, It.IsAny<CancellationToken>(), false))
                    .ReturnsAsync(cachedFilterData);
                _cache
                    .Setup(_ => _.SetAsync<List<FilterData>>(It.IsAny<string>(), It.IsAny<List<FilterData>>(), null, It.IsAny<TimeSpan>(), MockedCToken(), false));

                _equipmentRepository
                    .Setup(_ => _.GetFilterDataAsync(It.IsAny<DashboardFilter>(), MockedCToken()))
                    .ReturnsAsync(filterData);

                var cachedEquipmentRepo = new CachedEquipmentRepository(_equipmentRepository.Object, _cache.Object);

                var filterDataResponse = await cachedEquipmentRepo.GetFilterDataAsync(new() { Facilities = new() }, MockedCToken());

                Assert.NotNull(filterDataResponse);
                Assert.NotEmpty(filterDataResponse);
                Assert.Equal(filterData.Count, filterDataResponse.Count);

                _equipmentRepository.Verify(_ => _.GetFilterDataAsync(It.IsAny<DashboardFilter>(), MockedCToken()), Times.Once());

                _cache.Verify(_ => _.GetAsync<List<FilterData>>(It.IsAny<string>(), null, MockedCToken(), false), Times.Once);
                _cache.Verify(_ => _.SetAsync<List<FilterData>>(It.IsAny<string>(), It.IsAny<List<FilterData>>(), null, It.IsAny<TimeSpan>(), MockedCToken(), false), Times.Once);
            }
        }
    }
}

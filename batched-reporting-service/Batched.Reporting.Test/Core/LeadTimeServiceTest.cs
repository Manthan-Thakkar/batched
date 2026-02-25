using Batched.Reporting.Contracts;
using Batched.Reporting.Core;
using Moq;
using Xunit;

namespace Batched.Reporting.Test.Core
{
    public class LeadTimeServiceTest : BaseTest<LeadTimeReportService>
    {
        private readonly Mock<ILeadTimeProvider> _leadTimeProvider;

        public LeadTimeServiceTest() : base(typeof(ILeadTimeProvider))
        {
            _leadTimeProvider = new Mock<ILeadTimeProvider>();
        }

        [Fact]
        public async Task GetFilterDataAsync_ShouldSuccess()
        {
            _leadTimeProvider
                .Setup(_ => _.GetFilterDataAsync(It.IsAny<DashboardFilter>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(new List<LeadTimeDashboardFilter>());

            var leadTimeService = new LeadTimeReportService(_leadTimeProvider.Object);
            
            var filterData = await leadTimeService.GetFilterDataAsync(new DashboardFilter(), CancellationToken.None);

            Assert.NotNull(filterData);
            Assert.Empty(filterData);
        }

        [Fact]
        public async Task GetKpiAsync_ShouldSuccess()
        {
            _leadTimeProvider
                .Setup(_ => _.GetKpiAsync(It.IsAny<DashboardFilter>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(new LeadTimeManagerKpi());

            var leadTimeService = new LeadTimeReportService(_leadTimeProvider.Object);

            var kpiData = await leadTimeService.GetKpiAsync(new DashboardFilter(), CancellationToken.None);

            Assert.NotNull(kpiData);
        }

        [Fact]
        public async Task GetCapacitySummaryAsync_ShouldSuccess()
        {
            _leadTimeProvider
                .Setup(_ => _.GetCapacitySummaryAsync(It.IsAny<DashboardFilter>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(new List<CapacitySummary>());

            var leadTimeService = new LeadTimeReportService(_leadTimeProvider.Object);

            var capacitySummary = await leadTimeService.GetCapacitySummaryAsync(new DashboardFilter(), CancellationToken.None);
            Assert.NotNull(capacitySummary);
        }

        [Fact]
        public async Task GetCapacityOutlookAsync_ShouldSuccess()
        {
            _leadTimeProvider
                .Setup(_ => _.GetCapacityOutlookOverTimeAsync(It.IsAny<DashboardFilter>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(new Contracts.Models.LeadTimeManager.CapacityOutlookOverTimeResponse());

            var leadTimeService = new LeadTimeReportService(_leadTimeProvider.Object);

            var capacityOutlook = await leadTimeService.GetCapacityOutlookOverTimeAsync(new DashboardFilter(), CancellationToken.None);
            Assert.NotNull(capacityOutlook);
        }

        [Fact]
        public async Task GetCapacityOverviewAsync_ShouldSuccess()
        {
            _leadTimeProvider
                .Setup(_ => _.GetCapacityOverviewsAsync(It.IsAny<DashboardFilter>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(new List<CapacityOverview>());

            var leadTimeService = new LeadTimeReportService(_leadTimeProvider.Object);

            var capacityOverview = await leadTimeService.GetCapacityOverviewAsync(new DashboardFilter(), CancellationToken.None);
            Assert.NotNull(capacityOverview);
        }
    }
}

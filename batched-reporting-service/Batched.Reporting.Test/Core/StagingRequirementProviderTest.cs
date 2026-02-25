using CommonModels = Batched.Common.Data.Tenants.Sql.Models;
using Batched.Reporting.Contracts;
using Batched.Reporting.Contracts.Interfaces;
using Batched.Reporting.Contracts.Models.StagingRequirement;
using Batched.Reporting.Core.Core;
using Moq;
using Xunit;
using Batched.Common;
using Batched.Reporting.Shared;
using Batched.Reporting.Test.MockedEntities;
using static Batched.Reporting.Shared.BatchedConstants;
using Batched.Reporting.Contracts.Models;

namespace Batched.Reporting.Test.Core
{
    public class StagingRequirementProviderTest : BaseTest<StagingRequirementProvider>
    {
        private readonly Mock<IEquipmentRepository> _equipmentRepository;
        private readonly Mock<IStagingRequirementRepository> _stagingRequirementRepository;
        private readonly Mock<Common.Interfaces.IScheduleEventRepository> _scheduleEventRepository;
        private readonly Mock<ITenantRepository> _tenantRepository;
        private readonly Mock<IConfigurableViewsProvider> _configurableViewsProvider;

        public StagingRequirementProviderTest() : base(
            typeof(IEquipmentRepository),
            typeof(IStagingRequirementRepository),
            typeof(Common.Interfaces.IScheduleEventRepository),
            typeof(ITenantRepository),
            typeof(IConfigurableViewsProvider)
            )
        {
            _equipmentRepository = new Mock<IEquipmentRepository>();
            _stagingRequirementRepository = new Mock<IStagingRequirementRepository>();
            _scheduleEventRepository = new Mock<Common.Interfaces.IScheduleEventRepository>();
            _tenantRepository = new Mock<ITenantRepository>();
            _configurableViewsProvider = new Mock<IConfigurableViewsProvider>();
        }


        [Fact]
        public async Task GetFilterDataAsync_ShouldReturn_FilterData()
        {
            _equipmentRepository
                .Setup(_ => _.GetEquipmentWiseStagingTicketsAysnc(It.IsAny<StagingRequirementFilterDataPayload>(), MockedCToken()))
                .ReturnsAsync(MockedEquipmentsData.GetEquipmentWiseTickets());

            _equipmentRepository
                .Setup(_ => _.GetStagingFilterDataAsync(It.IsAny<StagingRequirementFilterDataPayload>(), MockedCToken()))
                .ReturnsAsync(MockedEquipmentsData.GetStagingFilterData());

            var stagingRequirementProvider = new StagingRequirementProvider(_equipmentRepository.Object, _stagingRequirementRepository.Object, _scheduleEventRepository.Object, _tenantRepository.Object, _configurableViewsProvider.Object);
            var response = await stagingRequirementProvider.GetFilterDataAsync(new StagingRequirementFilterDataPayload(), CancellationToken.None);

            Assert.NotNull(response);
            Assert.Equal(13, response.Count);
            Assert.Equal(6, response[5].Tickets.Count);
            Assert.Equal(2, response[6].StagingRequirements.Count);
            Assert.Single(response.First().ValueStreams);
        }


        [Fact]
        public async Task GetKPIDataAsync_ShouldReturn_KPIData()
        {
            _stagingRequirementRepository
                .Setup(_ => _.GetTicketTaskStagingInfoAsync(It.IsAny<StagingRequirementFilter>(), MockedCToken()))
                .ReturnsAsync(new List<TicketTaskStagingData>());

            _scheduleEventRepository
                .Setup(_ => _.GetNextScheduleRunTimeAsync(It.IsAny<string>(), It.IsAny<List<string>>(), MockedCToken()))
                .ReturnsAsync(new CommonModels.FacilityScheduledTime());

            var stagingRequirementProvider = new StagingRequirementProvider(_equipmentRepository.Object, _stagingRequirementRepository.Object, _scheduleEventRepository.Object, _tenantRepository.Object, _configurableViewsProvider.Object);

            using (new AmbientContextScope(new ApplicationContext("", "", "Tenant1", "", null, null)))
            {
                var response = await stagingRequirementProvider.GetKPIDataAsync(new StagingRequirementFilter(), CancellationToken.None);
                Assert.NotNull(response);
            }
        }


        [Fact]
        public async Task GetStagingRequirementReportAsync_ShouldReturn_ReportData()
        {
            var ticketAttributeColumns = new List<ReportViewField> { new ReportViewField { Id = "id1", Category = "TicketAttribute", FieldName = "Stock1Number" } };
            _configurableViewsProvider
                .Setup(_ => _.GetConfigurableViewFieldsAsync(It.IsAny<string>(), It.IsAny<string>(), MockedCToken()))
                .ReturnsAsync(new ConfigurableViewField()
                {
                    Columns = ticketAttributeColumns
                });

            _tenantRepository
                .Setup(_ => _.GetTenantCurrentTimeAsync(It.IsAny<string>(), MockedCToken()))
                .ReturnsAsync(DateTime.Now);

            _stagingRequirementRepository
                .Setup(_ => _.GetAllStagingRequirementsAsync())
                .ReturnsAsync(new List<StagingRequirements>());

            _stagingRequirementRepository
                .Setup(_ => _.GetStagingRequirementDataAsync(It.IsAny<StagingRequirementReportFilter>(), It.IsAny<List<string>>(), It.IsAny<DateTime>(), It.IsAny<List<StagingRequirements>>(), It.IsAny<List<string>>(), MockedCToken()))
                .ReturnsAsync(new StagingRequirementData());

            var defaultAttributes = ticketAttributeColumns.Select(x => x.FieldName).ToList();
            defaultAttributes.AddRange(StagingRequirementReportConstant.StagingRequirementAttributes.SelectMany(x => x.Value.Select(x => x).ToList()).ToList());
            defaultAttributes.AddRange(StagingRequirementReportConstant.StagingRequirementInfoAttributes.SelectMany(x => x.Value.Select(x => x).ToList()).ToList());
            var finalAttributes = defaultAttributes.Distinct().ToList();

            var stagingRequirementProvider = new StagingRequirementProvider(_equipmentRepository.Object, _stagingRequirementRepository.Object, _scheduleEventRepository.Object, _tenantRepository.Object, _configurableViewsProvider.Object);

            using (new AmbientContextScope(new ApplicationContext("", "", "Tenant1", "", null, null)))
            {
                var response = await stagingRequirementProvider.GetStagingRequirementReportAsync(new StagingRequirementReportFilter(), CancellationToken.None);

                _stagingRequirementRepository.Verify(_ => _.GetStagingRequirementDataAsync(It.IsAny<StagingRequirementReportFilter>(),
                    It.Is<List<string>>(ta => ta.All(t => finalAttributes.Contains(t))),
                    It.IsAny<DateTime>(), It.IsAny<List<StagingRequirements>>(), It.IsAny<List<string>>(), MockedCToken()), Times.Once);

                Assert.NotNull(response);
            }
        }


        [Fact]
        public async Task UpdateTicketTaskStagingStateAsync_ShouldReturn_KPIData()
        {
            _configurableViewsProvider
                .Setup(_ => _.GetConfigurableViewFieldsAsync(It.IsAny<string>(), It.IsAny<string>(), MockedCToken()))
                .ReturnsAsync(new ConfigurableViewField()
                {
                    Columns = new List<ReportViewField> { new ReportViewField { Id = "id1", Category = "TicketAttribute", FieldName = "Substrates" } }
                });

            _tenantRepository
                .Setup(_ => _.GetTenantCurrentTimeAsync(It.IsAny<string>(), MockedCToken()))
                .ReturnsAsync(DateTime.Now);

            _stagingRequirementRepository
                .Setup(_ => _.GetAllStagingRequirementsAsync())
                .ReturnsAsync(new List<StagingRequirements>());

            _stagingRequirementRepository
                .Setup(_ => _.GetStagingRequirementDataAsync(It.IsAny<StagingRequirementReportFilter>(), It.IsAny<List<string>>(), It.IsAny<DateTime>(), It.IsAny<List<StagingRequirements>>(), It.IsAny<List<string>>(), MockedCToken()))
                .ReturnsAsync(new StagingRequirementData());

            var stagingRequirementProvider = new StagingRequirementProvider(_equipmentRepository.Object, _stagingRequirementRepository.Object, _scheduleEventRepository.Object, _tenantRepository.Object, _configurableViewsProvider.Object);

            using (new AmbientContextScope(new ApplicationContext("", "", "Tenant1", "", null, null)))
            {
                var response = await stagingRequirementProvider.GetStagingRequirementReportAsync(new StagingRequirementReportFilter(), CancellationToken.None);
                Assert.NotNull(response);
            }
        }
    }
}
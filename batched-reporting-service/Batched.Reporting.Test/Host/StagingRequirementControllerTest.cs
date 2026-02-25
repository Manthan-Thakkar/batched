using Batched.Reporting.Contracts.Interfaces;
using Batched.Reporting.Contracts.Models.StagingRequirement;
using WebModels = Batched.Reporting.Web.Models.StagingRequirement;
using Batched.Reporting.Web.Controllers;
using Moq;
using Xunit;
using Batched.Reporting.Test.MockedEntities.StagingRequirement;
using Microsoft.AspNetCore.Mvc;

namespace Batched.Reporting.Test.Host
{
    public class StagingRequirementControllerTest : BaseTest<StagingRequirementController>
    {
        private readonly Mock<IStagingRequirementService> _stagingRequirementService;
        private readonly Mock<IExportService> _exportService;

        public StagingRequirementControllerTest() : base(typeof(IStagingRequirementService), typeof(IExportService))
        {
            _stagingRequirementService = new Mock<IStagingRequirementService>(MockBehavior.Strict);
            _exportService = new Mock<IExportService>(MockBehavior.Strict);
        }


        [Fact]
        public async Task GetFilterDataAsync_ShouldReturn_FilterData()
        {
            _stagingRequirementService
                .Setup(_ => _.GetFilterDataAsync(It.IsAny<StagingRequirementFilterDataPayload>(), MockedCToken()))
                .ReturnsAsync(MockedStagingRequirement.GetStagingRequirementFilterData());

            var controller = new StagingRequirementController(_stagingRequirementService.Object, _exportService.Object);
            var response = await controller.GetFilterDataAsync(It.IsAny<WebModels.StagingRequirementFilterDataPayload>(), MockedCToken());

            Assert.NotNull(response);

            var okResponse = Assert.IsType<OkObjectResult>(response);
            var responseItems = Assert.IsType<List<WebModels.StagingReportFilterData>>(okResponse.Value);
            
            Assert.Equal(13, responseItems.Count);
            Assert.Equal(24, responseItems.First().Tickets.Count);
            Assert.Equal(2, responseItems[6].StagingRequirements.Count);
            Assert.Equal(2, responseItems[7].ValueStreams.Count);
        }


        [Fact]
        public async Task GetKPIDataAsync_ShouldReturn_KPIData()
        {
            _stagingRequirementService
                .Setup(_ => _.GetKPIDataAsync(It.IsAny<StagingRequirementFilter>(), MockedCToken()))
                .ReturnsAsync(new StagingRequirementKPIData());

            var controller = new StagingRequirementController(_stagingRequirementService.Object, _exportService.Object);
            var response = await controller.GetKPIDataAsync(It.IsAny<WebModels.StagingRequirementFilter>(), MockedCToken());

            Assert.NotNull(response);
        }

        [Fact]
        public async Task GetStagingRequirementReportDataAsync_ShouldReturn_StagingRequirementData()
        {
            _stagingRequirementService
                .Setup(_ => _.GetStagingRequirementReportAsync(It.IsAny<StagingRequirementReportFilter>(), MockedCToken()))
                .ReturnsAsync(new StagingRequirementData());

            var controller = new StagingRequirementController(_stagingRequirementService.Object, _exportService.Object);
            var response = await controller.GetStagingRequirementReportDataAsync(It.IsAny<WebModels.StagingRequirementReportFilter>(), MockedCToken());

            Assert.NotNull(response);
        }


        [Fact]
        public async Task UpdateTicketTaskStagingStateAsync_Should_Succeed()
        {
            _stagingRequirementService
                .Setup(_ => _.UpdateTicketTaskStagingStateAsync(It.IsAny<List<TicketTaskStagingPayload>>(), MockedCToken()))
                .Returns(Task.CompletedTask);

            var controller = new StagingRequirementController(_stagingRequirementService.Object, _exportService.Object);
            var response = await controller.UpdateTicketTaskStagingStateAsync(new List<WebModels.TicketTaskStagingPayload>(), MockedCToken());

            Assert.NotNull(response);
        }
    }
}
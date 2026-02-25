using Batched.Reporting.Contracts;
using Batched.Reporting.Contracts.Errormap;
using Batched.Reporting.Contracts.Interfaces;
using Batched.Reporting.Contracts.Models.LeadTimeManager;
using Batched.Reporting.Web.Controllers;
using Moq;
using Xunit;

namespace Batched.Reporting.Test.Host
{
    public class LeadTimeDashboardControllerTest : BaseTest<LeadTimeDashboardController>
    {
        private readonly Mock<ILeadTimeService> _leadtimeService;
        private readonly Mock<ILeadTimeExceptionsService> _leadtimeExceptionsService;
        private readonly Mock<IExportService> _exportService;

        public LeadTimeDashboardControllerTest() : base(typeof(ILeadTimeService), typeof(ILeadTimeExceptionsService), typeof(IExportService))
        {
            _leadtimeService = new Mock<ILeadTimeService>(MockBehavior.Strict);
            _leadtimeExceptionsService = new Mock<ILeadTimeExceptionsService>(MockBehavior.Strict);
            _exportService = new Mock<IExportService>(MockBehavior.Strict);
        }

        [Fact]
        public async Task GetFilterDataAsync_Success()
        {
            var filterData = GetFilterData();
            _leadtimeService
                .Setup(_ => _.GetFilterDataAsync(It.IsAny<DashboardFilter>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(new List<LeadTimeDashboardFilter> { filterData });

            var controller = new LeadTimeDashboardController(_leadtimeService.Object, _leadtimeExceptionsService.Object, _exportService.Object);

            var response = await controller.GetFilterDataAsync(new(), CancellationToken.None);

            Assert.NotNull(response);
            Assert.Equal(2, filterData.Tickets.Count);
        }

        [Fact]
        public async Task GetFilterDataAsync_ThrowsException()
        {
            var exceptionMsg = "DashboardFilter is null";
            var filterData = GetFilterData();
            _leadtimeService
                .Setup(_ => _.GetFilterDataAsync(It.IsAny<DashboardFilter>(), It.IsAny<CancellationToken>()))
                .ThrowsAsync(new ArgumentException(exceptionMsg));

            var controller = new LeadTimeDashboardController(_leadtimeService.Object, _leadtimeExceptionsService.Object, _exportService.Object);

            async Task asyncAct() { await controller.GetFilterDataAsync(new(), CancellationToken.None); }

            var exception = await Assert.ThrowsAsync<ArgumentException>(asyncAct);

            Assert.NotNull(exception);
            Assert.Equal(exceptionMsg, exception.Message);
        }


        [Fact]
        public async Task GetKpi_Success()
        {
            var filterData = GetFilterData();
            _leadtimeService
                .Setup(_ => _.GetKpiAsync(It.IsAny<DashboardFilter>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(new LeadTimeManagerKpi
                {
                    ActualLeadTimeDays = 1,
                    ExternalLeadTimeDays = 1,
                    NextAvailableDate = DateTime.Now,
                    TotalTickets = 15,
                    DowntimeHours = 0,
                    ExternalNextAvailableDate = DateTime.Now,
                });

            var controller = new LeadTimeDashboardController(_leadtimeService.Object, _leadtimeExceptionsService.Object, _exportService.Object);
            var response = await controller.LeadTimeManagerKpi(new(), CancellationToken.None);
            Assert.NotNull(response);
        }

        [Fact]
        public async Task GetKpi_ThrowsException()
        {
            var exceptionMsg = "DashboardFilter is null";

            _leadtimeService
                .Setup(_ => _.GetKpiAsync(It.IsAny<DashboardFilter>(), It.IsAny<CancellationToken>()))
                .ThrowsAsync(new ArgumentException(exceptionMsg));

            var controller = new LeadTimeDashboardController(_leadtimeService.Object, _leadtimeExceptionsService.Object, _exportService.Object);

            async Task asyncAct() { await controller.LeadTimeManagerKpi(new(), CancellationToken.None); }

            var exception = await Assert.ThrowsAsync<ArgumentException>(asyncAct);

            Assert.NotNull(exception);
            Assert.Equal(exceptionMsg, exception.Message);
        }


        [Fact]
        public async Task GetOpenTicketDetails_Success()
        {
            _leadtimeService
                .Setup(_ => _.GetOpenTicketsLTMAsync(It.IsAny<LeadTimeManagerFilters>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(new OpenTicketDetailsResponse
                {
                    OpenTickets = new()
                });

            var controller = new LeadTimeDashboardController(_leadtimeService.Object, _leadtimeExceptionsService.Object, _exportService.Object);
            var response = await controller.OpenTicketDetailsAsync(new(), CancellationToken.None);
            Assert.NotNull(response);
        }

        [Fact]
        public async Task GetOpenTicketDetails_ThrowsException()
        {
            var exceptionMsg = "DashboardFilter is null";

            _leadtimeService
                .Setup(_ => _.GetOpenTicketsLTMAsync(It.IsAny<LeadTimeManagerFilters>(), It.IsAny<CancellationToken>()))
                .ThrowsAsync(new ArgumentException(exceptionMsg));

            var controller = new LeadTimeDashboardController(_leadtimeService.Object, _leadtimeExceptionsService.Object, _exportService.Object);

            async Task asyncAct() { await controller.OpenTicketDetailsAsync(new(), CancellationToken.None); }

            var exception = await Assert.ThrowsAsync<ArgumentException>(asyncAct);

            Assert.NotNull(exception);
            Assert.Equal(exceptionMsg, exception.Message);
        }


        [Fact]
        public async Task GetLeadTimeExceptions_Success()
        {
            _leadtimeExceptionsService
                .Setup(_ => _.GetLeadTimeExceptionsAsync(It.IsAny<CancellationToken>()))
                .ReturnsAsync(new GetExceptionsResponse());

            var controller = new LeadTimeDashboardController(_leadtimeService.Object, _leadtimeExceptionsService.Object, _exportService.Object);
            var response = await controller.GetLeadTimeExceptionsAsync(CancellationToken.None);

            Assert.NotNull(response);
        }


        [Fact]
        public async Task AddLeadTimeExceptions_Success()
        {
            _leadtimeExceptionsService
                .Setup(_ => _.AddLeadTimeExceptionAsync(It.IsAny<AddExceptionRequest>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(new AddExceptionsResponse());

            var controller = new LeadTimeDashboardController(_leadtimeService.Object, _leadtimeExceptionsService.Object, _exportService.Object);
            var response = await controller.AddLeadTimeExceptionAsync(new(), CancellationToken.None);

            Assert.NotNull(response);
        }

        [Fact]
        public async Task AddLeadTimeExceptions_ThrowsException_DuplicateExceptionName()
        {
            _leadtimeExceptionsService
                .Setup(_ => _.AddLeadTimeExceptionAsync(It.IsAny<AddExceptionRequest>(), It.IsAny<CancellationToken>()))
                .ThrowsAsync(new BadRequestException(ErrorCodes.DuplicateLeadTimeExceptionName, ErrorMessages.DuplicateLeadTimeExceptionName));

            var controller = new LeadTimeDashboardController(_leadtimeService.Object, _leadtimeExceptionsService.Object, _exportService.Object);

            async Task asyncAct() { await controller.AddLeadTimeExceptionAsync(new(), CancellationToken.None); }

            var exception = await Assert.ThrowsAsync<BadRequestException>(asyncAct);

            Assert.NotNull(exception);
            Assert.Equal(ErrorCodes.DuplicateLeadTimeExceptionName, exception.Code);
            Assert.Equal(ErrorMessages.DuplicateLeadTimeExceptionName, exception.Message);
        }


        [Fact]
        public async Task EditLeadTimeExceptions_Success()
        {
            _leadtimeExceptionsService
                .Setup(_ => _.EditLeadTimeExceptionAsync(It.IsAny<EditExceptionRequest>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(new ExceptionResponse());

            var controller = new LeadTimeDashboardController(_leadtimeService.Object, _leadtimeExceptionsService.Object, _exportService.Object);
            var response = await controller.EditLeadTimeExceptionAsync(new(), CancellationToken.None);

            Assert.NotNull(response);
        }

        [Fact]
        public async Task EditLeadTimeExceptions_ThrowsException_DuplicateExceptionName()
        {
            _leadtimeExceptionsService
                .Setup(_ => _.EditLeadTimeExceptionAsync(It.IsAny<EditExceptionRequest>(), It.IsAny<CancellationToken>()))
                .ThrowsAsync(new BadRequestException(ErrorCodes.DuplicateLeadTimeExceptionName, ErrorMessages.DuplicateLeadTimeExceptionName));

            var controller = new LeadTimeDashboardController(_leadtimeService.Object, _leadtimeExceptionsService.Object, _exportService.Object);

            async Task asyncAct() { await controller.EditLeadTimeExceptionAsync(new(), CancellationToken.None); }

            var exception = await Assert.ThrowsAsync<BadRequestException>(asyncAct);

            Assert.NotNull(exception);
            Assert.Equal(ErrorMessages.DuplicateLeadTimeExceptionName, exception.Message);
        }

        [Fact]
        public async Task EditLeadTimeExceptions_ThrowsException_InvalidExceptionId()
        {
            _leadtimeExceptionsService
                .Setup(_ => _.EditLeadTimeExceptionAsync(It.IsAny<EditExceptionRequest>(), It.IsAny<CancellationToken>()))
                .ThrowsAsync(new BadRequestException(ErrorCodes.InvalidLeadTimeExceptionId, ErrorMessages.InvalidLeadTimeExceptionId));

            var controller = new LeadTimeDashboardController(_leadtimeService.Object, _leadtimeExceptionsService.Object, _exportService.Object);

            async Task asyncAct() { await controller.EditLeadTimeExceptionAsync(new(), CancellationToken.None); }

            var exception = await Assert.ThrowsAsync<BadRequestException>(asyncAct);

            Assert.NotNull(exception);
            Assert.Equal(ErrorCodes.InvalidLeadTimeExceptionId, exception.Code);
            Assert.Equal(ErrorMessages.InvalidLeadTimeExceptionId, exception.Message);
        }


        [Fact]
        public async Task DeleteLeadTimeExceptions_Success()
        {
            _leadtimeExceptionsService
                .Setup(_ => _.DeleteLeadTimeExceptionAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(new ExceptionResponse());

            var controller = new LeadTimeDashboardController(_leadtimeService.Object, _leadtimeExceptionsService.Object, _exportService.Object);
            var response = await controller.DeleteLeadTimeExceptionAsync(It.IsAny<string>(), CancellationToken.None);

            Assert.NotNull(response);
        }

        [Fact]
        public async Task DeleteLeadTimeExceptions_ThrowsException_InvalidExceptionId()
        {
            _leadtimeExceptionsService
                .Setup(_ => _.DeleteLeadTimeExceptionAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
                .ThrowsAsync(new BadRequestException(ErrorCodes.InvalidLeadTimeExceptionId, ErrorMessages.InvalidLeadTimeExceptionId));

            var controller = new LeadTimeDashboardController(_leadtimeService.Object, _leadtimeExceptionsService.Object, _exportService.Object);

            async Task asyncAct() { await controller.DeleteLeadTimeExceptionAsync(It.IsAny<string>(), CancellationToken.None); }

            var exception = await Assert.ThrowsAsync<BadRequestException>(asyncAct);

            Assert.NotNull(exception);
            Assert.Equal(ErrorCodes.InvalidLeadTimeExceptionId, exception.Code);
            Assert.Equal(ErrorMessages.InvalidLeadTimeExceptionId, exception.Message);
        }


        [Fact]
        public async Task GetOpenCapacitySummary_Success()
        {
            var filterData = GetFilterData();
            _leadtimeService
                .Setup(_ => _.GetCapacitySummaryAsync(It.IsAny<DashboardFilter>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(new CapacitySummaryResponse()
                {
                    CapacitySummary = new List<CapacitySummary>()
                });

            var controller = new LeadTimeDashboardController(_leadtimeService.Object, _leadtimeExceptionsService.Object, _exportService.Object);
            var response = await controller.CapacitySummary(new(), CancellationToken.None);
            Assert.NotNull(response);
        }

        [Fact]
        public async Task GetOpenCapacityOutlook_Success()
        {
            var filterData = GetFilterData();
            _leadtimeService
                .Setup(_ => _.GetCapacityOutlookOverTimeAsync(It.IsAny<DashboardFilter>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(new CapacityOutlookOverTimeResponse()
                {
                    CapacityOutlookOverTime = new List<CapacityOutlookOverTime>()
                });

            var controller = new LeadTimeDashboardController(_leadtimeService.Object, _leadtimeExceptionsService.Object, _exportService.Object);
            var response = await controller.CapacityOutlookOverTimeAsync(new(), CancellationToken.None);
            Assert.NotNull(response);
        }

        [Fact]
        public async Task GetOpenCapacityOverview_Success()
        {
            var filterData = GetFilterData();
            _leadtimeService
                .Setup(_ => _.GetCapacityOverviewAsync(It.IsAny<DashboardFilter>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(new CapacityOverviewResponse()
                {
                    CapacityOverviews = new List<CapacityOverview>()
                });

            var controller = new LeadTimeDashboardController(_leadtimeService.Object, _leadtimeExceptionsService.Object, _exportService.Object);
            var response = await controller.CapacityOverviewAsync(new(), CancellationToken.None);
            Assert.NotNull(response);
        }


        private static LeadTimeDashboardFilter GetFilterData()
        {
            return new LeadTimeDashboardFilter
            {
                FacilityId = "facilityId1",
                FacilityName = "facility1",
                EquipmentId = "eqId1",
                EquipmentName = "eq1",
                WorkcenterId = "wcId1",
                WorkcenterName = "wc1",
                ValueStreams = new(),
                Tickets = new List<TicketFilter>
                {
                    new() {
                        IsScheduled = true,
                        SourceTicketId = "stId1"
                    },
                    new() {
                        IsScheduled = false,
                        SourceTicketId = "stId2"
                    }
                }
            };
        }
    }
}

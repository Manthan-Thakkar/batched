using Batched.Common;
using Batched.Common.Data.Tenants.Sql.Models;
using Batched.Common.Testing.Mock;
using Batched.Reporting.Contracts;
using Batched.Reporting.Contracts.Models.StagingRequirement;
using Batched.Reporting.Data;
using Batched.Reporting.Test.MockedEntities;
using Batched.Reporting.Test.MockedEntities.StagingRequirement;
using Moq;
using Xunit;
using static Batched.Common.Testing.Mock.MockDbContext;
using static Batched.Reporting.Shared.BatchedConstants;
using CM = Batched.Common.Data.Tenants.Sql.Models;

namespace Batched.Reporting.Test.Repository
{
    public class EquipmentRepositoryTest : BaseTest<EquipmentRepository>
    {
        private readonly Mock<UnitOfWorkFactory> _unitOfWorkFactory;
        private readonly Mock<TenantContext> _dbContext;
        public EquipmentRepositoryTest() : base(typeof(UnitOfWorkFactory))
        {
            _unitOfWorkFactory = new Mock<UnitOfWorkFactory>(null);
            _dbContext = new Mock<TenantContext>();
            MockContext<TenantContext, CM.ValueStream>(_dbContext, MockedValueStream.GetValueStreams());
            MockContext<TenantContext, CM.EquipmentValueStream>(_dbContext, MockedValueStream.GetEquipmentValueStreams());
            MockContext<TenantContext, CM.Facility>(_dbContext, MockedFacilities.GetFacilities());
            MockContext<TenantContext, CM.EquipmentMaster>(_dbContext, MockedEquipmentsData.GetEquipments());
            MockContext<TenantContext, CM.TicketMaster>(_dbContext, MockedTicketMaster.GetTickets());
            MockContext<TenantContext, CM.TicketShipping>(_dbContext, MockedTicketShipping.GetTicketShipping());
            MockContext<TenantContext, CM.TicketTask>(_dbContext, MockedTicketTask.GetTicketTasks());
            MockContext<TenantContext, CM.ScheduleReport>(_dbContext, MockedScheduleReport.GetScheduleReports());
            MockContext<TenantContext, CM.DailyEquipmentCapacity>(_dbContext, MockedEquipmentsData.GetDailyEquipmentCapacity());
            MockContext<TenantContext, CM.EquipmentDowntime>(_dbContext, MockedEquipmentsData.GetEquipmentDowntimes());
            MockContext<TenantContext, CM.EquipmentCalendar>(_dbContext, MockedEquipmentsData.GetEquipmentCalendar());
            MockContext<TenantContext, CM.CapacityConfiguration>(_dbContext, MockedEquipmentsData.GetEquipmentsCapacityConfigurations());
            MockContext<TenantContext, CM.StagingRequirement>(_dbContext, MockedStagingRequirement.GetStagingRequirements());
            MockContext<TenantContext, CM.StagingRequirementGroup>(_dbContext, MockedStagingRequirement.GetWorkcenterStagingRequirements());

            _unitOfWorkFactory
                .Setup(x => x.BeginUnitOfWork(DBContextLevel.Tenant, DbAccessMode.read))
                .Returns(() => new MockUnitOfWork(_dbContext.Object));
        }

        [Fact(Skip = "Failing due to EF Core mock issue.")]
        public async Task GetFilterDataAsync_ShouldReturnFilterData_WithNoFacilities()
        {
            var filter = new DashboardFilter { Facilities = new() };
            var equipmentRepo = new EquipmentRepository(_unitOfWorkFactory.Object);
            var filterData = await equipmentRepo.GetFilterDataAsync(filter, new CancellationToken());
            Assert.NotNull(filterData);
        }

        [Fact]
        public async Task GetEquipmentWiseTicketsAysnc_ShouldReturnTickets_WithFilter()
        {
            var filter = new DashboardFilter { Facilities = new(), EndDate = DateTime.Now.AddDays(60) };
            var equipmentRepo = new EquipmentRepository(_unitOfWorkFactory.Object);
            var equipmentWiseTickets = await equipmentRepo.GetEquipmentWiseTicketsAysnc(filter, new CancellationToken());
            Assert.NotNull(equipmentWiseTickets);
            Assert.Equal(5, equipmentWiseTickets.Count);
        }

        [Fact]
        public async Task GetEquipmentWiseTicketsAysnc_ShouldReturnTickets_WithToDateFilter()
        {
            var filterToDateDays = 30;
            var mockedTicketShippings = MockedTicketShipping.GetTicketShipping();
            var mockedTickets = MockedTicketMaster.GetTickets();
            var ticketShipping = mockedTicketShippings.FirstOrDefault(t => t.ShipByDateTime > DateTime.Now.AddDays(filterToDateDays));
            var expectedTicket = mockedTickets.FirstOrDefault(t => t.Id == ticketShipping?.TicketId);

            var filter = new DashboardFilter { Facilities = new(), EndDate = DateTime.Now.AddDays(filterToDateDays) };
            var equipmentRepo = new EquipmentRepository(_unitOfWorkFactory.Object);
            var equipmentWiseTickets = await equipmentRepo.GetEquipmentWiseTicketsAysnc(filter, new CancellationToken());
            Assert.NotNull(equipmentWiseTickets);
            Assert.NotEmpty(equipmentWiseTickets);
            //srcTicket5 has ShipByDateTime > 30 days
            Assert.DoesNotContain(equipmentWiseTickets, e => e.Tickets.Any(t => t.SourceTicketId == expectedTicket.SourceTicketId));
        }

        [Fact]
        public async Task GetEquipmentWiseTicketsAysnc_ShouldReturnScheduledTicket()
        {
            var mockedScheduleReport = MockedScheduleReport.GetScheduleReports();
            var expectedScheduledTicket = mockedScheduleReport.FirstOrDefault();
            var filter = new DashboardFilter { Facilities = new(), EndDate = DateTime.Now.AddDays(30) };
            var equipmentRepo = new EquipmentRepository(_unitOfWorkFactory.Object);
            var equipmentWiseTickets = await equipmentRepo.GetEquipmentWiseTicketsAysnc(filter, new CancellationToken());
            Assert.NotNull(equipmentWiseTickets);
            Assert.NotEmpty(equipmentWiseTickets);
            //There is one ticket which is Scheduled
            Assert.Contains(equipmentWiseTickets, e => e.Tickets.Any(t => t.IsScheduled));
            Assert.Contains(equipmentWiseTickets, e => e.Tickets.Any(t => t.SourceTicketId == expectedScheduledTicket.SourceTicketId));
        }

        [Fact]
        public async Task GetEquipmentWiseTicketsAysnc_ShouldNotReturnCompletedTicket()
        {
            var mockedTickets = MockedTicketMaster.GetTickets();
            var mockedTicketTasks = MockedTicketTask.GetTicketTasks();
            var allTasksCompletedTicket = mockedTicketTasks.GroupBy(tt => tt.TicketId)
                .Where(g => g.All(tt => tt.IsComplete))
                .Select(g => g.Key).FirstOrDefault();

            var completedTicketSourceId = mockedTickets.FirstOrDefault(t => t.Id == allTasksCompletedTicket);

            var filter = new DashboardFilter { Facilities = new(), EndDate = DateTime.Now.AddDays(30) };
            var equipmentRepo = new EquipmentRepository(_unitOfWorkFactory.Object);
            var equipmentWiseTickets = await equipmentRepo.GetEquipmentWiseTicketsAysnc(filter, new CancellationToken());
            Assert.NotNull(equipmentWiseTickets);
            Assert.NotEmpty(equipmentWiseTickets);
            //There is a ticket which has all Tasks with IsComplete = true
            Assert.DoesNotContain(equipmentWiseTickets, e => e.Tickets.Any(t => t.SourceTicketId == completedTicketSourceId.SourceTicketId));
        }

        [Fact]
        public async Task GetEquipmentWiseTicketsAysnc_ShouldReturnNullShipByDateTicket()
        {
            var mockedTickets = MockedTicketMaster.GetTickets();
            var mockedTicketShipping = MockedTicketShipping.GetTicketShipping();
            var ticketWithNullShipByDate = mockedTicketShipping.FirstOrDefault(t => t.ShipByDateTime == null);

            var srcTicketOfNullShipByDate = mockedTickets.FirstOrDefault(t => t.Id == ticketWithNullShipByDate.TicketId);

            var filter = new DashboardFilter { Facilities = new(), EndDate = DateTime.Now.AddDays(30) };
            var equipmentRepo = new EquipmentRepository(_unitOfWorkFactory.Object);
            var equipmentWiseTickets = await equipmentRepo.GetEquipmentWiseTicketsAysnc(filter, new CancellationToken());
            Assert.NotNull(equipmentWiseTickets);
            Assert.NotEmpty(equipmentWiseTickets);
            //There is a ticket which has null ShipByDateTime
            Assert.Contains(equipmentWiseTickets, e => e.Tickets.Any(t => t.SourceTicketId == srcTicketOfNullShipByDate.SourceTicketId));
        }

        [Fact(Skip = "need to add mocking.")]
        public async Task GetEquipmentCapacityAysnc_ShouldReturnEquipmentCapacity_withDateFilter()
        {
            var startDate = new DateTime(2024, 1, 1);
            var endDate = new DateTime(2024, 1, 10);
            var totalEquipmentCapacityEntries = MockedEquipmentsData.GetDailyEquipmentCapacity()
                .Where(x => x.Date >= startDate && x.Date <= endDate).Count();

            var equipmentRepo = new EquipmentRepository(_unitOfWorkFactory.Object);
            var dailyEquipmentCapacity = await equipmentRepo.GetEquipmentsCapacityAsync(startDate, endDate, new CancellationToken());

            Assert.NotNull(dailyEquipmentCapacity);
            Assert.Equal(totalEquipmentCapacityEntries, dailyEquipmentCapacity.Count);
        }

        [Fact]
        public async Task GetMaxEquipmentCalendarDateAysnc_ShouldReturnMaxDateFromEquipmentCalendar()
        {
            var maxDate = MockedEquipmentsData.GetEquipmentCalendar().Max(x => x.TheDateTime);

            var equipmentRepo = new EquipmentRepository(_unitOfWorkFactory.Object);
            var maxCalendarDate = await equipmentRepo.GetMaxEquipmentCalendarDate();

            Assert.Equal(maxCalendarDate, maxDate);

        }


        [Theory]
        [MemberData(nameof(MockedStagingRequirementRequests.GetStagingRequirementFilterRequest), MemberType = typeof(MockedStagingRequirementRequests))]
        public async Task GetEquipmentWiseStagingTicketsAysnc_ShouldReturn_EquipmentsAndRespectiveTickets_wrt_ProvidedFilters(int requestNum, DateTime? startDate, DateTime? endDate, List<string> UserAssignedFacilities)
        {
            MockContext(_dbContext, MockedScheduleReport.GetScheduleReportForStaging());
            var request = new StagingRequirementFilterDataPayload
            {
                StartDate = startDate,
                EndDate = endDate,
                UserAssignedFacilities = UserAssignedFacilities
            };

            var equipmentRepo = new EquipmentRepository(_unitOfWorkFactory.Object);
            var equipmentTickets = await equipmentRepo.GetEquipmentWiseStagingTicketsAysnc(request, It.IsAny<CancellationToken>());

            switch (requestNum)
            {
                case 1:
                    Assert.Equal(8, equipmentTickets.Count);
                    Assert.Equal(2, equipmentTickets.First().Tickets.Count);
                    break;

                case 2:
                    Assert.Equal(5, equipmentTickets.Count);
                    Assert.Equal(4, equipmentTickets[1].Tickets.Count);
                    break;

                case 3:
                    Assert.Empty(equipmentTickets);
                    break;
            }
        }


        [Theory(Skip = "Failing due to EF Core mock issue - Left join.")]
        [MemberData(nameof(MockedStagingRequirementRequests.GetStagingRequirementFilterRequest), MemberType = typeof(MockedStagingRequirementRequests))]
        public async Task GetStagingFilterDataAsync_ShouldReturn_FilterData_wrt_ProvidedFilters(int requestNum, DateTime? startDate, DateTime? endDate, List<string> UserAssignedFacilities)
        {
            MockContext(_dbContext, MockedScheduleReport.GetScheduleReportForStaging());

            var request = new StagingRequirementFilterDataPayload
            {
                StartDate = startDate,
                EndDate = endDate,
                UserAssignedFacilities = UserAssignedFacilities
            };

            var equipmentRepo = new EquipmentRepository(_unitOfWorkFactory.Object);
            var filterData = await equipmentRepo.GetStagingFilterDataAsync(request, It.IsAny<CancellationToken>());

            switch (requestNum)
            {
                case 1:
                    Assert.Equal(7, filterData.Count);
                    break;

                case 2:
                    Assert.Equal(5, filterData.Count);
                    break;

                case 3:
                    Assert.Single(filterData);
                    break;
            }
        }
    }
}

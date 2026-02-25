using Batched.Common;
using Batched.Common.Data.Tenants.Sql.Models;
using Batched.Common.Testing.Mock;
using Batched.Reporting.Contracts;
using Batched.Reporting.Data;
using Batched.Reporting.Data.Contracts;
using Batched.Reporting.Test.MockedEntities;
using Moq;
using Xunit;
using static Batched.Common.Testing.Mock.MockDbContext;
using CM = Batched.Common.Data.Tenants.Sql.Models;

namespace Batched.Reporting.Test.Repository
{
    public class TicketTaskRepositoryTest : BaseTest<TicketTaskRepository>
    {
        private readonly Mock<UnitOfWorkFactory> _unitOfWorkFactory;
        private readonly Mock<TenantContext> _dbContext;
        private readonly Mock<IConnectionStringService> _connectionStringService;

        public TicketTaskRepositoryTest() : base(typeof(UnitOfWorkFactory), typeof(IConnectionStringService))
        {
            _unitOfWorkFactory = new Mock<UnitOfWorkFactory>(null);
            _dbContext = new Mock<TenantContext>();
            _connectionStringService = new Mock<IConnectionStringService>();

            MockContext<TenantContext, CM.ValueStream>(_dbContext, MockedValueStream.GetValueStreams());
            MockContext<TenantContext, CM.EquipmentValueStream>(_dbContext, MockedValueStream.GetEquipmentValueStreams());
            MockContext<TenantContext, CM.Facility>(_dbContext, MockedFacilities.GetFacilities());
            MockContext<TenantContext, CM.CapacityConfiguration>(_dbContext, MockedEquipmentsData.GetEquipmentsCapacityConfigurations());
            MockContext<TenantContext, CM.EquipmentMaster>(_dbContext, MockedEquipmentsData.GetEquipments());
            MockContext<TenantContext, CM.TicketMaster>(_dbContext, MockedTicketMaster.GetTickets());
            MockContext<TenantContext, CM.TicketShipping>(_dbContext, MockedTicketShipping.GetTicketShipping());
            MockContext<TenantContext, CM.TicketTask>(_dbContext, MockedTicketTask.GetTicketTasks());
            MockContext<TenantContext, CM.ScheduleReport>(_dbContext, MockedScheduleReport.GetScheduleReports());

            _unitOfWorkFactory
                .Setup(x => x.BeginUnitOfWork(DBContextLevel.Tenant, DbAccessMode.read))
                .Returns(() => new MockUnitOfWork(_dbContext.Object));
        }

        [Fact(Skip = "Failing due to EF left join issue.")]
        public async Task GetTicketsDemandAsync_ShouldReturnTicketsDemand_WithFilter()
        {
            var filter = new DashboardFilter { Facilities = new(), EndDate = DateTime.Now.AddDays(60) };
            var ticketTaskRepo = new TicketTaskRepository(_unitOfWorkFactory.Object, _connectionStringService.Object);
            var maxDate = DateTime.Now.AddDays(180);
            var ticketTaskDemand = await ticketTaskRepo.GetTicketsDemandAsync(filter, maxDate, new CancellationToken());
            Assert.NotNull(ticketTaskDemand);
            Assert.Equal(5, ticketTaskDemand.Count);
        }
    }
}

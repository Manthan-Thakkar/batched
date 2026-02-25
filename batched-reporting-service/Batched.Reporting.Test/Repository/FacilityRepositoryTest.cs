using Batched.Common.Data.Tenants.Sql.Models;
using Batched.Common;
using Batched.Reporting.Data;
using Batched.Reporting.Test.MockedEntities;
using Moq;
using Xunit;
using static Batched.Common.Testing.Mock.MockDbContext;
using CM = Batched.Common.Data.Tenants.Sql.Models;
using Batched.Common.Testing.Mock;

namespace Batched.Reporting.Test.Repository
{
    public class FacilityRepositoryTest : BaseTest<FacilityRepository>
    {
        private readonly Mock<UnitOfWorkFactory> _unitOfWorkFactory;
        private readonly Mock<TenantContext> _dbContext;
        public FacilityRepositoryTest() : base(typeof(UnitOfWorkFactory))
        {
            _unitOfWorkFactory = new Mock<UnitOfWorkFactory>(null);
            _dbContext = new Mock<TenantContext>();
            MockContext<TenantContext, CM.FacilityHoliday>(_dbContext, MockedHolidays.GetFacilityHolidays());
            MockContext<TenantContext, CM.HolidaySchedule>(_dbContext, MockedHolidays.GetHolidaySchedules());


            _unitOfWorkFactory
                .Setup(x => x.BeginUnitOfWork(DBContextLevel.Tenant, DbAccessMode.read))
                .Returns(() => new MockUnitOfWork(_dbContext.Object));
        }

        [Fact]
        public async Task GetFacilityHolidaysCountAsync_ShouldReturn_FacilityWiseHolidays()
        {
            var facilities = new List<string> {};
            var startDate = new DateTime(2024, 1, 1);
            var endDate = new DateTime(2024, 6, 1);

            var facilityHolidays = MockedHolidays.GetFacilityHolidays();
            var holidaySchedule = MockedHolidays.GetHolidaySchedules();

            var totalHolidays = (from fh in facilityHolidays
                                 join hs in holidaySchedule on fh.HolidayId equals hs.Id
                                 where hs.Date >= startDate && hs.Date <= endDate
                                 select new { hs.Date }).Count();

            var facilityRepo = new FacilityRepository(_unitOfWorkFactory.Object);

            var facilityWiseHolidayCount = await facilityRepo.GetFacilityHolidaysCountAsync(facilities, startDate, endDate);
            Assert.NotNull(facilityWiseHolidayCount);
            Assert.Equal(totalHolidays, facilityWiseHolidayCount.Select(x => x.TotalHolidays).Sum());
        }

        [Fact]
        public async Task GetFacilityHolidaysCountAsync_ShouldReturn_FacilityWiseHolidays_WithFacilityFilter()
        {
            var facilities = new List<string> { "4233c3a8-c524-4a2f-88c2-5b177955baf6" };
            var startDate = new DateTime(2024,1,1);
            var endDate = new DateTime(2024, 6, 1);

            var facilityHolidays = MockedHolidays.GetFacilityHolidays();
            var holidaySchedule = MockedHolidays.GetHolidaySchedules();

            var totalHolidays = (from fh in facilityHolidays
                                 join hs in holidaySchedule on fh.HolidayId equals hs.Id
                                 where hs.Date >= startDate && hs.Date <= endDate
                                 && facilities.Contains(fh.FacilityId)
                                 select new { hs.Date }).Count();

            var facilityRepo = new FacilityRepository(_unitOfWorkFactory.Object);

            var facilityWiseHolidayCount = await facilityRepo.GetFacilityHolidaysCountAsync(facilities, startDate, endDate);
            Assert.NotNull(facilityWiseHolidayCount);
            Assert.Equal(totalHolidays, facilityWiseHolidayCount.Select(x => x.TotalHolidays).Sum());
        }
    }
}

using Batched.Common;
using Batched.Reporting.Contracts.Interfaces;
using Batched.Reporting.Contracts.Models;
using Microsoft.EntityFrameworkCore;
using Commons = Batched.Common.Data.Tenants.Sql.Models;

namespace Batched.Reporting.Data
{
    public class FacilityRepository : IFacilityRepository
    {
        private readonly UnitOfWorkFactory _unitOfWorkFactory;
        public FacilityRepository(UnitOfWorkFactory unitOfWorkFactory)
        {
            _unitOfWorkFactory = unitOfWorkFactory;
        }
        public async Task<List<FacilityHolidaysCount>> GetFacilityHolidaysCountAsync(List<string> facilities, DateTime startDate, DateTime endDate)
        {

            using (Tracer.Benchmark("facility-repo-get-facility-wise-holiday-count"))
            using (var unitOfWork = _unitOfWorkFactory.BeginUnitOfWork(DBContextLevel.Tenant, DbAccessMode.read))
            {
                var holidaySchedule = unitOfWork.Repository<Commons.HolidaySchedule>().GetQueryable();
                var facilityHolidays = unitOfWork.Repository<Commons.FacilityHoliday>().GetQueryable();

                return await (from fh in facilityHolidays
                                            join hs in holidaySchedule on fh.HolidayId equals hs.Id
                                            where hs.Date >= startDate && hs.Date <= endDate
                                            && (facilities.Count == 0 || facilities.Contains(fh.FacilityId))
                                            group new { fh.FacilityId, hs.Date } by fh.FacilityId into g
                                            select new FacilityHolidaysCount
                                            {
                                                FacilityId = g.Key,
                                                TotalHolidays = g.Select(x => x.Date).Count()
                                            }
                                   ).ToListAsync();
            }
               
        }

        public async Task<List<FacilityWiseHolidays>> GetAllFacilityWiseHolidays(List<string> facilities)
        { 
            using (Tracer.Benchmark("facility-repo-get-all-facility-wise-holidays"))
            using (var unitOfWork = _unitOfWorkFactory.BeginUnitOfWork(DBContextLevel.Tenant, DbAccessMode.read))
            {
                var holidaySchedule = unitOfWork.Repository<Commons.HolidaySchedule>().GetQueryable();
                var facilityHolidays = unitOfWork.Repository<Commons.FacilityHoliday>().GetQueryable();

                return await (from fh in facilityHolidays
                              join hs in holidaySchedule on fh.HolidayId equals hs.Id
                              where (facilities.Count == 0 || facilities.Contains(fh.FacilityId))
                              group new { fh.FacilityId, hs.Date } by fh.FacilityId into g
                              select new FacilityWiseHolidays
                              {
                                  FacilityId = g.Key,
                                  Holidays = g.Select(x => x.Date.Date).ToList()
                              }
                              ).ToListAsync();
            }
        }
    }
}

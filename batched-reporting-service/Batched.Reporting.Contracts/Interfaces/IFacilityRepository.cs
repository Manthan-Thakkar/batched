using Batched.Reporting.Contracts.Models;

namespace Batched.Reporting.Contracts.Interfaces
{
    public interface IFacilityRepository
    {
        Task<List<FacilityHolidaysCount>> GetFacilityHolidaysCountAsync(List<string> facilities, DateTime startDate, DateTime endDate);
        Task<List<FacilityWiseHolidays>> GetAllFacilityWiseHolidays(List<string> facilities);
    }
}

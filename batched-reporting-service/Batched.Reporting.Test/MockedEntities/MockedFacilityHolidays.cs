using Batched.Common.Data.Tenants.Sql.Models;
using Newtonsoft.Json;

namespace Batched.Reporting.Test.MockedEntities
{
    public class MockedHolidays
    {
        public static List<FacilityHoliday> GetFacilityHolidays()
        {
            var jsonFacilityHolidays = File.ReadAllText("./Data/FacilityHoliday.json");

            var facilityHolidays = JsonConvert.DeserializeObject<List<FacilityHoliday>>(jsonFacilityHolidays);
            return facilityHolidays;
        }

        public static List<HolidaySchedule> GetHolidaySchedules()
        {
            var JsonHolidaySchedule = File.ReadAllText("./Data/HolidaySchedule.json");

            var holidaySchedules = JsonConvert.DeserializeObject<List<HolidaySchedule>>(JsonHolidaySchedule);
            return holidaySchedules;
        }
    }
}

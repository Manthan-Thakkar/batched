using Batched.Common.Data.Tenants.Sql.Models;
using Newtonsoft.Json;

namespace Batched.Reporting.Test.MockedEntities
{
    public class MockedFacilities
    {
        public static List<Facility> GetFacilities()
        {
            var jsonFacilities = File.ReadAllText("./Data/Facility.json");

            var facilities = JsonConvert.DeserializeObject<List<Facility>>(jsonFacilities);
            return facilities;
        }
    }
}

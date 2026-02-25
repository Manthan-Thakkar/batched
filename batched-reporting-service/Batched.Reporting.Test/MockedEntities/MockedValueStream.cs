using Batched.Common.Data.Tenants.Sql.Models;
using Newtonsoft.Json;

namespace Batched.Reporting.Test.MockedEntities
{
    public class MockedValueStream
    {
        public static List<ValueStream> GetValueStreams()
        {
            var jsonValueStreams = File.ReadAllText("./Data/ValueStream.json");

            var valueStreams = JsonConvert.DeserializeObject<List<ValueStream>>(jsonValueStreams);
            valueStreams.ForEach(valueStream => { valueStream.EquipmentValueStreams = new List<EquipmentValueStream>(); });
            return valueStreams;
        }

        public static List<EquipmentValueStream> GetEquipmentValueStreams()
        {
            var jsonValueStreams = File.ReadAllText("./Data/EquipmentValueStream.json");

            var valueStreams = JsonConvert.DeserializeObject<List<EquipmentValueStream>>(jsonValueStreams);
            valueStreams.ForEach(valueStream => { valueStream.ValueStream = new (); valueStream.Equipment = new(); });
            return valueStreams;
        }
    }
}

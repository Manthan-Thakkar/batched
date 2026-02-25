using Batched.Common.Data.Tenants.Sql.Models;
using Batched.Reporting.Contracts;
using Batched.Reporting.Contracts.Models.StagingRequirement;
using Newtonsoft.Json;

namespace Batched.Reporting.Test.MockedEntities
{
    public class MockedEquipmentsData
    {
        public static List<EquipmentMaster> GetEquipments()
        {
            var jsonEquipmentMaster = File.ReadAllText("./Data/EquipmentMaster.json");

            var equipments = JsonConvert.DeserializeObject<List<EquipmentMaster>>(jsonEquipmentMaster);
            equipments.ForEach(equip => { equip.EquipmentValueStreams = new List<EquipmentValueStream>(); });
            return equipments;
        }

        public static List<DailyEquipmentCapacity> GetDailyEquipmentCapacity()
        {
            var jsonDailyEquipmentCapacity = File.ReadAllText("./Data/DailyEquipmentCapacity.json");
            var dailyEquipmentCapacaties = JsonConvert.DeserializeObject<List<DailyEquipmentCapacity>>(jsonDailyEquipmentCapacity);
            return dailyEquipmentCapacaties;
        }

        public static List<EquipmentDowntime> GetEquipmentDowntimes()
        {
            var jsonEquipmentDowntimes = File.ReadAllText("./Data/EquipmentDowntimes.json");
            var equipmentDowntimes = JsonConvert.DeserializeObject<List<EquipmentDowntime>>(jsonEquipmentDowntimes);
            return equipmentDowntimes;
        }

        public static List<EquipmentCalendar> GetEquipmentCalendar()
        {
            var jsonEquipmentCalendar = File.ReadAllText("./Data/EquipmentCalendar.json");
            var equipmentCalendars = JsonConvert.DeserializeObject<List<EquipmentCalendar>>(jsonEquipmentCalendar);
            return equipmentCalendars;
        }

        public static List<CapacityConfiguration> GetEquipmentsCapacityConfigurations()
        {
            var jsonEquipmentMaster = File.ReadAllText("./Data/EquipmentMaster.json");

            var equipments = JsonConvert.DeserializeObject<List<EquipmentMaster>>(jsonEquipmentMaster);
            equipments.ForEach(equip => { equip.EquipmentValueStreams = new List<EquipmentValueStream>(); });

            var capacityConfigs = equipments.Select(equip => new CapacityConfiguration
            {
                Id = Guid.NewGuid().ToString(),
                EquipmentId = equip.Id,
                Equipment = equip,
                AvailabilityThreshold = 0,
                MinLeadTime = 14,
                UnplannedAllowance = 0,
                CreatedOnUtc = DateTime.UtcNow,
                ModifiedOnUtc = DateTime.UtcNow,
            }).ToList();
            return capacityConfigs;
        }

        public static List<EquipmentStagingTickets> GetEquipmentWiseTickets()
        {
            var jsonEquipmentWiseTickets = File.ReadAllText("./Data/EquipmentWiseTickets.json");
            var equipmentWiseTickets = JsonConvert.DeserializeObject<List<EquipmentStagingTickets>>(jsonEquipmentWiseTickets);
            return equipmentWiseTickets;
        }

        public static List<StagingReportFilterData> GetStagingFilterData()
        {
            var jsonStagingFilterData = File.ReadAllText("./Data/StagingFilterData.json");
            var stagingFilterData = JsonConvert.DeserializeObject<List<StagingReportFilterData>>(jsonStagingFilterData);
            return stagingFilterData;
        }
    }
}
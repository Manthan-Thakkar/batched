using Batched.Reporting.Contracts.Models.LeadTimeManager;

namespace Batched.Reporting.Test.MockedEntities
{
    public static class MockedCapacityOutlook
    {
        public static List<EquipmentCapacityOutlook> GetDailyEquipmentCapacityOutlook(int holidayDaysEquip1, int holidayDaysEquip2)
        {
            var result = new List<EquipmentCapacityOutlook>();
            var startDate = DateTime.Today;
            var holidayDate1 = DateTime.Today.AddDays(holidayDaysEquip1);
            var holidayDate2 = DateTime.Today.AddDays(holidayDaysEquip2);

            for (int i = 0; i < 180; i++)
            {
                result.Add(new EquipmentCapacityOutlook
                {
                    EquipmentId = "equip1",
                    FacilityId = "f1",
                    SourceEquipmentId = "e1",
                    ShiftStart = new TimeSpan(4, 0, 0),
                    ShiftEnd = new TimeSpan(12, 0, 0),
                    CapacityHours = 8.0f,
                    TheDate = startDate.AddDays(i),
                    TicketDemand = 0,
                    DowntimeStart = null,
                    DowntimeEnd = null,
                    DowntimeHours = 0,
                    IsHoliday = startDate.AddDays(i) == holidayDate1,
                    UnplannedAllowance = 10,
                    UnplannedAllowanceHours = 0.8f,
                });

                result.Add(new EquipmentCapacityOutlook
                {
                    EquipmentId = "equip2",
                    FacilityId = "f1",
                    SourceEquipmentId = "e2",
                    ShiftStart = new TimeSpan(4, 0, 0),
                    ShiftEnd = new TimeSpan(14, 0, 0),
                    CapacityHours = 10.0f,
                    TheDate = startDate.AddDays(i),
                    TicketDemand = 0,
                    DowntimeStart = null,
                    DowntimeEnd = null,
                    DowntimeHours = 0,
                    IsHoliday = startDate.AddDays(i) == holidayDate2,
                    UnplannedAllowance = 10,
                    UnplannedAllowanceHours = 1.0f,
                });
            }

            return result;
        }

        public static List<EquipmentCapacityOutlook> GetDailyEquipmentCapacityOutlookWithDowntime()
        {
            var result = new List<EquipmentCapacityOutlook>();
            var startDate = DateTime.Today;

            for (int i = 0; i < 180; i++)
            {
                result.Add(new EquipmentCapacityOutlook
                {
                    EquipmentId = "equip1",
                    FacilityId = "f1",
                    SourceEquipmentId = "e1",
                    ShiftStart = new TimeSpan(4, 0, 0),
                    ShiftEnd = new TimeSpan(12, 0, 0),
                    CapacityHours = 8.0f,
                    TheDate = startDate.AddDays(i),
                    TicketDemand = 0,
                    DowntimeStart = i >= 2 && i <= 3 ? startDate.AddDays(2).AddHours(5) : null,
                    DowntimeEnd = i >= 2 && i <= 3 ? startDate.AddDays(3).AddHours(10) : null,
                    DowntimeHours = 0,
                    IsHoliday = false,
                    UnplannedAllowance = 10,
                    UnplannedAllowanceHours = 0.8f,
                });
            }
            return result;
        }


    }
}

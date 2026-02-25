using Batched.Common;
using Batched.Reporting.Contracts;

namespace Batched.Reporting.Core.Translators
{
    public static class CapacitySummaryTranslator
    {
        public static List<CapacitySummaryFlatData> Flatten(this List<CapacitySummary> summaries)
        {
            var flatList = new List<CapacitySummaryFlatData>();
            summaries.FlattenHelper(flatList);
            return flatList;
        }

        private static void FlattenHelper(this List<CapacitySummary> summaries, List<CapacitySummaryFlatData> flatList)
        {
            foreach (var summary in summaries)
            {
                flatList.Add(summary.CapacitySummaryData.Translate(summary.Name, summary.Type));
                FlattenHelper(summary.DownStreamSummary, flatList);
            }
        }

        public static CapacitySummaryFlatData Translate(this CapacityConfig summeries, string name, string type)
        {
            if (summeries == null)
                return null;

            return new CapacitySummaryFlatData()
            {
                Facility = type == Constants.EquipmentLevel.Facility ? name : string.Empty,
                ValueStream = type == Constants.EquipmentLevel.ValueStream ? name : string.Empty,
                Workcenter = type == Constants.EquipmentLevel.Workcenter ? name : string.Empty,
                Equipment = type == Constants.EquipmentLevel.Equipment ? name : string.Empty,
                ActualLeadTimeDays = summeries.ActualLeadTimeDays,
                AvailableCapacity = summeries.AvailableCapacity,
                DownTimeHolidays = summeries.DownTimeHolidays,
                ExternalLeadTimeDays = summeries.ExternalLeadTimeDays,
                NextAvailableDate = summeries.NextAvailableDate,
                ReservedDemand = summeries.ReservedDemand,
                TicketDemand = summeries.TicketDemand,
                TotalCapacity = summeries.TotalCapacity,
                TotalDemand = summeries.TotalDemand,
                TotalTickets = summeries.TotalTickets,
                UnplannedAllowance = summeries.UnplannedAllowance
            };
        }
    }
}
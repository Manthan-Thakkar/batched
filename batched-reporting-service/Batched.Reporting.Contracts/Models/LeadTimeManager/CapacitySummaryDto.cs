using Batched.Common;
using Batched.Reporting.Contracts.Models.LeadTimeManager;
using System.Collections;

namespace Batched.Reporting.Contracts
{
    public class CapacitySummaryDto
    {
        public string FacilityId { get; set; }
        public string FacilityName { get; set; }
        public string ValueStreamId { get; set; }
        public string ValueStreamName { get; set; }
        public string WorkcenterId { get; set; }
        public string WorkcenterName { get; set; }
        public string EquipmentId { get; set; }
        public string EquipmentName { get; set; }
        public int TotalTickets { get; set; }
        public float TotalCapacity { get; set; }
        public float TicketDemand { get; set; }
        public float ReservedDemand { get; set; }
        public int UnplannedAllowance { get; set; }
        public int ExternalLeadTimeDays { get; set; }
        public List<string> Tickets { get; set; } = new List<string>();
    }

    public class CapacityConfig
    {
        public int TotalTickets { get; set; }
        public float TicketDemand { get; set; }
        public float TotalCapacity { get; set; }
        public float? ReservedDemand { get; set; }
        public float TotalDemand { get; set; }
        public int DownTimeHolidays { get; set; }
        public int UnplannedAllowance { get; set; }
        public float AvailableCapacity { get; set; }
        public int ActualLeadTimeDays { get; set; }
        public int ExternalLeadTimeDays { get; set; }
        public DateTime? ExternalNextAvailableDate { get; set; }
        public DateTime? NextAvailableDate { get; set; }

    }

    public class CapacitySummary
    {
        public string Id { get; set; }
        public string Name { get; set; }
        public string Type { get; set; }
        public CapacityConfig CapacitySummaryData { get; set; }
        public List<CapacitySummary> DownStreamSummary { get; set; } = new List<CapacitySummary>();

    }

    public class CapacitySummaryResponse
    {
        public List<CapacitySummary> CapacitySummary { get; set; } = new List<CapacitySummary>();

    }

    public class CapacitySummaryFlatData : CapacityConfig
    {
        public string Facility { get; set; }
        public string ValueStream { get; set; }
        public string Workcenter { get; set; }
        public string Equipment { get; set; }

    }

    public class ExportCapacitySummaryDataPropertyMapper : IEnumerable<KeyValuePair<string, object>>
    {
        private readonly CapacitySummaryFlatData _capacitySummary;
        public ExportCapacitySummaryDataPropertyMapper(CapacitySummaryFlatData capacitySummary)
        {
            _capacitySummary = capacitySummary;
        }

        public IEnumerator<KeyValuePair<string, object>> GetEnumerator()
        {
            yield return new KeyValuePair<string, object>(nameof(CapacitySummaryFlatData.Facility), _capacitySummary.Facility);
            yield return new KeyValuePair<string, object>(nameof(CapacitySummaryFlatData.ValueStream), _capacitySummary.ValueStream);
            yield return new KeyValuePair<string, object>(nameof(CapacitySummaryFlatData.Workcenter), _capacitySummary.Workcenter);
            yield return new KeyValuePair<string, object>(nameof(CapacitySummaryFlatData.Equipment), _capacitySummary.Equipment);
            yield return new KeyValuePair<string, object>(nameof(CapacitySummaryFlatData.ActualLeadTimeDays), _capacitySummary.ActualLeadTimeDays.FormatNumber());
            yield return new KeyValuePair<string, object>(nameof(CapacitySummaryFlatData.AvailableCapacity), RoundValue(_capacitySummary.AvailableCapacity));
            yield return new KeyValuePair<string, object>(nameof(CapacitySummaryFlatData.DownTimeHolidays), _capacitySummary.DownTimeHolidays.FormatNumber());
            yield return new KeyValuePair<string, object>(nameof(CapacitySummaryFlatData.ExternalLeadTimeDays), _capacitySummary.ExternalLeadTimeDays.FormatNumber());
            yield return new KeyValuePair<string, object>(nameof(CapacitySummaryFlatData.NextAvailableDate), _capacitySummary.NextAvailableDate.FormatDate());
            yield return new KeyValuePair<string, object>(nameof(CapacitySummaryFlatData.ReservedDemand), _capacitySummary.ReservedDemand.FormatNumber());
            yield return new KeyValuePair<string, object>(nameof(CapacitySummaryFlatData.TicketDemand), RoundValue(_capacitySummary.TicketDemand));
            yield return new KeyValuePair<string, object>(nameof(CapacitySummaryFlatData.TotalCapacity), RoundValue(_capacitySummary.TotalCapacity));
            yield return new KeyValuePair<string, object>(nameof(CapacitySummaryFlatData.TotalDemand), RoundValue(_capacitySummary.TotalDemand));
            yield return new KeyValuePair<string, object>(nameof(CapacitySummaryFlatData.TotalTickets), _capacitySummary.TotalTickets.FormatNumber());
            yield return new KeyValuePair<string, object>(nameof(CapacitySummaryFlatData.UnplannedAllowance), _capacitySummary.UnplannedAllowance.FormatNumber());
        }

        IEnumerator IEnumerable.GetEnumerator()
        {
            return GetEnumerator();
        }

        static string RoundValue(float num)
        {
            if (num < 0)
                return ((int)Math.Floor(num)).FormatNumber();
            else
                return ((int)Math.Ceiling(num)).FormatNumber();
        }
    }
}
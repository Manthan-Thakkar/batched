namespace Batched.Reporting.Contracts
{
    public class FilterData
    {
        public string FacilityId { get; set; }
        public string FacilityName { get; set; }
        public string WorkcenterId { get; set; }
        public string WorkcenterName { get; set; }
        public string EquipmentId { get; set; }
        public string EquipmentName { get; set; }
        public List<ValueStreamDto> ValueStreams { get; set; }
    }

    public class EquipemntDetailsData : FilterData
    {
        public int MinLeadTime { get; set; }
    }
}
namespace Batched.Reporting.Contracts.Models
{
    public class EquipmentDowntimeDto
    {
        public string EquipmentId { get; set; }
        public string FacilityId { get; set; }
        public float DownTimeHours { get; set; }
    }

    public class PlannedDowntimeHours
    {
        public string EquipmentId { get; set; }
        public string FacilityId { get; set; }
        public double PlannedDowntime { get; set; }
    }

    public class FacilityHolidaysCount
    {
        public string FacilityId { get; set; }  
        public int TotalHolidays { get; set; }
    }

    public class FacilityWiseHolidays
    {
        public string FacilityId { get; set; }
        public List<DateTime>  Holidays { get; set; }
    }
}

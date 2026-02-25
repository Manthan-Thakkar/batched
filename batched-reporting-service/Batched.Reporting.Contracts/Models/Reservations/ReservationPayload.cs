namespace Batched.Reporting.Contracts.Models
{ 
    public class ReservationPayload
    {
        public string Name { get; set; }
        public string FacilityId { get; set; }
        public List<WorkcenterReservationPayload> WorkcenterReservations { get; set; } = new List<WorkcenterReservationPayload>();
        public List<string> Customers { get; set; } = new List<string>();
        public DateTime StartDate { get; set; }
        public bool IsRecurring { get; set; } 
        public ReservationRecurrencePayload ReservationRecurrence {  get; set; }
        public int ExpirationDays { get; set; }
        public string CreatedBy { get; set; }

    }

    public class EditReservationPayload : ReservationPayload
    {
        public string Id { get; set; }  
    }

    public class ReservationRecurrencePayload
    {
        public string RecurrenceType { get; set; }
        public int Frequency { get; set; }
        public bool IsRecurringMonthlyOnWeekDay { get; set; }
        public int? RecurrenceDay { get; set; }
        public string RecurrenceMonth { get; set; }
        public List<string> RecurrenceWeekDays { get; set; } = new List<string>();
        public string RecurrenceDayOfWeekIndex { get; set; }
        public DateTime? EndDate { get; set; }    
    }

    public class WorkcenterReservationPayload
    {
        public string WorkcenterId { get; set; }
        public string WorkcenterName { get; set; }
        public int ReservedHours { get; set; }
        public List<WorkcenterEquipmentReservationPayload> EquipmentReservations { get; set; } = new List<WorkcenterEquipmentReservationPayload>();
    }

    public class WorkcenterEquipmentReservationPayload
    {
        public string EquipmentId { get; set; }
        public int ReservedHours { get; set; }
    }

    public class DuplicateReservationValidationDto
    {
        public string ReservationName { get; set; }
        public string FacilityId { get; set; }
        public string CustomerId { get; set; }
        public string WorkcenterId { get; set; }
        public string EquipmentId { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime? EndDate { get; set; }
    }
}

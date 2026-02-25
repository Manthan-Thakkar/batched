using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Batched.Reporting.Contracts
{
    public class Schedule
    {
        public string Id { get; set; }
        public string TicketNumber { get; set; }
        public bool Pinned { get; set; }
        public string PinType { get; set; }
        public string Status { get; set; }
        public bool IsOnPress { get; set; }
        public double? TaskMinutes { get; set; }
        public double? ChangeoverMinutes { get; set; }
        public string StartsAt { get; set; }
        public string EndsAt { get; set; }
        public string EquipmentId { get; set; }
        public string TaskName { get; set; }
        public string CustomerName { get; set; }
        public DateTime CreatedOn { get; set; }

        public string ShipByDateTime { get; set; }
        public string Substrate { get; set; }
        public decimal StockWidth { get; set; }
        public string MainTool { get; set; }
        public decimal EstimatedMeters { get; set; }
        public string GeneralDescription { get; set; }
        public decimal CoreSize { get; set; }
        public int NumberOfCores { get; set; }
        public decimal TicketPoints { get; set; }
        public string Varnish { get; set; }
        public string Colors { get; set; }
        public string MasterRollNumber { get; set; }
        public bool IsMasterRoll { get; set; }
        public string SchedulingNotes { get; set; }
        public string ForcedGroup { get; set; }
        public bool IsManuallyScheduled { get; set; }
        public bool FeasibilityOverride { get; set; }
        public bool IsTicketEdited { get; set; }
        public string TicketId { get; set; }
        public bool IsFirstDay { get; set; }
        public short TaskSequence { get; set; }
        public short TicketCategory { get; set; }
        public short WorkcenterMaterialTicketCategory { get; set; }
        public bool IsCompletingOnTime { get; set; }
    }
}

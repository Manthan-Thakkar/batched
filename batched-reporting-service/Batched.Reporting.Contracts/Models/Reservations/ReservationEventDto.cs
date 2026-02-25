using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Batched.Reporting.Contracts.Models.Reservations
{
    public class ReservationEventDto
    {
        public string Id { get; set; }
        public DateTime Date { get; set; }
        public string ReservationId { get; set; }   
        public string WorkcenterId { get; set; }
        public string EquipmentId { get; set; }
        public float ActualDemand { get; set; }
        public float NetReservedDemand { get; set; }
    }
}

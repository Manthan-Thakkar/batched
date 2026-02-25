namespace Batched.Reporting.Contracts.Models
{
    /// <summary>
    /// The response object for workcenter details associated with reservation.
    /// </summary>
    public class WorkcenterReservation
    {
        /// <summary>
        /// Id of the workcenter associated to the reservation.
        /// </summary>
        /// <example>ead00d5d-4948-438c-86c1-e84acdce7349</example>
        public string WorkcenterId { get; set; }

        /// <summary>
        /// Name of the workcenter associated to the reservation.
        /// </summary>
        /// <example>Flexo Press</example>
        public string WorkcenterName { get; set; }

        /// <summary>
        /// Number of hours reserved for the workcenter.
        /// </summary>
        /// <example>20</example>
        public int ReservedHours { get; set; }

        /// <summary>
        /// Equipments which are reserved in the workcenter.
        /// </summary>
        public List<EquipmentReservation> EquipmentReservations { get; set; }  = new List<EquipmentReservation>();  
    }
}

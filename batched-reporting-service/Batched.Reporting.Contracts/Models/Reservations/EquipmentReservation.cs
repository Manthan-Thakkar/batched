namespace Batched.Reporting.Contracts.Models
{
    /// <summary>
    /// The response object of equipments associated with the workcenter of reservation.
    /// </summary>
    public class EquipmentReservation
    {
        /// <summary>
        /// Id of the Equipment associated to the workcenter reservation.
        /// </summary>
        /// <example>ead00d5d-4948-438c-86c1-e84acdce7349</example>
        public string EquipmentId { get; set; }

        /// <summary>
        /// Name of the Equipment associated to the workcenter reservation.
        /// </summary>
        /// <example>2-A</example>
        public string EquipmentName { get; set; }

        /// <summary>
        /// Number of hours reserved for the equipment.
        /// </summary>
        /// <example>15</example>
        public int ReservedHours { get; set; }
    }
}

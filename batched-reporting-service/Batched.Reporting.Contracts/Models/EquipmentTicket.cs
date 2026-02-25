namespace Batched.Reporting.Contracts
{
    public class EquipmentTicket
    {
        public string EquipmentId { get; set; }
        public List<TicketFilter> Tickets { get; set; }
    }

    public class EquipmentStagingTickets
    {
        public string EquipmentId { get; set; }
        public List<string> Tickets { get; set; }
    }
}

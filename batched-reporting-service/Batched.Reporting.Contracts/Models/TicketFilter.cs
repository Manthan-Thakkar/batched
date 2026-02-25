namespace Batched.Reporting.Contracts
{
    public class TicketFilter
    {
        public string SourceTicketId { get; set; }
        public bool IsScheduled { get; set; }
    }
}
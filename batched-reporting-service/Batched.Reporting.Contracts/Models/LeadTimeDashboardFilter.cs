namespace Batched.Reporting.Contracts
{
    public class LeadTimeDashboardFilter : FilterData
    {
        public LeadTimeDashboardFilter()
        {
            Tickets = new List<TicketFilter>();
        }

        public List<TicketFilter> Tickets { get; set; }
    }
}

using Batched.Common.Data.Tenants.Sql.Models;

namespace Batched.Reporting.Test.MockedEntities
{
    public class MockedTicketMaster
    {
        public static List<TicketMaster> GetTickets()
        {
            return new List<TicketMaster>
            {
                new() { Id = "ticket1", SourceTicketId = "srcTicket1" },
                new() { Id = "ticket2", SourceTicketId = "srcTicket2" },
                new() { Id = "ticket3", SourceTicketId = "srcTicket3" },
                new() { Id = "ticket4", SourceTicketId = "srcTicket4" },
                new() { Id = "ticket5", SourceTicketId = "srcTicket5" },
                new() { Id = "ticket6", SourceTicketId = "srcTicket6" },
            };
        }
    }
}

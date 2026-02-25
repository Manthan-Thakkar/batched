
using Batched.Common.Data.Tenants.Sql.Models;

namespace Batched.Reporting.Test.MockedEntities
{
    public class MockedTicketShipping
    {
        internal static List<TicketShipping> GetTicketShipping()
        {
            return new List<TicketShipping>
            {
                new() { TicketId = "ticket1", ShipByDateTime = DateTime.Now.AddDays(20)},
                new() { TicketId = "ticket2", ShipByDateTime = DateTime.Now.AddDays(20)},
                new() { TicketId = "ticket3", ShipByDateTime = DateTime.Now.AddDays(20)},
                new() { TicketId = "ticket4", ShipByDateTime = DateTime.Now.AddDays(20)},
                new() { TicketId = "ticket5", ShipByDateTime = DateTime.Now.AddDays(50)},
                new() { TicketId = "ticket6", ShipByDateTime = null},
            };
        }
    }
}

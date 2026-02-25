using Batched.Common.Data.Tenants.Sql.Models;

namespace Batched.Reporting.Test.MockedEntities
{
    public class MockedTicketTask
    {
        public static List<TicketTask> GetTicketTasks()
        {
            return new List<TicketTask>
            {
                new() {Ticket=GetTicket("ticket1"), TicketId = "ticket1", OriginalEquipmentId = "78883DD5-CD13-4AD0-A8F1-3418BAB89C5B", TaskName = "Press", IsComplete = true},
                new() {Ticket=GetTicket("ticket1"), TicketId = "ticket1", OriginalEquipmentId = "D2CB3B43-5110-4956-BB09-EDD8EE54C179", TaskName = "Equip", IsComplete = true},
                new() {Ticket=GetTicket("ticket2"), TicketId = "ticket2", OriginalEquipmentId = "78883DD5-CD13-4AD0-A8F1-3418BAB89C5B", TaskName = "Press", IsComplete = false},
                new() {Ticket=GetTicket("ticket3"), TicketId = "ticket3", OriginalEquipmentId = "4CC6D48F-831E-4E84-9A9C-0A91C549049E", TaskName = "Equip", IsComplete = false},
                new() {Ticket=GetTicket("ticket4"), TicketId = "ticket4", OriginalEquipmentId = "D2CB3B43-5110-4956-BB09-EDD8EE54C179", TaskName = "Press", IsComplete = false},
                new() {Ticket=GetTicket("ticket4"), TicketId = "ticket4", OriginalEquipmentId = "235D50BB-C972-4B26-B867-804AA904A847", TaskName = "Equip", IsComplete = false},
                new() {Ticket=GetTicket("ticket5"), TicketId = "ticket5", OriginalEquipmentId = "235D50BB-C972-4B26-B867-804AA904A847", TaskName = "Press", IsComplete = true},
                new() {Ticket=GetTicket("ticket5"), TicketId = "ticket5", OriginalEquipmentId = "235D50BB-C972-4B26-B867-804AA904A847", TaskName = "Equip", IsComplete = false},
                new() {Ticket=GetTicket("ticket6"), TicketId = "ticket6", OriginalEquipmentId = "29EDFCB6-1DE1-4C41-A8A3-D789A64A756D", TaskName = "Press", IsComplete = false},
            };
        }
        private static TicketMaster GetTicket(string ticketid)
        { 
            return MockedTicketMaster.GetTickets().Where(x => x.Id == ticketid).FirstOrDefault();
        }
    }
}

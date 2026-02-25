using Batched.Common;
namespace Batched.Reporting.Contracts.Models.LeadTimeManager
{
    public class OpenTicketDetailsResponse
    {
        public List<dynamic> OpenTickets { get; set; }
    }

    public class EquipmentValueStreams
    {
        public string EquipmentId { get; set; }
        public List<string> ValueStreams { get; set; } = new();
    }
}

using Batched.Reporting.Shared;
using ContractModels = Batched.Reporting.Contracts.Models.LeadTimeManager;
using WebModels = Batched.Reporting.Web.Models.LeadTimeManager;

namespace Batched.Reporting.Web.Translators
{
    public static class LeadTimeTranslator
    {
        public static ContractModels.LeadTimeManagerFilters Translate(this WebModels.LeadTimeManagerFilters request)
        {
            return new ContractModels.LeadTimeManagerFilters
            {
                StartDate = request.StartDate,
                EndDate = request.EndDate,
                Facilities = request.Facilities,
                ValueStreams = request.ValueStreams,
                Workcenters = request.Workcenters,
                Equipments = request.Equipments,
                Tickets = request.Tickets,
                ScheduleStatus = request.ScheduleStatus,
                ReportName = request.ReportName,
                SortField = request.SortField,
                SortBy = request.SortBy,
                ViewId = request.ViewId
            };
        }

        public static WebModels.OpenTicketDetailsResponse Translate(this ContractModels.OpenTicketDetailsResponse request)
        {
            return new WebModels.OpenTicketDetailsResponse
            {
                OpenTickets = request.OpenTickets
            };
        }
    }
}
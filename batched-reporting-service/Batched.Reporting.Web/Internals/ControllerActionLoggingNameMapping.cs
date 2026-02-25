namespace Batched.Reporting.Web.Internals
{
    internal class ControllerActionLoggingNameMapping
    {
        public static Dictionary<string, Map> Map = new Dictionary<string, Map>(StringComparer.InvariantCultureIgnoreCase)
        {
            {
                // "healthcheck" is controller got from routemap.
                "healthcheck", Web.Map.Create
                            .Add(KeyStore.ControllerLogKey, "health")
                            .Add("Check", "check")
            },
            {
                "leadtimedashboard", Web.Map.Create
                            .Add(KeyStore.ControllerLogKey, "lead-time")
                            .Add("GetFilterData", "get-filter-data")
                            .Add("LeadTimeManagerKpi","get-kpi-data")
                            .Add("CapacitySummary", "get-capacity-summary")
                            .Add("CapacityOverview", "get-capacity-overview")
                            .Add("OpenTicketDetails","get-open-ticket-details")
                            .Add("ExportLeadTimeTable","export")
                            .Add("CapacityOutlookOverTime","get-capacity-outlook")
                            .Add("GetLeadTimeExceptions","get-exception")
                            .Add("AddLeadTimeException","add-exception")
                            .Add("EditLeadTimeException","edit-exception")
                            .Add("DeleteLeadTimeExceptionAsync","delete-exception")
            },
            {
                "reservations", Web.Map.Create
                            .Add(KeyStore.ControllerLogKey, "reservations")
                            .Add("AddReservation", "add-reservation")
                            .Add("EditReservation", "edit-reservation")
                            .Add("SearchReservation", "get-reservation")
                            .Add("DeleteReservation", "delete-reservation")
            },
            {
                "stagingrequirement", Web.Map.Create
                            .Add(KeyStore.ControllerLogKey, "staging-requirement")
                            .Add("GetFilterData", "get-filter-data")
                            .Add("GetKPIData", "get-kpi-data")
                            .Add("GetStagingRequirementReportData", "get-staging-report-data")
            }
        };
    }
}

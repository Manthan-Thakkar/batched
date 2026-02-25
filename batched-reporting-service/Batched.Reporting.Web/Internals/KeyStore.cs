namespace Batched.Reporting.Web
{
    internal static class KeyStore
    {
        public const string AppName = "reporting-web";
        public const string ApplicationJson = "application/json";
        public const string ControllerLogKey = "controller";
        public const string ActionLogKey = "action";

        public static class Header
        {
            public const string CorrelationId = "correlationId";
            public const string IpAddress = "userip";
            public const string TenantId = "tenantId";
            public const string TransactionId = "transactionId";
            public const string AcceptLanguage = "accept-language";
            public const string Debug = "debug";
            public const string UserId = "userId";
        }

        public static class Routes
        {
            public const string BaseApiV1 = "api/v1/";

            public const string HealthController = BaseApiV1 + "health";
            public const string LeadTime = BaseApiV1 + "lead-time";
            public const string Reservations = BaseApiV1 + "reservations";
            public const string StagingRequirement = BaseApiV1 + "staging-requirement";
            public const string Customers = BaseApiV1 + "customers";

            public const string FilterData = "get-filter-data";
            public const string KpiData = "get-kpi-data";
            public const string TicketStagingInfo = "get-ticket-staging-info";
            public const string ReportData = "get-report-data";
            public const string MarkStagingState = "mark-staging-state";
            public const string CapacitySummary = "get-capacity-summary";
            public const string CapacityOverview = "get-capacity-overview";
            public const string OpenTicketDetails = "get-open-ticket-details";
            public const string CapacityOutlook = "get-capacity-outlook";
            public const string Exception = "exception";
            public const string Export = "export";
        }
    }
}

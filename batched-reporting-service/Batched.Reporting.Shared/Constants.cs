namespace Batched.Reporting.Shared
{
    public static class BatchedConstants
    {
        public static class ReportName
        {
            public const string StagingRequirement = "Staging";
            public const string OpenTickets = "OpenTickets";
        }

        public static class TableNames
        {
            public const string CapacitySummary = "CapacitySummary";
            public const string LeadTimeExceptions = "LeadTimeExceptions";
        }

        public static class ToggleNames
        {
            public const string MultiFacilityScheduling = "EnableMultiFacilityScheduling";
        }

        public static class FieldCategory
        {
            public const string Ticket = "Ticket";
            public const string TicketAttribute = "TicketAttribute";
            public const string StagingComponent = "StagingComponent";
            public const string ExportStagingStatus = "ExportStagingStatus";
        }

        public static class StagingRequirementReportConstant
        {
            public static Dictionary<string, List<string>> StagingRequirementAttributes = new()
            {
                {
                    "Art Proofs", new List<string>() { "ProofStatus" }
                },
                {
                    "Plates", new List<string>() { "PlateID" }
                },
                {
                    "Inks", new List<string>() { "Colors" }
                },
                {
                    "Cylinders", new List<string>() { "Cylinders" }
                },
                {
                    "Tools", new List<string>() { "Tools" }
                },
                {
                    "Substrates", new List<string>() { "Substrates" }
                },
                {
                    "Cores", new List<string>() { "Cores" }
                }
            };

            public static Dictionary<string, List<string>> StagingRequirementInfoAttributes = new()
            {
                {
                    "Art Proofs", new List<string>() { "ProofStatus", "ProofReceived" }
                },
                {
                    "Plates", new List<string>() { "PlateID", "PlateReceived" }
                },
                {
                    "Inks", new List<string>() { "ColorInfo", "InkReceived" }
                },
                {
                    "Cylinders", new List<string>() { "Cylinders" }
                },
                {
                    "Tools", new List<string>()
                    {
                        "ToolingId", "ToolStatus", "ToolShape",
                        "Tool1Description", "Tool2Description", "Tool3Description", "Tool4Description", "Tool5Description"
                    }
                },
                {
                    "Substrates", new List<string>()
                    {
                        "Stock1Number", "Stock2Number", "Stock3Number",
                        "Stock1Width", "Stock2Width", "Stock3Width",
                        "Stock1Location", "Stock2Location", "Stock3Location",
                        "PlannedStock1Number", "PlannedStock2Number", "PlannedStock3Number",
                        "PlannedStock1Width", "PlannedStock2Width", "PlannedStock3Width"
                    }
                },
                {
                    "Cores", new List<string>() { "Cores", "CoreType", "CoreWidth", "Quantity", "NumLeftoverRolls", "OverRun" }
                }
            };
        }

        public static class ConfigurableViewsReportConstant
        {
            public static List<string> MandatoryColumnList = new()
            {
                "[SR].[Id] AS [scheduleId]",
                "[SR].[startsAt]",
                "[SR].[endsAt]",
                "[SR].[taskMinutes]",
                "[SR].[changeoverMinutes]",

                "[SMC].[ticketId]",
                "[SMC].[ticketNumber]",
                "[SMC].[taskName]",
                "[SMC].[shipByDate]",
                "[SMC].[actualEstTotalHours]",
                "[SMC].[estMaxDueDateTime]",
                "CAST([SMC].[isTicketGeneralNotePresent] AS BIT) AS [isTicketGeneralNotePresent]",

                "ISNULL([ScheduledEM].[FacilityId], [SMC].[FacilityId]) AS [facilityId]",
                "ISNULL([ScheduledEM].[FacilityName], [SMC].[FacilityName]) AS [facilityName]",
                "ISNULL([ScheduledEM].[WorkcenterTypeId], [SMC].[WorkcenterTypeId]) AS [workcenterId]",
                "ISNULL([ScheduledEM].[WorkCenterName], [SMC].[WorkCenterName]) AS [workcenterName]",
                "[SMC].[originalEquipmentId]",
                "[SMC].[OriginalEquipmentName] AS [originalEquipmentName]",
                "[SR].[equipmentId]",
                "[ScheduledEM].[Name] AS [equipmentName]"
            };

            public static List<string> ExcludedColumnList = new()
            {
                "TaskStatus",
                "ScheduleId",
                "StartsAt",
                "EndsAt",
                "TaskMinutes",
                "ChangeoverMinutes",
                "TicketId",
                "TicketNumber",
                "TaskName",
                "ShipByDate",
                "ActualEstTotalHours",
                "EstMaxDueDateTime",
                "IsTicketGeneralNotePresent",
                "FacilityId",
                "FacilityName",
                "WorkcenterId",
                "WorkcenterName",
                "OriginalEquipmentId",
                "OriginalEquipmentName",
                "EquipmentId",
                "EquipmentName",
                "ScheduledHours"
            };

            public static Dictionary<string, string> ColumnsOtherThanCacheTable = new()
            {
                { "TicketPriority", "[SMC].[TicketPriority] AS [priority]" },
                { "TicketStatus", "[SMC].[TicketStatus] AS [status]" },
                { "WIPValue", "COALESCE(1 - (CAST([SMC].[ActualQuantity] AS REAL) / NULLIF(CAST([SMC].[Quantity] AS REAL), 0)), 0) * [SMC].[EstTotalRevenue] as [wipValue]" }
            };
        }
    }
}
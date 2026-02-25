namespace Batched.Reporting.Core
{
    public static class Constants
    {
        public static class CacheKey
        {
            public const string GetAllMetaData = "all-dsl-metadata";
            public const string GetAllTenantDatabases = "all-tenant-databases";

        }

        public static class DslCategory
        {
            public const string Attribute = "Attribute";
            public const string Constraint = "Constraint";
            public const string Changeover = "Changeover";
        }

        public static class EquipmentLevel
        {
            public const string Facility = "Facility";
            public const string ValueStream = "ValueStream";
            public const string Workcenter = "Workcenter";
            public const string Equipment = "Equipment";
        }

        public static class TaskStatus
        {
            public const string Completed = "Complete";
            public const string Late = "Late";
            public const string Unscheduled = "Unscheduled";
            public const string AtRisk = "At Risk";
            public const string Behind = "Behind";
            public const string OnTrack = "On Track";
            public const string OnPress = "On Press";

        }

        public static class RecurrenceType
        {
            public const string Daily = "Daily";
            public const string Monthly = "Monthly";
            public const string Weekly = "Weekly";
            public const string Yearly = "Yearly";
        }

        public static int MaxEquipmentCalendarGenerationDays = 180;
    }
}

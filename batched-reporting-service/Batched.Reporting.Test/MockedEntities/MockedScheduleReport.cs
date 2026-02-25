using Batched.Common.Data.Tenants.Sql.Models;
using Newtonsoft.Json;

namespace Batched.Reporting.Test.MockedEntities
{
    internal class MockedScheduleReport
    {
        internal static List<ScheduleReport> GetScheduleReports()
        {
            return new List<ScheduleReport>
            {
                new () { SourceTicketId = "srcTicket3", TaskName = "Equip" }
            };
        }

        public static List<ScheduleReport> GetScheduleReportForStaging()
        {
            var jsonScheduleReport = File.ReadAllText("./Data/ScheduleReport.json");
            var scheduleReport = JsonConvert.DeserializeObject<List<ScheduleReport>>(jsonScheduleReport);
            return scheduleReport;
        }
    }
}

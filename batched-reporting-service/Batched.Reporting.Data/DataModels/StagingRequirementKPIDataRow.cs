using Batched.Common.Data.Sql.Extensions;
using System.Data;

namespace Batched.Scheduling.Data
{
    internal class StagingRequirementKPIDataRow : DataRowParser
    {
        public string TicketId { get; set; }
        public string TicketNumber { get; set; }
        public string TaskName { get; set; }
        public string StagingNameKey { get; set; }
        public bool? IsStaged { get; set; }
        public string StagingReq {  get; set; }
        public DateTime StartsAt {  get; set; }
        public DateTime EndsAt { get; set; }

        public override void Fill(DataRow dataRow)
        {
            if (dataRow.Table.Columns.Contains("TicketId") && !dataRow.IsNull("TicketId"))
                TicketId = dataRow["TicketId"].ToString();

            if (dataRow.Table.Columns.Contains("TicketNumber") && !dataRow.IsNull("TicketNumber"))
                TicketNumber = dataRow["TicketNumber"].ToString();

            if (dataRow.Table.Columns.Contains("TaskName") && !dataRow.IsNull("TaskName"))
                TaskName = dataRow["TaskName"].ToString();

            if (dataRow.Table.Columns.Contains("StagingNameKey") && !dataRow.IsNull("StagingNameKey"))
                StagingNameKey = dataRow["StagingNameKey"].ToString();

            if (dataRow.Table.Columns.Contains("IsStaged") && !dataRow.IsNull("IsStaged"))
                IsStaged = Convert.ToBoolean(dataRow["IsStaged"]);

            if (dataRow.Table.Columns.Contains("StagingReq") && !dataRow.IsNull("StagingReq"))
                StagingReq = dataRow["StagingReq"].ToString();

            if (dataRow.Table.Columns.Contains("StartsAt") && !dataRow.IsNull("StartsAt"))
                StartsAt = dataRow.Field<DateTime>("StartsAt");

            if (dataRow.Table.Columns.Contains("EndsAt") && !dataRow.IsNull("EndsAt"))
                EndsAt = dataRow.Field<DateTime>("EndsAt");
        }
    }
}
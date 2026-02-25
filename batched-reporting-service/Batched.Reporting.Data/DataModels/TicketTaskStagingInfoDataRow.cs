using Batched.Common.Data.Sql.Extensions;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Batched.Reporting.Data.DataModels
{
    internal class TicketTaskStagingInfoDataRow : DataRowParser
    {
        public string TicketId { get; set; }
        public string TaskName { get; set; }
        public string StagingNameKey { get; set; }
        public bool? IsStaged { get; set; }
        public override void Fill(DataRow dataRow)
        {
            TicketId = dataRow.GetString("TicketId");
            TaskName = dataRow.GetString("TaskName");
            StagingNameKey = dataRow.GetString("StagingNameKey");
            IsStaged = !dataRow.IsNull("IsStaged") ? dataRow.Field<bool>("IsStaged") : null;
        }
    }
}

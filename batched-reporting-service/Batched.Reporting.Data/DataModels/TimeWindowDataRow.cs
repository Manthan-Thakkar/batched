using Batched.Common.Data.Sql.Extensions;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Batched.Reporting.Data.DataModels
{
    internal class TimeWindowDatarow : DataRowParser
    {
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }

        public override void Fill(DataRow dataRow)
        {
            StartDate = !dataRow.IsNull("StartDate") ? dataRow.Field<DateTime>("StartDate") : DateTime.MinValue;
            EndDate = !dataRow.IsNull("EndDate") ? dataRow.Field<DateTime>("EndDate") : DateTime.MinValue;
        }
    }
}

using Batched.Common.Data.Sql.Extensions;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Batched.Reporting.Data.DataModels
{
    internal class TotalCountDataRow : DataRowParser
    {
        public int TotalCount { get; set; }

        public override void Fill(DataRow dataRow)
        {
            TotalCount = dataRow.Field<int>("TotalCount");
        }
    }
}

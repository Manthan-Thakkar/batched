using Batched.Common.Data.Sql.Extensions;
using System.Data;
using System.Text;

namespace Batched.Reporting.Data.DataModels
{
    public class TicketAttributeValueDataRow : DataRowParser
    {
        public string TicketId { get; set; }
        public string Name { get; set; }
        public string Value { get; set; }

        public override void Fill(DataRow dataRow)
        {
            if (dataRow.Table.Columns.Contains("TicketId") && !dataRow.IsNull("TicketId"))
                TicketId = dataRow.GetString("TicketId");

            if (dataRow.Table.Columns.Contains("Value") && !dataRow.IsNull("Value"))
                Value = dataRow.GetString("Value");

            if (dataRow.Table.Columns.Contains("Name") && !dataRow.IsNull("Name"))
                Name = dataRow.GetString("Name");
        }
    }
}

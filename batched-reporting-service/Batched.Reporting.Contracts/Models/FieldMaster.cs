using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Batched.Reporting.Contracts
{
    [Serializable]
    public class FieldMaster
    {
        public string Id { get; set; }
        public string Name { get; set; }
        public string JsonFieldName { get; set; }
        public string ReportId { get; set; }
        public string Action { get; set; }
    }
}

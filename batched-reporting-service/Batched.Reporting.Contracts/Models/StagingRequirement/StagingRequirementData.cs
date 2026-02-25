using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Batched.Reporting.Contracts.Models.StagingRequirement
{
    public class StagingRequirementData
    {
        public List<ScheduledTasksStagingData> ScheduledTasksStagingData { get; set; }  = new List<ScheduledTasksStagingData>();
        public int TotalCount { get; set; }
    }
}

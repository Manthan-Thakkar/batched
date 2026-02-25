using Batched.Reporting.Contracts;
using Batched.Reporting.Data.DataModels;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Batched.Reporting.Data.Translators
{
    internal static class ScheduleTransalator
    {
        public static List<string> GetValueStreams(string valuestreams)
        {
            var response = new List<string>();
            if (string.IsNullOrEmpty(valuestreams) == false)
            {
                string[] tasksArray = valuestreams.Split(", ");
                response.AddRange(tasksArray.ToList());
            }
            return response;
        }
    }
}

using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Batched.Reporting.Contracts.Models
{
    public class CustomerDetails
    {
        public string CustomerId { get; set; }  
        public string SourceCustomerId { get; set; }
        public string CustomerName { get; set; }
    }
}

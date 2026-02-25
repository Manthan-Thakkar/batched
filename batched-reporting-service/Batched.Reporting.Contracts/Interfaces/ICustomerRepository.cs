using Batched.Common.Data.Tenants.Sql.Models;
using Batched.Reporting.Contracts.Models;

namespace Batched.Reporting.Contracts.Interfaces
{
    public interface ICustomerRepository
    {
        Task<List<CustomerDetails>> GetAllCustomerDetailsAsync();
    }
}

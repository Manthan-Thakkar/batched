using Batched.Reporting.Contracts.Models;

namespace Batched.Reporting.Contracts.Interfaces
{
    public interface ICustomerService
    {
        Task<List<CustomerDetails>> GetCustomerDetailsAsync();
    }
}

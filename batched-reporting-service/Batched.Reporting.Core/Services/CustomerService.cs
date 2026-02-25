using Batched.Reporting.Contracts.Interfaces;
using Batched.Reporting.Contracts.Models;
using Batched.Reporting.Core.Translators;

namespace Batched.Reporting.Core.Services
{
    public class CustomerService : ICustomerService
    {
        private readonly ICustomerRepository _customerRepository;

        public CustomerService(ICustomerRepository customerRepository)
        {
            _customerRepository = customerRepository;
        }

        public async Task<List<CustomerDetails>> GetCustomerDetailsAsync()
        {
            return await _customerRepository.GetAllCustomerDetailsAsync();
        } 
    }
}

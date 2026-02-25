using Batched.Common.Auth;
using Batched.Reporting.Contracts.Interfaces;
using Batched.Reporting.Contracts.Models;
using Batched.Reporting.Web.Filters;
using Microsoft.AspNetCore.Mvc;

namespace Batched.Reporting.Web.Controllers
{
    [ApiController]
    [Produces(KeyStore.ApplicationJson)]
    [Route(KeyStore.Routes.Customers)]
    [BatchedAuthorize]
    [BusinessEntity("Reservation")]
    [TenantContext]
    public class CustomerController : ControllerBase
    {
        private readonly ICustomerService _customerService;

        public CustomerController(ICustomerService customerService)
        {
            _customerService = customerService;
        }
            
        [HttpGet]
        [Access("Read")]
        [ProducesResponseType(typeof(List<CustomerDetails>), StatusCodes.Status200OK)]
        public async Task<IActionResult> GetCustomerDetailsAsync()
        {
            var result = await _customerService.GetCustomerDetailsAsync();
            return Ok(result);
        }
    }
}

using Microsoft.AspNetCore.Mvc;
using Batched.Reporting.Contracts;

namespace Batched.Reporting.Web.Controllers
{

    /// <summary>
    /// Health check controller
    /// </summary>
    [ApiController]
    [Produces(KeyStore.ApplicationJson)]
    [Route(KeyStore.Routes.HealthController)]
    public class HealthCheckController : ControllerBase
    {
        private readonly IHealthCheckService _healthCheckService;
        /// <summary>
        /// HealthCheckController constructor
        /// </summary>
        /// <param name="healthCheckService"> HealthCheckService dependency</param>
        public HealthCheckController(IHealthCheckService healthCheckService)
        {
            _healthCheckService = healthCheckService;
        }
        /// <summary>
        /// Returns the status of the service.
        /// </summary>
        /// <param name="cancellationToken">cancellationToken to manage the aysnc operation</param>
        /// <param name="shouldCheckWithDB">Explicitly checks the db connectivity</param>
        /// <returns>true/false</returns>
        [HttpGet]
        public async Task<IActionResult> CheckAsync([FromQuery] bool shouldCheckWithDB, CancellationToken cancellationToken)
        {
            var response = await _healthCheckService.IsHealthyAsync(shouldCheckWithDB, cancellationToken);
            return Ok(response);
        }
    }
}

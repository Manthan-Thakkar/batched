using Batched.Common.Auth;
using Batched.Reporting.Contracts.Interfaces;
using Batched.Reporting.Contracts.Models;
using Batched.Reporting.Web.Filters;
using Microsoft.AspNetCore.Mvc;

namespace Batched.Reporting.Web.Controllers
{
    /// <summary>
    /// API controller for reservation configurations.
    /// </summary>
    [ApiController]
    [Produces(KeyStore.ApplicationJson)]
    [Route(KeyStore.Routes.Reservations)]
    [BatchedAuthorize]    
    [BusinessEntity("LeadTimeManager")]
    [TenantContext]
    public class ReservationsController : ControllerBase
    {
        private readonly IReservationService _reservationService;

        /// <summary>
        /// Constructor on controller for dependency injection
        /// </summary>
        /// <param name="reservationService"></param>
        public ReservationsController(IReservationService reservationService)
        {
            _reservationService = reservationService;
        }

        /// <summary>
        /// To add the reservation configurations.
        /// </summary>
        [HttpPost]
        [Access("Create")]
        [ProducesResponseType(typeof(AddReservationResponse), StatusCodes.Status200OK)]
        public async Task<IActionResult> AddReservationAsync([FromBody] ReservationPayload payload, CancellationToken cancellationToken)
        {
            var result = await _reservationService.AddReservationAsync(payload, cancellationToken);
            return (Ok(result));
        }

        /// <summary>
        /// To edit the reservation configurations.
        /// </summary>
        [HttpPut]
        [Access("Update")]
        [ProducesResponseType(typeof(EditReservationResponse), StatusCodes.Status200OK)]
        public async Task<IActionResult> EditReservationAsync([FromBody] EditReservationPayload payload, CancellationToken cancellationToken)
        {
            var result = await _reservationService.EditReservationAsync(payload, cancellationToken);
            return (Ok(result));
        }

        /// <summary>
        /// Retrieves all the reservation configurations.
        /// </summary>
        [HttpGet]
        [Access("Read")]
        [ProducesResponseType(typeof(ReservationResponse), StatusCodes.Status200OK)]
        public async Task<IActionResult> SearchReservationAsync([FromQuery] string search, [FromQuery] string sort, [FromQuery] int pageNum
            , [FromQuery] int pageSize, [FromQuery] List<string> facilities, CancellationToken cancellationToken)
        {
            var result = await _reservationService.SearchReservationsAsync(search, sort,pageNum, pageSize, facilities, cancellationToken);
            return Ok(result);
        }

        /// <summary>
        /// To delete the reservation configurations.
        /// </summary>
        [HttpDelete("{reservationId}")]
        [Access("Delete")]
        [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status200OK)]
        public async Task<IActionResult> DeleteReservationAsync(string reservationId, CancellationToken cancellationToken)
        {
            var result = await _reservationService.DeleteReservationAsync(reservationId, cancellationToken);
            return Ok(result);
        }
    }
}
using Batched.Common.Auth;
using Batched.Reporting.Contracts.Interfaces;
using Batched.Reporting.Contracts.Models;
using Batched.Reporting.Web.Filters;
using Batched.Reporting.Web.Models.Export;
using Batched.Reporting.Web.Models.StagingRequirement;
using Batched.Reporting.Web.Translators;
using Microsoft.AspNetCore.Mvc;

namespace Batched.Reporting.Web.Controllers
{
    /// <summary>
    /// API controller for Staging Requirement Report.
    /// </summary>
    [ApiController]
    [Produces(KeyStore.ApplicationJson)]
    [Route(KeyStore.Routes.StagingRequirement)]
    [BatchedAuthorize]
    [BusinessEntity("StagingRequirement")]
    [TenantContext]
    public class StagingRequirementController : ControllerBase
    {
        private readonly IStagingRequirementService _stagingRequirementService;
        private readonly IExportService _exportService;

        /// <summary>
        /// Constructor on controller for dependency injection
        /// </summary>
        /// <param name="stagingRequirementService"></param>
        /// <param name="exportService"></param>
        public StagingRequirementController(IStagingRequirementService stagingRequirementService, IExportService exportService)
        {
            _stagingRequirementService = stagingRequirementService;
            _exportService = exportService;
        }

        /// <summary>
        /// Get All Staging Requirements.
        /// </summary>
        /// <returns>staging requirements</returns>
        [HttpGet]
        [Access("Read")]
        [ProducesResponseType(typeof(StagingRequirementComponents), StatusCodes.Status200OK)]
        public async Task<IActionResult> GetAllStagingRequirementsAsync()
        {
            var response = await _stagingRequirementService.GetAllStagingRequirementsAsync();
            return Ok(response.TranslateStagingRequirementComponent());
        }

        /// <summary>
        /// Filter data for the filters shown on Staging Requirement Report.
        /// </summary>
        /// <param name="payload">userAssignedFacilties, start and end date to filter equipments and tickets</param>
        /// <param name="cancellationToken">To cancel the task</param>
        /// <returns>filter data</returns>
        [HttpPost]
        [Access("Read")]
        [Route(KeyStore.Routes.FilterData)]
        [ProducesResponseType(typeof(List<StagingReportFilterData>), StatusCodes.Status200OK)]
        public async Task<IActionResult> GetFilterDataAsync([FromBody] StagingRequirementFilterDataPayload payload, CancellationToken cancellationToken)
        {
            var response = await _stagingRequirementService.GetFilterDataAsync(payload.Translate(), cancellationToken);
            return Ok(response.Translate());
        }

        /// <summary>
        /// KPI data shown on Staging Requirement Report.
        /// </summary>
        /// <param name="filter">Facilities, value streams, workcenters, equipments, tickets and components</param>
        /// <param name="cancellationToken">To cancel the task</param>
        /// <returns>KPI data</returns>
        [HttpPost]
        [Access("Read")]
        [Route(KeyStore.Routes.KpiData)]
        [ProducesResponseType(typeof(StagingRequirementKPIData), StatusCodes.Status200OK)]
        public async Task<IActionResult> GetKPIDataAsync([FromBody] StagingRequirementFilter filter, CancellationToken cancellationToken)
        {
            var response = await _stagingRequirementService.GetKPIDataAsync(filter.Translate(), cancellationToken);
            return Ok(response.Translate());
        }


        /// <summary>
        /// Data shown on Staging Requirement Report.
        /// </summary>
        /// <param name="filter">Facilities, value streams, workcenters, equipments, tickets and components</param>
        /// <param name="cancellationToken">To cancel the task</param>
        /// <returns>Staging requirement report data</returns>
        [HttpPost]
        [Access("Read")]
        [Route(KeyStore.Routes.ReportData)]
        [ProducesResponseType(typeof(StagingRequirementData), StatusCodes.Status200OK)]
        public async Task<IActionResult> GetStagingRequirementReportDataAsync([FromBody] StagingRequirementReportFilter filter, CancellationToken cancellationToken)
        {
            var response = await _stagingRequirementService.GetStagingRequirementReportAsync(filter.Translate(), cancellationToken);
            return Ok(response.Translate());
        }

        /// <summary>
        /// API to mark Ticket task staging requirement as staged or unstaged.
        /// </summary>
        /// <param name="payload">Ticket task level staging component states which need to change</param>
        /// <param name="cancellationToken">To cancel the task</param>
        /// <returns>Success response</returns>
        [HttpPost]
        [Access("Read")]
        [Route(KeyStore.Routes.MarkStagingState)]
        [ProducesResponseType(StatusCodes.Status200OK)]
        public async Task<IActionResult> UpdateTicketTaskStagingStateAsync([FromBody] List<TicketTaskStagingPayload> payload, CancellationToken cancellationToken)
        {
            await _stagingRequirementService.UpdateTicketTaskStagingStateAsync(payload.Translate(), cancellationToken);
            return Ok();
        }

        /// <summary>
        /// API to fetch ticket task staging info.
        /// </summary>
        /// <param name="stagingPayload">Ticket task payload consists of ticketId, ticketNumber and taskname.</param>
        /// <param name="cancellationToken">To cancel the task</param>
        /// <returns>Staging info</returns>
        [HttpPost]
        [Access("Read")]
        [Route(KeyStore.Routes.TicketStagingInfo)]
        [ProducesResponseType(typeof(TicketStagingInfo), StatusCodes.Status200OK)]
        public async Task<IActionResult> GetTicketTaskInfoAsync([FromBody] TicketTaskStagingInfoPayload stagingPayload, CancellationToken cancellationToken)
        {
            var response = await _stagingRequirementService.GetTicketTaskInfoAsync(stagingPayload.Translate(), cancellationToken);
            return Ok(response.Translate());
        }

        /// <summary>
        /// Export staging requirement report.
        /// </summary>
        /// <param name="exportRequest">Filter data by Facilities, ValueStreams, Workcenters, Equipments, Tickets, ScheduleStatus, StartDate and EndDate and Export the data into required file format</param>
        /// <param name="cancellationToken">To cancel the task</param>
        /// <returns>Export response consist of status and URL to download the exported file</returns>
        [HttpPost]
        [Access("Read")]
        [Route(KeyStore.Routes.Export)]
        [ProducesResponseType(typeof(ExportData), StatusCodes.Status200OK)]
        public async Task<IActionResult> ExportStagingRequirementAsync([FromBody] ExportStagingRequirementReportRequest exportRequest, CancellationToken cancellationToken)
        {
            var response = await _exportService.ExportAsync(exportRequest.Translate(), cancellationToken);
            return Ok(response.Translate());
        }
    }
}
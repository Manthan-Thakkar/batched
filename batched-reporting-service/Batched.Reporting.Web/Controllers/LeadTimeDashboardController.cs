using Batched.Common.Auth;
using Batched.Reporting.Contracts;
using Batched.Reporting.Contracts.Interfaces;
using Batched.Reporting.Web.Filters;
using Batched.Reporting.Web.Models.Export;
using Batched.Reporting.Web.Models.LeadTimeException;
using Batched.Reporting.Web.Models.LeadTimeManager;
using Batched.Reporting.Web.Translators;
using Microsoft.AspNetCore.Mvc;
using LeadTimeContractModels = Batched.Reporting.Contracts.Models.LeadTimeManager;


namespace Batched.Reporting.Web.Controllers
{
    /// <summary>
    /// API controller for LeadTime Manager Dashboard and related data.
    /// </summary>
    [ApiController]
    [Produces(KeyStore.ApplicationJson)]
    [Route(KeyStore.Routes.LeadTime)]
    [BatchedAuthorize]
    [BusinessEntity("LeadTimeManager")]
    [BusinessEntity("LeadTimeSummary")]
    [TenantContext]
    public class LeadTimeDashboardController : ControllerBase
    {
        private readonly ILeadTimeService _leadTimeReportService;
        private readonly ILeadTimeExceptionsService _leadTimeExceptionsService;
        private readonly IExportService _exportService;

        /// <summary>
        /// Constructor on controller for dependency injection
        /// </summary>
        /// <param name="leadTimeReportService"></param>
        /// <param name="leadTimeExceptionsService"></param>
        /// <param name="exportService"></param>
        public LeadTimeDashboardController(ILeadTimeService leadTimeReportService, ILeadTimeExceptionsService leadTimeExceptionsService, IExportService exportService)
        {
            _leadTimeReportService = leadTimeReportService;
            _leadTimeExceptionsService = leadTimeExceptionsService;
            _exportService = exportService;
        }

        /// <summary>
        /// Filter data for the filters shown on lead time manager dashboard.
        /// </summary>
        /// <param name="filter">userAssignedFacilties, from and to date to filter equipments and tickets</param>
        /// <param name="cancellationToken">To cancel the task</param>
        /// <returns>filter data</returns>
        [HttpPost]
        [TenantContext]
        [Access("Read")]
        [Route(KeyStore.Routes.FilterData)]
        [ProducesResponseType(typeof(List<LeadTimeDashboardFilter>), StatusCodes.Status200OK)]
        public async Task<IActionResult> GetFilterDataAsync(Models.DashboardFilter filter, CancellationToken cancellationToken)
        {
            var dashboardFilter = filter.Translate();
            var filterData = await _leadTimeReportService.GetFilterDataAsync(dashboardFilter, cancellationToken);
            return Ok(filterData);
        }

        /// <summary>
        /// KPI data for the lead time manager dashboard.
        /// </summary>
        /// <param name="filter">Filter data values facilities, valuestreams, workcenters, equipments, from and to date to get the KPI values accordingly</param>
        /// <param name="cancellationToken">To cancel the task</param>
        /// <returns>KPI data</returns>
        [HttpPost]
        [Access("Read")]
        [Route(KeyStore.Routes.KpiData)]
        [ProducesResponseType(typeof(LeadTimeManagerKpi), StatusCodes.Status200OK)]
        public async Task<IActionResult> LeadTimeManagerKpi([FromBody] Models.DashboardFilter filter, CancellationToken cancellationToken)
        {
            var dashboardFilter = filter.Translate();
            var result = await _leadTimeReportService.GetKpiAsync(dashboardFilter, cancellationToken);
            return Ok(result);
        }

        /// <summary>
        /// Capacity Summary data for the lead time manager dashboard.
        /// </summary>
        /// <param name="filter">Filter data values facilities, valuestreams, workcenters, equipments, from and to date to get the KPI values accordingly</param>
        /// <param name="cancellationToken">To cancel the task</param>
        /// <returns>Capacity summary data</returns>
        [HttpPost]
        [Access("Read")]
        [Route(KeyStore.Routes.CapacitySummary)]
        [ProducesResponseType(typeof(CapacitySummaryResponse), StatusCodes.Status200OK)]
        public async Task<IActionResult> CapacitySummary([FromBody] Models.DashboardFilter filter, CancellationToken cancellationToken)
        {
            var dashboardFilter = filter.Translate();
            var result = await _leadTimeReportService.GetCapacitySummaryAsync(dashboardFilter, cancellationToken);
            return Ok(result);
        }

        /// <summary>
        /// Capacity Overview data for the lead time manager dashboard.
        /// </summary>
        /// <param name="filter">Filter data values facilities, valuestreams, workcenters, equipments, from and to date to get the KPI values accordingly</param>
        /// <param name="cancellationToken">To cancel the task</param>
        /// <returns>Daywise Capacity Overview data</returns>
        [HttpPost]
        [Access("Read")]
        [Route(KeyStore.Routes.CapacityOverview)]
        [ProducesResponseType(typeof(CapacityOverviewResponse), StatusCodes.Status200OK)]
        public async Task<IActionResult> CapacityOverviewAsync([FromBody] Models.DashboardFilter filter, CancellationToken cancellationToken)
        {
            var dashboardFilter = filter.Translate();
            var result = await _leadTimeReportService.GetCapacityOverviewAsync(dashboardFilter, cancellationToken);
            return Ok(result);
        }



        /// <summary>
        /// Open Tickets data for the lead time manager dashboard - configurable view.
        /// </summary>
        /// <param name="filter">Filter data values facilities, valuestreams, workcenters, equipments, from and to date to get the KPI values accordingly</param>
        /// <param name="cancellationToken">To cancel the task</param>
        /// <returns>Open Tickets details response.</returns>
        [HttpPost]
        [Access("Read")]
        [Route(KeyStore.Routes.OpenTicketDetails)]
        [ProducesResponseType(typeof(OpenTicketDetailsResponse), StatusCodes.Status200OK)]
        public async Task<IActionResult> OpenTicketDetailsAsync([FromBody] LeadTimeManagerFilters filter, CancellationToken cancellationToken)
        {
            var repsonse = await _leadTimeReportService.GetOpenTicketsLTMAsync(filter.Translate(), cancellationToken);
            return Ok(repsonse.Translate());
        }



        /// <summary>
        /// Capacity outlook over time for the lead time manager dashboard.
        /// </summary>
        /// <param name="filter">Filter data values facilities, valuestreams, workcenters, equipments, from and to date to get the KPI values accordingly</param>
        /// <param name="cancellationToken">To cancel the task</param>
        /// <returns>Capacity outlook over time response.</returns>
        [HttpPost]
        [Access("Read")]
        [Route(KeyStore.Routes.CapacityOutlook)]
        [ProducesResponseType(typeof(LeadTimeContractModels.CapacityOutlookOverTimeResponse), StatusCodes.Status200OK)]
        public async Task<IActionResult> CapacityOutlookOverTimeAsync([FromBody] Models.DashboardFilter filter, CancellationToken cancellationToken)
        {
            var dashboardFilter = filter.Translate();
            var result = await _leadTimeReportService.GetCapacityOutlookOverTimeAsync(dashboardFilter, cancellationToken);
            return Ok(result);
        }

        /// <summary>
        /// Export the tables on lead time manager dashboard.
        /// </summary>
        /// <param name="exportRequest">Filter data by Facilities, ValueStreams, Workcenters, Equipments, Tickets, ScheduleStatus, StartDate and EndDate and Export the data into required file format</param>
        /// <param name="cancellationToken">To cancel the task</param>
        /// <returns>Export response consist of status and URL to download the exported file</returns>
        [HttpPost]
        [Access("Read")]
        [Route(KeyStore.Routes.Export)]
        [ProducesResponseType(typeof(ExportData), StatusCodes.Status200OK)]
        public async Task<IActionResult> ExportLeadTimeTableAsync([FromBody] ExportLeadTimeTableRequest exportRequest, CancellationToken cancellationToken)
        {
            var response = await _exportService.ExportAsync(exportRequest.Translate(), cancellationToken);
            return Ok(response.Translate());
        }

        /// <summary>
        /// Get the lead time exceptions.
        /// </summary>
        /// <param name="cancellationToken">To cancel the task</param>
        /// <returns>Export response consist of status and URL to download the exported file</returns>
        [HttpGet]
        [Access("Read")]
        [Route(KeyStore.Routes.Exception)]
        [ProducesResponseType(typeof(GetExceptionsResponse), StatusCodes.Status200OK)]
        public async Task<IActionResult> GetLeadTimeExceptionsAsync(CancellationToken cancellationToken)
        {
            var response = await _leadTimeExceptionsService.GetLeadTimeExceptionsAsync(cancellationToken);
            return Ok(response.Translate());
        }

        /// <summary>
        /// Add a new lead time exception.
        /// </summary>
        /// <param name="exception">Payload for adding a new exception</param>
        /// <param name="cancellationToken">To cancel the task</param>
        /// <returns>Export response consist of status and URL to download the exported file</returns>
        [HttpPost]
        [Access("Create")]
        [Route(KeyStore.Routes.Exception)]
        [ProducesResponseType(typeof(AddExceptionsResponse), StatusCodes.Status200OK)]
        public async Task<IActionResult> AddLeadTimeExceptionAsync([FromBody] AddExceptionRequest exception, CancellationToken cancellationToken)
        {
            var response = await _leadTimeExceptionsService.AddLeadTimeExceptionAsync(exception.Translate(), cancellationToken);
            return Ok(response.Translate());
        }

        /// <summary>
        /// Edit a lead time exception.
        /// </summary>
        /// <param name="exception">Payload for editing a exception</param>
        /// <param name="cancellationToken">To cancel the task</param>
        /// <returns>Export response consist of status and URL to download the exported file</returns>
        [HttpPut]
        [Access("Update")]
        [Route(KeyStore.Routes.Exception)]
        [ProducesResponseType(typeof(ExceptionResponse), StatusCodes.Status200OK)]
        public async Task<IActionResult> EditLeadTimeExceptionAsync([FromBody] EditExceptionRequest exception, CancellationToken cancellationToken)
        {
            var response = await _leadTimeExceptionsService.EditLeadTimeExceptionAsync(exception.Translate(), cancellationToken);
            return Ok(response.Translate());
        }

        /// <summary>
        /// Delete a lead time exception.
        /// </summary>
        /// <param name="exceptionId">Id of the exception which should be deleted</param>
        /// <param name="cancellationToken">To cancel the task</param>
        /// <returns>Export response consist of status and URL to download the exported file</returns>
        [HttpDelete(KeyStore.Routes.Exception + "/{exceptionId}")]
        [Access("Delete")]
        [ProducesResponseType(typeof(ExceptionResponse), StatusCodes.Status200OK)]
        public async Task<IActionResult> DeleteLeadTimeExceptionAsync(string exceptionId, CancellationToken cancellationToken)
        {
            var response = await _leadTimeExceptionsService.DeleteLeadTimeExceptionAsync(exceptionId, cancellationToken);
            return Ok(response.Translate());
        }
    }
}
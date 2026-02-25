namespace Batched.Reporting.Web.Translators
{
    /// <summary>
    /// trasnslator for dashboard filter object.
    /// </summary>
    public static class DashboardFilterTranslator
    {
        /// <summary>
        /// Translate web model of dashboard filter into contract.
        /// </summary>
        /// <param name="filter">Web model of dashboard filter</param>
        /// <returns>Contract model of dashboard filter</returns>
        public static Contracts.DashboardFilter Translate(this Models.DashboardFilter filter) 
        {
            return new Contracts.DashboardFilter
            {
                Facilities = filter.Facilities ?? new List<string>(),
                ValueStreams = filter.ValueStreams ?? new List<string>(),
                Workcenters = filter.Workcenters ?? new List<string>(),
                Equipments = filter.Equipments ?? new List<string>(), 
                Tickets = filter.Tickets ?? new List<string>(), 
                StartDate = filter.StartDate,
                EndDate = filter.EndDate,
                ScheduleStatus = filter.ScheduleStatus,
            };
        }
    }
}

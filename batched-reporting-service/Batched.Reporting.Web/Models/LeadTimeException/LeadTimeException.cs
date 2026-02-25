namespace Batched.Reporting.Web.Models.LeadTimeException
{
    /// <summary>
    /// Represents an exception related to lead time calculations.
    /// </summary>
    public class LeadTimeException
    {
        /// <summary>
        /// The unique identifier of the lead time exception.
        /// </summary>
        /// <example>"2DCA4FB7-8BBA-4F75-8BBA-983CBF3A626B"</example>
        public string Id { get; set; }

        /// <summary>
        /// The name or description of the lead time exception.
        /// </summary>
        /// <example>"Priority Rule"</example>
        public string Name { get; set; }

        /// <summary>
        /// The reason or cause of the lead time exception.
        /// </summary>
        /// <example>"The jobs tageed with RUSH priority will always receive lead time of 3 days"</example>
        public string Reason { get; set; }

        /// <summary>
        /// The name of the person who reported the lead time exception.
        /// </summary>
        /// <example>"John Wick"</example>
        public string ReportedBy { get; set; }

        /// <summary>
        /// The lead time in days associated with the exception.
        /// </summary>
        /// <example>3</example>
        public int LeadTimeInDays { get; set; }
    }
}
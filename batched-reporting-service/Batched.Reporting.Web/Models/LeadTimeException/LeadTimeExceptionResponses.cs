using Batched.Reporting.Contracts.Models;

namespace Batched.Reporting.Web.Models.LeadTimeException
{
    /// <summary>
    /// Represents a response object for retrieving lead time exceptions.
    /// Inherits ExceptionResponse, which contains Status object.
    /// </summary>
    public class GetExceptionsResponse : ExceptionResponse
    {
        /// <summary>
        /// List of lead time exceptions.
        /// </summary>
        public List<LeadTimeException> Exceptions { get; set; }
    }

    /// <summary>
    /// Represents a response object for adding a new lead time exception.
    /// Inherits ExceptionResponse, which contains Status object.
    /// </summary>
    public class AddExceptionsResponse : ExceptionResponse
    {
        /// <summary>
        /// The unique identifier of the newly added lead time exception.
        /// </summary>
        /// <example>"2DCA4FB7-8BBA-4F75-8BBA-983CBF3A626B"</example>
        public string ExceptionId { get; set; }
    }

    /// <summary>
    /// Represents a response object for which consists of Status object.
    /// </summary>
    public class ExceptionResponse
    {
        /// <summary>
        /// The object of Status representing status of the operations on the lead time exceptions (View/Add/Edit/Delete).
        /// </summary>
        public Status Status { get; set; }
    }
}
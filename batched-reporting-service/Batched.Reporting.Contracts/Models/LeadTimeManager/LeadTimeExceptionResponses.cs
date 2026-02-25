namespace Batched.Reporting.Contracts.Models.LeadTimeManager
{
    public class GetExceptionsResponse : ExceptionResponse
    {
        public List<LeadTimeException> Exceptions { get; set; }
    }

    public class AddExceptionsResponse : ExceptionResponse
    {
        public string ExceptionId { get; set; }
    }

    public class ExceptionResponse
    {
        public Status Status { get; set; }
    }
}
namespace Batched.Reporting.Contracts.Models.LeadTimeManager
{
    public class AddExceptionRequest
    {
        public string Name { get; set; }
        public string Reason { get; set; }
        public string ReportedBy { get; set; }
        public int LeadTimeInDays { get; set; }
    }

    public class EditExceptionRequest
    {
        public string Id { get; set; }
        public string Name { get; set; }
        public string Reason { get; set; }
        public int LeadTimeInDays { get; set; }
    }
}
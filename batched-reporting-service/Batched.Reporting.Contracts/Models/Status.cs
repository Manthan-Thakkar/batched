namespace Batched.Reporting.Contracts.Models
{
    public class Status
    {
        public bool Error { get; set; } = false;
        public string Code { get; set; } = "200";
        public string Message { get; set; } = string.Empty;
        public string Type { get; set; } = "success";
    }
}
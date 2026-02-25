namespace Batched.Reporting.Contracts.Models.Export
{
    public class ExportData
    {
        public Status Status { get; set; } = new Status();
        public string Url { get; set; } = string.Empty;
    }
}
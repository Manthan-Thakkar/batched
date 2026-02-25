namespace Batched.Reporting.Contracts.Models.Export
{
    public class ExportMetadata
    {
        public string FileFormat { get; set; }
        public string FileName { get; set; }
        public List<string> RequiredColumns { get; set; }
        public string EntityName { get; set; }
    }
}
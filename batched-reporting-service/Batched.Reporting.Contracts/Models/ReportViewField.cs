namespace Batched.Reporting.Contracts.Models
{
    [Serializable]
    public class ReportViewField
    {
        public string Id { get; set; }
        public string ReportViewId { get; set; }
        public string FieldName { get; set; }
        public string DisplayName { get; set; }
        public string JsonName { get; set; }
        public string Type { get; set; }
        public string Category { get; set; }
        public bool IsDefault { get; set; }
        public int Sequence { get; set; }
        public string SortField { get; set; }
        public string Action { get; set; }
    }
}

namespace Batched.Reporting.Contracts.Interfaces
{
    public interface IConfigurableViewsProvider
    {
        Task<ConfigurableViewField> GetConfigurableViewFieldsAsync(string viewId, string reportName, CancellationToken cancellationToken);
    }
}

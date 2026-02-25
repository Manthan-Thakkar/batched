using Batched.Common.Export;

namespace Batched.Reporting.Contracts.Interfaces
{
    public interface IAwsSetting
    {
        AwsSettings GetAwsSettings();
    }
}
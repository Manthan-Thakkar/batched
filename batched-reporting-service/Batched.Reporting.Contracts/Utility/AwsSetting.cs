using Batched.Common.Export;
using Batched.Reporting.Contracts.Interfaces;
using Microsoft.Extensions.Configuration;

namespace Batched.Reporting.Contracts
{
    public class AwsSetting : IAwsSetting
    {

        private readonly IConfiguration _configuration;

        public AwsSetting(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        public AwsSettings GetAwsSettings()
        {
            return new AwsSettings()
            {
                BucketName = _configuration["AppSettings:S3ReportUploadBucketName"],
                Region = _configuration["AppSettings:Region"]
            };
        }
    }
}
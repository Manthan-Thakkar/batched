using Microsoft.OpenApi.Any;
using Microsoft.OpenApi.Models;
using Swashbuckle.AspNetCore.SwaggerGen;

namespace Batched.Reporting.Web
{
    /// <summary>
    /// Add required header parameter for swagger
    /// </summary>
    public class AddRequiredHeaderParameter : IOperationFilter
    {
        /// <summary>
        /// Adds required headers for swagger
        /// </summary>
        /// <param name="operation"></param>
        /// <param name="context"></param>
        public void Apply(OpenApiOperation operation, OperationFilterContext context)
        {
            operation.Parameters ??= new List<OpenApiParameter>();

            operation.Parameters.Add(new OpenApiParameter()
            {
                Name = "tenantId",
                In = ParameterLocation.Header,
                Example = new OpenApiString("6b52acb0-da22-4db5-96b0-6f330cbe000f"),
                Required = true
            });

            operation.Parameters.Add(new() 
            {
                Name = "clientId",
                In = ParameterLocation.Header,
                Example = new OpenApiString("e437fde9-4c18-4455-823c-173bafb401da"),
                Required = true
            });

        }
    }
}

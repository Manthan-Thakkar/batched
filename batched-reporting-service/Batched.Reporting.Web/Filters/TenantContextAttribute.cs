using Batched.Reporting.Contracts;
using Batched.Reporting.Shared;
using Microsoft.AspNetCore.Mvc.Filters;

namespace Batched.Reporting.Web.Filters
{
    public class TenantContextAttribute: ActionFilterAttribute
    {

        public async override Task OnActionExecutionAsync(ActionExecutingContext context, ActionExecutionDelegate next)
        {
            if (string.IsNullOrWhiteSpace(ApplicationContext.Current.TenantId))
            {
                AppLogger.Log("No tenant id found in request header.");
                throw ClientSideError.InvalidRequest(Info.Create().AddInfo("10", "No tenant id found in request header."));
            }

            var _tenantProvider = (ITenantProvider?)context.HttpContext.RequestServices.GetService(typeof(ITenantProvider));
            if (_tenantProvider != null)
                await SetTenantNameAsync(_tenantProvider, ApplicationContext.Current.TenantId);
            else
            {
                AppLogger.Log($"Error in creating TenantProvider dependency");
                throw new BaseApplicationException("500", "Error in creating TenantProvider dependency");
            }
            await next();
        }

        public static async Task SetTenantNameAsync(ITenantProvider tenantProvider, string tenantId)
        {
            var tenantDatabase = await tenantProvider.GetTenantDatabaseNameAsync(tenantId, default); 
            if (!string.IsNullOrEmpty(tenantDatabase))
            {
                ApplicationContext.SetTenantName(tenantDatabase);
            }
            else
            {
                AppLogger.Log($"Tenant database not found");
                throw ClientSideError.InvalidRequest(Info.Create().AddInfo("10", $"tenant database not found "));
            }
        }

    }
}

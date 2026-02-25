using Batched.Common;
using Batched.Reporting.Shared;

namespace Batched.Reporting.Web
{
    public class ContextInjectorMiddleware
    {
        private readonly RequestDelegate _next;
        public ContextInjectorMiddleware(RequestDelegate next)
        {
            _next = next;
        }
        public async Task Invoke(HttpContext httpContext)
        {
            string transactionId = Guid.NewGuid().ToString();
            ApplicationContext callContext = CallContextPopulatorcs.Create(httpContext.Request);


            httpContext?.Response.Headers.Append(KeyStore.Header.CorrelationId, callContext.CorrelationId);
            httpContext?.Response.Headers.Append(KeyStore.Header.TransactionId, callContext.TransactionId);

            httpContext?.Response.Headers.Add("Access-Control-Allow-Origin", "*");
            httpContext?.Response.Headers.Add("Access-Control-Allow-Headers", "tenantId");

            using (new AmbientContextScope(callContext))
            {
                await _next(httpContext);
            }
        }
    }
}

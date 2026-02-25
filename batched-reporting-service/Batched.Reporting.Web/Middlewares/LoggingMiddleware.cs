using Batched.Reporting.Shared;
using Batched.Reporting.Web.Internals;
using System.Diagnostics;
using System.Net;

namespace Batched.Reporting.Web
{
    public class LoggingMiddleware
    {
        private readonly RequestDelegate _next;
        public LoggingMiddleware(RequestDelegate next)
        {
            _next = next;
        }
        public async Task Invoke(HttpContext httpContext)
        {
            var url = $"{httpContext.Request.Scheme}://{httpContext.Request.Host.Value}{httpContext.Request.Path.Value}";

            var stopwatch = new Stopwatch();
            stopwatch.Start();

            await _next(httpContext);

            stopwatch.Stop();

            var apiVerb = GetApiAndVerb(httpContext);

            var isSuccessful = httpContext.Response.StatusCode >= 200 && httpContext.Response.StatusCode <= 299;
            string message = GetApiMessage(httpContext.Response);

            AppLogger.Api(url, isSuccessful, apiVerb.Item1, apiVerb.Item2, stopwatch.ElapsedMilliseconds,
                httpContext.Request.Headers, httpContext.Response.Headers, message);
        }

        private string GetApiMessage(HttpResponse response)
        {
            var responseCode = response.StatusCode;
            if (Enum.IsDefined(typeof(HttpStatusCode), responseCode))
            {
                var httpStatusCode = (HttpStatusCode)responseCode;
                return httpStatusCode.ToString();
            }
            return "";
        }

        private Tuple<string, string> GetApiAndVerb(HttpContext httpContext)
        {
            var routes = httpContext.Request.RouteValues;
            try
            {

                var pair = Tuple.Create(routes.ContainsKey(KeyStore.ControllerLogKey) ? routes[KeyStore.ControllerLogKey]?.ToString() : default,
                    routes.ContainsKey(KeyStore.ActionLogKey) ? routes[KeyStore.ActionLogKey]?.ToString() : default);
                if (pair != null && ControllerMappingExists(pair))
                {
                    var mapping = ControllerActionLoggingNameMapping.Map[pair.Item1];
                    return Tuple.Create(mapping.GetValue(KeyStore.ControllerLogKey), mapping.GetValue(pair.Item2));
                }
            }
            catch (Exception ex)
            {
                //suppress and log
                AppLogger.LogException(ex);
            }
            return Tuple.Create("", "");
        }

        private static bool ControllerMappingExists(Tuple<string?, string?> pair)
        {
            return !string.IsNullOrWhiteSpace(pair.Item1)   
                                && !string.IsNullOrWhiteSpace(pair.Item2)
                                && ControllerActionLoggingNameMapping.Map.ContainsKey(pair.Item1);
        }
    }
}

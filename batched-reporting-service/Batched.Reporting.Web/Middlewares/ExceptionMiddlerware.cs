using Batched.Reporting.Contracts;
using Batched.Reporting.Shared;
using Newtonsoft.Json;

namespace Batched.Reporting.Web.Middlewares
{
    public class ExceptionMiddlerware
    {
        private readonly RequestDelegate _next;
        public ExceptionMiddlerware(RequestDelegate requestDelegate)
        {
            _next = requestDelegate;
        }

        public async Task Invoke(HttpContext httpContext)
        {
            try
            {
                await _next(httpContext);
            }
            catch (BadRequestException exception)
            {
                var code = exception.Code;
                var message = exception.Message;

                var errorInfo = new ErrorInfo(code, message);
                if (!exception.Infos.IsNullOrEmpty())
                {
                    errorInfo.Infos = exception.Infos;
                }
                AddResponseHeaders(httpContext);
                httpContext.Response.StatusCode = (int)exception.HttpStatusCode;
                await httpContext.Response.WriteAsync(JsonConvert.SerializeObject(errorInfo));

                AppLogger.LogException(exception, GetLogFields(exception));
            }
            catch (Exception exception)
            {
                var errorInfo = new ErrorInfo("123", "Something went wrong.");
                var additionalInfo = exception.GetFormattedExceptionMessage();
                errorInfo.Infos = new System.Collections.Generic.List<Info>();
                errorInfo.Infos.Add(new Info("123", additionalInfo));

                httpContext.Response.StatusCode = 500;
                AddResponseHeaders(httpContext);
                await httpContext.Response.WriteAsync(JsonConvert.SerializeObject(errorInfo));

                AppLogger.LogException(exception, GetLogFields(exception));
            }
        }
        private void AddResponseHeaders(HttpContext httpContext)
        {
            httpContext.Response.Headers.Add("Content-Type", "application/json; charset=utf-8");
        }
        private LogFields GetLogFields(Exception exception)
        {
            var additionalInfo = exception.GetFormattedExceptionMessage();

            return LogFields.Create.Add("additioanlInfo", additionalInfo);
        }
    }
}

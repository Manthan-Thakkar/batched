using Batched.Common;
using Microsoft.AspNetCore.Http;

namespace Batched.Reporting.Shared
{
    public class AppLogger
    {
        public static void Log(string message, LogFields? fields = null)
        {
            var log = new SimpleLog(null, fields?.GetMap());
            log.Message = message;
            if (CallContext.Current != null)
            {
                log.ApplicationTransactionId = CallContext.Current.TransactionId;
                log.ApplicationName = CallContext.Current.ApplicationName;
                log.CorrelationId = CallContext.Current.CorrelationId;
                log.TenantId = CallContext.Current.TenantId;
                log.TrySetValue("tenant", ApplicationContext.Current.TenantName);
            }
            TryAddKeyValuePairs(log, fields);

            Logger.WriteLog(log);
        }
        public static void LogException(Exception exception, LogFields? fields = null)
        {
            var log = new ExceptionLog(exception);

            if (CallContext.Current != null)
            {
                log.ApplicationTransactionId = CallContext.Current.TransactionId;
                log.ApplicationName = CallContext.Current.ApplicationName;
                log.CorrelationId = CallContext.Current.CorrelationId;
                log.TenantId = CallContext.Current.TenantId;
                log.TrySetValue("tenant", ApplicationContext.Current.TenantName);
            }

            if (exception != null)
                log.Message = exception.Message;

            TryAddAdditionalFields(exception, log);
            TryAddKeyValuePairs(log, fields);

            Logger.WriteLog(log);
        }

        private static void TryAddAdditionalFields(Exception? exception, ExceptionLog log)
        {
            if (exception?.Data != null)
                foreach (var map in exception.Data)
                {
                    log.TrySetValue(map.ToString(), exception.Data[map]);
                }
        }

        public static void Trace(string category, string message, LogFields fields)
        {
            TraceLog trace = new TraceLog();
            CallContext context = CallContext.Current;

            if (context != null)
            {
                trace.ApplicationName = context.ApplicationName;
                trace.TenantId = context.TenantId;
                trace.CorrelationId = context.CorrelationId;
                trace.StackId = context.StackId;
                trace.ApplicationTransactionId = context.TransactionId;
                trace.Message = message;
                trace.TrySetValue("tenant", ApplicationContext.Current.TenantName);
            }
            trace.Category = category;

            TryAddKeyValuePairs(trace, fields);

            Logger.WriteLog(trace);
        }
        public static void Api(string url, bool isSuccess, string api, string verb, long timeTakenInMs,
            IHeaderDictionary requestHeaders,
            IHeaderDictionary responseHeaders,
            string message,
            LogFields? fields = null)
        {
            var context = CallContext.Current;
            var apiLog = new ApiLog()
            {
                Url = url,
                CorrelationId = context.CorrelationId,
                StackId = context.StackId,
                ApplicationTransactionId = context.TransactionId,
                TransactionId = context.TransactionId,
                ApplicationName = context.ApplicationName,
                IsSuccessful = isSuccess,
                TenantId = context.TenantId,
                ClientIp = context.IpAddress,
                Api = api,
                Verb = verb,
                TimeTakenInMs = timeTakenInMs,
                Message = message
            };
            apiLog.TrySetValue("tenant", ApplicationContext.Current.TenantName);

            if (!requestHeaders.IsNullOrEmpty())
                foreach (var reqHeader in requestHeaders)
                {
                    // Skip the Authorization header
                    if (reqHeader.Key.Equals("Authorization", StringComparison.OrdinalIgnoreCase))
                        continue;

                    apiLog.TrySetValue($"rq_header_{reqHeader.Key}", reqHeader.Value.ToString());
                }
            if (!responseHeaders.IsNullOrEmpty())
                foreach (var resHeader in responseHeaders)
                {
                    apiLog.TrySetValue($"rs_header_{resHeader.Key}", resHeader.Value.ToString());
                }

            if(fields != null)
                TryAddKeyValuePairs(apiLog, fields);

            SetApi(api, apiLog);
            SetVerb(verb, apiLog);

            Logger.WriteLog(apiLog);
        }

        private static void SetVerb(string verb, ApiLog apiLog)
        {
            if (!string.IsNullOrEmpty(verb))
                apiLog.Verb = verb;
            else if (!string.IsNullOrEmpty(ApplicationContext.Current?.Verb))
                apiLog.Verb = ApplicationContext.Current?.Verb;
            else
                apiLog.Verb = null;
        }

        private static void SetApi(string api, ApiLog apiLog)
        {
            if (!string.IsNullOrEmpty(api))
                apiLog.Api = api;
            else if (!string.IsNullOrEmpty(ApplicationContext.Current?.Api))
                apiLog.Api = ApplicationContext.Current?.Api;
            else
                apiLog.Api = null;
        }

        private static void TryAddKeyValuePairs(LogBase log, LogFields? fields)
        {
            if (fields != null && !fields.GetMap().IsNullOrEmpty())
                foreach (var pair in fields)
                {
                    log.TrySetValue(pair.Key, pair.Value);
                }
        }
    }
}

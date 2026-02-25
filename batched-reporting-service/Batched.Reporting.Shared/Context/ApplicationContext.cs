using Batched.Common;
using System.Globalization;
using System.Net;

namespace Batched.Reporting.Shared
{
    public class ApplicationContext : CallContext
    {
        public ApplicationContext(string app, string corelationId, string? tenantId, string trasactionId
            , CultureInfo? cultureInfo, IPAddress? ipAddress)
        {
            ApplicationName = app;
            CorrelationId = corelationId;
            TenantId = tenantId;
            TransactionId = trasactionId;
            Culture = cultureInfo;
            IpAddress = ipAddress;
        }

        public string? TenantName { get; private set; }
        public string? Api { get; set; }
        public string? Verb { get; set; }

        public static void SetTenantName(string tenantName)
        {
            Current.TenantName = tenantName;
        }

        public static void SetTenantId(string tenantId)
        {
            Current.TenantId = tenantId;
        }
        public static void SetApiName(string api)
        {
            if (Current != null)
                Current.Api = api;
        }
        public static void SetVerbName(string verb)
        {
            if (Current != null)
                Current.Verb = verb;
        }
        public static new ApplicationContext Current => (ApplicationContext)CallContext.Current;

    }
}

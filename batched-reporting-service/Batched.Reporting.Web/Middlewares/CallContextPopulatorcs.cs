using Batched.Reporting.Shared;
using Microsoft.Extensions.Primitives;
using System.Globalization;
using System.Net;

namespace Batched.Reporting.Web
{
    public class CallContextPopulatorcs
    {
        public static ApplicationContext Create(HttpRequest? httpRequest)
        {
            var missingHeaders = new List<string>();
            var invalidHeaders = new List<string>();

            IPAddress? consumerIPAddress = IPAddress.None;
            CultureInfo? cultureInfo = null;

            var headerDictionary = httpRequest?.Headers;
            var queryCollections = httpRequest?.Query;

            //mandatory header check
            var tenantId = GetHeaderValue(headerDictionary, KeyStore.Header.TenantId, true, ref missingHeaders);

            var correlationId = GetHeaderValue(headerDictionary, KeyStore.Header.CorrelationId, false, ref missingHeaders);
            var culture = GetHeaderValue(headerDictionary, KeyStore.Header.AcceptLanguage, false, ref missingHeaders);
            var cultureIdentifier = ExtractValidCultureIdentifier(culture);
            try { cultureInfo = string.IsNullOrEmpty(cultureIdentifier) ? null : new CultureInfo(cultureIdentifier); } 
            catch(Exception e) 
            {
                AppLogger.LogException(e);
            }

            var ipAddress = GetHeaderValue(headerDictionary, KeyStore.Header.IpAddress, true, ref missingHeaders);

            if (!string.IsNullOrWhiteSpace(ipAddress) && !IPAddress.TryParse(ipAddress, out consumerIPAddress))
            {
                invalidHeaders.Add(KeyStore.Header.IpAddress);
            }
            //throw exception if missingHeaders and invalid headers found
            correlationId = correlationId ?? Guid.NewGuid().ToString();
            var transationId = Guid.NewGuid().ToString();
            return new ApplicationContext(KeyStore.AppName, correlationId, tenantId, transationId, cultureInfo, consumerIPAddress);

        }
        private static string? GetHeaderValue(IHeaderDictionary? headers, string headerName, bool isMandatory, ref List<string> missingHeaders)
        {
            if (headers!= null && headers.TryGetValue(headerName, out StringValues values) && !string.IsNullOrWhiteSpace(values))
            {
                return values;
            }
            else if (isMandatory)
            {
                missingHeaders.Add(headerName);
            }

            return null;
        }

        private static string ExtractValidCultureIdentifier(string languageTags)
        {
            return !string.IsNullOrWhiteSpace(languageTags) ?
                languageTags
                .Split(',')
                .Select(tag => tag.Split(';')[0].Trim())
                .Where(languageCode => IsValidCulture(languageCode))
                .FirstOrDefault()
                : string.Empty;
        }

        private static bool IsValidCulture(string languageCode)
        {
            try
            {
                CultureInfo.GetCultureInfo(languageCode);
                return true;
            }
            catch (CultureNotFoundException)
            {
                return false;
            }
        }
    }
}

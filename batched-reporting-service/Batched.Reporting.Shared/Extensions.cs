using System.Collections;

namespace Batched.Reporting.Shared
{
    public static class Extensions
    {
        public static bool IsNullOrEmpty<TItem>(this ICollection<TItem> items)
        {
            return items == null || items.Count == 0;
        }

        public static string Format(this string str, params string[] arg)
        {
            return string.Format(str, arg);
        }

        public static string GetFormattedExceptionMessage(this Exception exception)
        {
            if (exception is AggregateException)
                return GetFormattedExceptionMessage(exception?.InnerException);

            if (exception == null)
                return string.Empty;

            var message = exception.Data.Count > 0
                    ? GetExceptionDataMessage(exception.Data)
                    : exception.Message;

            var innerMessage = exception.InnerException != null
                                ? GetFormattedExceptionMessage(exception.InnerException) : exception.Message;

            message = $"{message} | {innerMessage}";

            return message;
        }
        private static string GetExceptionDataMessage(IDictionary data)
        {
            var keys = new List<string>();
            foreach (var key in data.Keys)
            {
                keys.Add($"{key}: {data[key]}");
            }
            return string.Join(" | ", keys);
        }

        public struct DateTimeWithZone
        {
            private readonly DateTime utcDateTime;
            private readonly TimeZoneInfo timeZone;

            public DateTimeWithZone(string timeZone)
            {
                utcDateTime = DateTime.UtcNow;
                this.timeZone = TimeZoneConverter.TZConvert.GetTimeZoneInfo(timeZone);
            }

            public DateTime LocalTime
            {
                get
                {
                    return TimeZoneInfo.ConvertTimeFromUtc(utcDateTime, timeZone);
                }
            }
        }
    }
}

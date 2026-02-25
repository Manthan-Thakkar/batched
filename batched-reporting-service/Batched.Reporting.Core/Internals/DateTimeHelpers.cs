internal static class DateTimeHelpers
{
    public static Dictionary<string, int> monthMapping = new()
    {
        { "JAN", 1 },
        { "FEB", 2 },
        { "MAR", 3 },
        { "APR", 4 },
        { "MAY", 5 },
        { "JUN", 6 },
        { "JUL", 7 },
        { "AUG", 8 },
        { "SEP", 9 },
        { "OCT", 10 },
        { "NOV", 11 },
        { "DEC", 12 }
    };

    public static Dictionary<string, DayOfWeek> dayOfWeekMapping = new(StringComparer.OrdinalIgnoreCase)
    {
        { "SUN", DayOfWeek.Sunday },
        { "MON", DayOfWeek.Monday },
        { "TUE", DayOfWeek.Tuesday },
        { "WED", DayOfWeek.Wednesday },
        { "THU", DayOfWeek.Thursday },
        { "FRI", DayOfWeek.Friday },
        { "SAT", DayOfWeek.Saturday }
    };

    public static Dictionary<string, int> weekDayIndexMapping = new(StringComparer.OrdinalIgnoreCase)
    {
        { "FIRST", 1 },
        { "SECOND", 2 },
        { "THIRD", 3 },
        { "FORTH", 4 },
        { "LAST", -1 }
    };

    public static int GetMonth(string month)
    {
        monthMapping.TryGetValue(month, out int monthNumber);
        return monthNumber;
    }

    public static DayOfWeek GetDayOfWeek(string weekDay)
    {
        dayOfWeekMapping.TryGetValue(weekDay, out DayOfWeek dayOfWeek);
        return dayOfWeek;
    }
}
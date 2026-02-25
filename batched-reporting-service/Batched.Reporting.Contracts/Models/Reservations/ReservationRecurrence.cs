namespace Batched.Reporting.Contracts.Models
{
    /// <summary>
    /// Represents a response object for reservation recurrence.
    /// </summary>
    public class ReservationRecurrence
    {
        /// <summary>
        /// The recurrence type of the reservation.
        /// </summary>
        /// <example>Daily</example>
        public string RecurrenceType { get; set; }

        /// <summary>
        /// The frequency of repetition of reservation.
        /// </summary>
        /// <example>1</example>
        public int Frequency { get; set; }

        /// <summary>
        /// If the reservation is repetiting monthly on Week day or not.
        /// </summary>
        /// <example>false</example>
        public bool IsRecurringMonthlyOnWeekDay { get; set; }

        /// <summary>
        /// The day on which the reservation will repeat in case of monthly and yearly recurrence.
        /// </summary>
        /// <example>12</example>
        public int? RecurrenceDay { get; set; }

        /// <summary>
        /// The month on which the reservation will repeat in case of yearly recurrence.
        /// </summary>
        /// <example>NOV</example>
        public string RecurrenceMonth { get; set; }

        /// <summary>
        /// The list of weekdays on which the reservation will repeat in case of weekly and monthly recurrence.
        /// </summary>
        /// <example>["TUE","WED"]</example>
        public List<string> RecurrenceWeekDays { get; set; } = new List<string>();

        /// <summary>
        /// The index of the week day on which the reservation will repeat.
        /// </summary>
        /// <example>SECOND</example>
        public String RecurrenceDayOfWeekIndex { get; set; }

        /// <summary>
        /// The end date of the recurrence after which reservation will not repeat.
        /// </summary>
        public DateTime? EndDate { get; set; }

    }
}

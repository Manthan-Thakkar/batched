using Batched.Reporting.Contracts.Models.Reservations;
using DataModels = Batched.Common.Data.Tenants.Sql.Models;

namespace Batched.Reporting.Core.Translators
{
    public static class ReservationEventTranslator
    {
        public static List<ReservationEventDto> Translate(this List<DataModels.ReservationEvent> reservationEvents)
        {
            return reservationEvents.Select(x => new ReservationEventDto
            {
                Id = x.Id,
                Date = x.ReservationEventDate,
                ReservationId = x.ReservationId,
                EquipmentId = x.EquipmentId,
                WorkcenterId = x.WorkcenterId,
                ActualDemand = x.ReservedDemands.First().ActualDemand,
                NetReservedDemand = x.ReservedDemands.First().NetReservedDemand,
            }).ToList();
        }
        public static List<DateTime> GetReservationEventDates(DataModels.Reservation reservation)
        {
            var eventDates = new List<DateTime>();

            if (!reservation.IsRecurring)
                eventDates.Add(reservation.StartDate);
            else
            {
                var recurrenceType = reservation.ReservationRecurrence.RecurrenceType;

                switch (recurrenceType)
                {
                    case Constants.RecurrenceType.Daily:
                        eventDates.AddRange(GetEventDatesForDailyType(reservation));
                        break;
                    case Constants.RecurrenceType.Weekly:
                        eventDates.AddRange(GetEventDatesForWeeklyType(reservation));
                        break;
                    case Constants.RecurrenceType.Monthly:
                        eventDates.AddRange(GetEventDatesForMonthlyType(reservation));
                        break;
                    case Constants.RecurrenceType.Yearly:
                        eventDates.AddRange(GetEventDatesForYearlyType(reservation));
                        break;
                }
            }
            return eventDates;
        }

        public static List<DataModels.ReservationEvent> CreateReservationEvents(DataModels.Reservation reservation, List<DateTime> reservationDates, bool IsUpdate)
        {
            var events = new List<DataModels.ReservationEvent>();
            foreach(var date in reservationDates)
            {
                foreach(var workcenter in reservation.WorkcenterReservations)
                {
                    if (workcenter.WorkcenterEquipmentReservations.Any())
                        foreach(var equipment in workcenter.WorkcenterEquipmentReservations)
                        {
                            events.Add(CreateReservationEventModel(reservation, workcenter.WorkcenterTypeId, equipment.EquipmentId, date, IsUpdate));
                        }
                    else
                        events.Add(CreateReservationEventModel(reservation, workcenter.WorkcenterTypeId, null, date, IsUpdate));
                }
            }
            return events.OrderBy(x => x.ReservationEventDate).ToList();
        }

        private static DataModels.ReservationEvent CreateReservationEventModel(DataModels.Reservation reservation, string workcenterId, string equipmentId, DateTime eventDate, bool IsUpdate)
        {
            var reservationEventId = Guid.NewGuid().ToString();
                return new DataModels.ReservationEvent
                {
                    Id = reservationEventId,
                    ReservationId = reservation.Id,
                    EquipmentId = equipmentId,
                    WorkcenterId = workcenterId,    
                    ReservationEventDate = eventDate,
                    ReservedDemand = GetReservedDemandForEvent(reservation, workcenterId, equipmentId),
                    IsExpired = false,
                    ExpirationDate = GetExpiryDate(eventDate, reservation.ExpirationDays),
                    CreatedOnUtc = IsUpdate ? reservation.CreatedOnUtc : DateTime.UtcNow,
                    ModifiedOnUtc = DateTime.UtcNow,
                };
        }

        private static int GetReservedDemandForEvent(DataModels.Reservation reservation, string workcenterId, string equipmentId)
        {
            if (equipmentId != null)
                return reservation.WorkcenterReservations.Where(x => x.WorkcenterTypeId == workcenterId).First()
                    .WorkcenterEquipmentReservations.Where(x => x.EquipmentId == equipmentId).First().ReservedHours;
            else
                return reservation.WorkcenterReservations.Where(x => x.WorkcenterTypeId == workcenterId).First().ReservedHours;
        }
        
        private static DateTime GetExpiryDate(DateTime eventDate, int expirationDays) 
        {
            var date = eventDate.AddDays(-expirationDays);
            return date;
        }

        private static List<DateTime> GetEventDatesForDailyType(DataModels.Reservation reservation)
        {
            var eventDates = new List<DateTime>();
            var date = reservation.StartDate;
            while (date <= reservation.ReservationRecurrence.EndDate)
            {
                eventDates.Add(date);
                date = date.AddDays(reservation.ReservationRecurrence.Frequency);
            }
            return eventDates;
        }

        private static List<DateTime> GetEventDatesForWeeklyType(DataModels.Reservation reservation)
        {
            var eventDates = new List<DateTime>();
            var weekDays = reservation.ReservationRecurrence.RecurrenceWeekDays.Split(',').ToList();
            foreach (var day in weekDays)
            {
                var date = GetFirstReservationEventDateInWeeklyCase(reservation.StartDate, day);
                while (date <= reservation.ReservationRecurrence.EndDate)
                {
                    eventDates.Add(date);
                    date = date.AddDays(reservation.ReservationRecurrence.Frequency * 7);
                }
            }
            return eventDates;
        }

        private static List<DateTime> GetEventDatesForMonthlyType(DataModels.Reservation reservation)
        {
            var eventDates = new List<DateTime>();
            if (!reservation.ReservationRecurrence.IsRecurringMonthlyOnWeekDay)
            {
                var date = GetFirstReservationEventDateInMonthlyCase(reservation.StartDate, (int)reservation.ReservationRecurrence.RecurrenceDay);
                while (date <= reservation.ReservationRecurrence.EndDate)
                {
                    eventDates.Add(date);
                    date = date.AddMonths(reservation.ReservationRecurrence.Frequency);
                }
            }
            else
            {
                var dayOfWeek = reservation.ReservationRecurrence.RecurrenceWeekDays;
                var dayOfWeekIndex = reservation.ReservationRecurrence.RecurrenceDayOfWeekIndex;
                var frequency = reservation.ReservationRecurrence.Frequency;

                DateTimeHelpers.weekDayIndexMapping.TryGetValue(dayOfWeekIndex, out int weekOfMonthIndex);

                eventDates.AddRange(GetRecurringDatesMonthlyOnWeekDay(frequency, weekOfMonthIndex, DateTimeHelpers.GetDayOfWeek(dayOfWeek), 
                    reservation.StartDate, (DateTime)reservation.ReservationRecurrence.EndDate));
            }
            return eventDates;
        }
        
        private static List<DateTime> GetRecurringDatesMonthlyOnWeekDay(int frequency, int weekOfMonthIndex, DayOfWeek dayOfWeek, DateTime startDate, DateTime endDate)
        {
            List<DateTime> dates = new List<DateTime>();
            DateTime currentDate = startDate;

            while (currentDate <= endDate)
            {
                DateTime firstDayOfMonth = new DateTime(currentDate.Year, currentDate.Month, 1);
                DateTime targetDate;

                if (weekOfMonthIndex > 0)
                    targetDate = GetNthWeekdayOfMonth(firstDayOfMonth, dayOfWeek, weekOfMonthIndex);
                else
                    targetDate = GetLastWeekdayOfMonth(firstDayOfMonth, dayOfWeek);

                if (targetDate >= startDate && targetDate <= endDate)
                    dates.Add(targetDate);

                currentDate = currentDate.AddMonths(frequency);
            }
            return dates;
        }

        private static DateTime GetNthWeekdayOfMonth(DateTime firstDayOfMonth, DayOfWeek dayOfWeek, int n)
        {
            int daysUntilFirstOccurrence = ((int)dayOfWeek - (int)firstDayOfMonth.DayOfWeek + 7) % 7;
            DateTime firstOccurrence = firstDayOfMonth.AddDays(daysUntilFirstOccurrence);
            return firstOccurrence.AddDays((n - 1) * 7);
        }

        private static DateTime GetLastWeekdayOfMonth(DateTime firstDayOfMonth, DayOfWeek dayOfWeek)
        {
            int daysInMonth = DateTime.DaysInMonth(firstDayOfMonth.Year, firstDayOfMonth.Month);
            DateTime lastDayOfMonth = new DateTime(firstDayOfMonth.Year, firstDayOfMonth.Month, daysInMonth);
            int daysUntilLastOccurrence = ((int)lastDayOfMonth.DayOfWeek - (int)dayOfWeek + 7) % 7;
            return lastDayOfMonth.AddDays(-daysUntilLastOccurrence);
        }

        private static List<DateTime> GetEventDatesForYearlyType(DataModels.Reservation reservation)
        {
            var eventDates = new List<DateTime>();
            var date = GetFirstReservationEventDateInYearlyCase(reservation.StartDate, (int)reservation.ReservationRecurrence.RecurrenceDay, reservation.ReservationRecurrence.RecurrenceMonth);
            while (date <= reservation.ReservationRecurrence.EndDate)
            {
                eventDates.Add(date);
                date = date.AddYears(reservation.ReservationRecurrence.Frequency);
            }
            return eventDates;
        }


        private static DateTime GetFirstReservationEventDateInWeeklyCase(DateTime startDate, string weekDay)
        {
            var date = startDate;
            while (date.ToString("ddd").ToUpper() != weekDay)
            {
                date = date.AddDays(1);
            }
            return date;
        }

        private static DateTime GetFirstReservationEventDateInMonthlyCase(DateTime startDate, int day)
        {
            if(startDate.Day <= day)
                return new DateTime(startDate.Year, startDate.Month, day);
            else
            {
                if (startDate.Month == 12)
                    return new DateTime(startDate.Year + 1, 1, day);
                else
                    return new DateTime(startDate.Year, startDate.Month + 1, day);
            }
        }

        private static DateTime GetFirstReservationEventDateInYearlyCase(DateTime startDate, int day, string month)
        {
            var currentDate = new DateTime(startDate.Year, DateTimeHelpers.GetMonth(month), day);
            if(currentDate < startDate)
                currentDate = currentDate.AddYears(1);

            return currentDate; 
        }

    }
}

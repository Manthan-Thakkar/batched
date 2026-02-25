using DataModels = Batched.Common.Data.Tenants.Sql.Models;
using Batched.Reporting.Contracts.Interfaces;
using Batched.Reporting.Contracts.Models;
using Batched.Reporting.Core.Translators;

namespace Batched.Reporting.Core.Core
{
    public class ReservationProvider : IReservationProvider
    {
        private readonly IReservationsRepository _reservationsRepository;

        public ReservationProvider(IReservationsRepository reservationsRepository)
        {
            _reservationsRepository = reservationsRepository;
        }

        public async Task<List<DataModels.Reservation>> GetAllReservationsAsync(CancellationToken cancellationToken)
        {
            return await _reservationsRepository.GetAllReservationsAsync(cancellationToken);
        }

        public async Task<DataModels.Reservation> GetReservationAsync(string reservationId, CancellationToken cancellationToken)
        {
            return await _reservationsRepository.GetReservationAsync(reservationId, cancellationToken);
        }
        public async Task<string> AddReservationAsync(ReservationPayload payload, CancellationToken cancellationToken)
        {
            var reservation = payload.TranslateToModelObject();
            if (payload.IsRecurring)
            {
                var reservationRecurrence = payload.ReservationRecurrence.TranslateToModelObject();
                reservation.ReservationRecurrenceId = reservationRecurrence.Id;
                reservation.ReservationRecurrence = reservationRecurrence;
            }

            var eventDates = ReservationEventTranslator.GetReservationEventDates(reservation);
            var reservationEvents = ReservationEventTranslator.CreateReservationEvents(reservation, eventDates, false);

            var reservationId = await _reservationsRepository.AddReservationAsync(reservation, cancellationToken);
            await _reservationsRepository.AddReservationEventsAsync(reservationEvents);

            return reservationId;
        }

        public async Task EditReservationAsync(EditReservationPayload payload, DataModels.Reservation existingReservation, CancellationToken cancellationToken)
        {
            var reservation = UpdateExistingReservation(payload, existingReservation);
            if (payload.IsRecurring)
            {
                var reservationRecurrence = UpdateExistingRecurrence(payload.ReservationRecurrence, reservation);
                reservation.ReservationRecurrenceId = reservationRecurrence.Id;
                reservation.ReservationRecurrence = reservationRecurrence;
            }
            var eventDates = ReservationEventTranslator.GetReservationEventDates(reservation);
            var reservationEvents = ReservationEventTranslator.CreateReservationEvents(reservation, eventDates, true);

            await _reservationsRepository.UpdateReservationAsync(reservation, cancellationToken);
            await _reservationsRepository.RemoveReservationEventsAsync(reservation.Id);
            await _reservationsRepository.AddReservationEventsAsync(reservationEvents);
        }

        public async Task DeleteReservationAsync(string reservationId, CancellationToken cancellationToken)
        {
            await _reservationsRepository.RemoveReservationEventsAsync(reservationId);
            await _reservationsRepository.DeleteReservationAsync(reservationId, cancellationToken);
        }

        private static DataModels.Reservation UpdateExistingReservation(EditReservationPayload payload, DataModels.Reservation reservation)
        {
            reservation.Name = payload.Name;
            reservation.FacilityId = payload.FacilityId;
            reservation.StartDate = payload.StartDate;
            reservation.ExpirationDays = payload.ExpirationDays;
            reservation.IsRecurring = payload.IsRecurring;
            reservation.ModifiedBy = payload.CreatedBy;
            reservation.ModifiedOnUtc = DateTime.UtcNow;
            reservation.CustomerReservations = payload.Customers.Select(customerId => new DataModels.CustomerReservation
            {
                Id = Guid.NewGuid().ToString(),
                ReservationId = payload.Id,
                CustomerId = customerId,
                CreatedOnUtc = DateTime.UtcNow,
                ModifiedOnUtc = DateTime.UtcNow,

            }).ToList();
            reservation.WorkcenterReservations = new List<DataModels.WorkcenterReservation>();
            foreach (var item in payload.WorkcenterReservations)
            {
                var workcenterReservationId = Guid.NewGuid().ToString();
                reservation.WorkcenterReservations.Add(new DataModels.WorkcenterReservation
                {
                    Id = workcenterReservationId,
                    WorkcenterTypeId = item.WorkcenterId,
                    WorkcenterName = item.WorkcenterName,
                    CreatedOnUtc = DateTime.UtcNow,
                    ModifiedOnUtc = DateTime.UtcNow,
                    ReservedHours = item.ReservedHours, 
                    WorkcenterEquipmentReservations = item.EquipmentReservations.Select(er => new DataModels.WorkcenterEquipmentReservation
                    {
                        Id = Guid.NewGuid().ToString(),
                        WorkcenterReservationId = workcenterReservationId,
                        EquipmentId = er.EquipmentId,
                        ReservedHours = er.ReservedHours,
                        CreatedOnUtc = DateTime.UtcNow,
                        ModifiedOnUtc = DateTime.UtcNow,
                    }).ToList(),
                });
            }

            return reservation;
        }

        public static DataModels.ReservationRecurrence UpdateExistingRecurrence(ReservationRecurrencePayload payload, DataModels.Reservation reservation)
        {
            var reservationRecurrence = reservation.ReservationRecurrence;

            return new DataModels.ReservationRecurrence()
            {
                Id = Guid.NewGuid().ToString(),
                Frequency = payload.Frequency,
                RecurrenceType = payload.RecurrenceType,
                IsRecurringMonthlyOnWeekDay = payload.IsRecurringMonthlyOnWeekDay,
                RecurrenceMonth = payload.RecurrenceMonth,
                RecurrenceDay = payload.RecurrenceDay,
                RecurrenceDayOfWeekIndex = payload.RecurrenceDayOfWeekIndex,
                RecurrenceWeekDays = string.Join(',', payload.RecurrenceWeekDays),
                EndDate = payload.EndDate,
                CreatedOnUtc = reservationRecurrence != null ? reservationRecurrence.CreatedOnUtc : DateTime.UtcNow,
                ModifiedOnUtc = DateTime.UtcNow,
            };
        }


    }
}

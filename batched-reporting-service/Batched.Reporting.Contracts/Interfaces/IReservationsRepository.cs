using Batched.Common.Data.Tenants.Sql.Models;
using Batched.Reporting.Contracts.Models.Reservations;

namespace Batched.Reporting.Contracts.Interfaces
{
    public interface IReservationsRepository
    {
        Task<List<Reservation>> GetAllReservationsAsync(CancellationToken cancellationToken);
        Task<List<ReservationEventDto>> GetReservationEventAsync(CancellationToken cancellationToken);
        Task<Reservation> GetReservationAsync(string reservationId, CancellationToken cancellationToken);
        Task<string> AddReservationAsync(Reservation reservation, CancellationToken cancellationToken);
        Task UpdateReservationAsync(Reservation reservation, CancellationToken cancellationToken);
        Task DeleteReservationAsync(string reservationId, CancellationToken cancellationToken);
        Task AddReservationEventsAsync(List<ReservationEvent> reservationEvents);
        Task RemoveReservationEventsAsync(string reservationId);
    }
}

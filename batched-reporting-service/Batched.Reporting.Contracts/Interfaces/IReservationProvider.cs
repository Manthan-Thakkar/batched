using Batched.Reporting.Contracts.Models;
using DataModels = Batched.Common.Data.Tenants.Sql.Models;

namespace Batched.Reporting.Contracts.Interfaces
{
    public interface IReservationProvider
    {
        Task<List<DataModels.Reservation>> GetAllReservationsAsync(CancellationToken cancellationToken);
        Task<DataModels.Reservation> GetReservationAsync(string reservationId, CancellationToken cancellationToken);
        Task<string> AddReservationAsync(ReservationPayload payload, CancellationToken cancellationToken);
        Task EditReservationAsync(EditReservationPayload payload, DataModels.Reservation existingReservation, CancellationToken cancellationToken);
        Task DeleteReservationAsync(string reservationId, CancellationToken cancellationToken);
    }
}

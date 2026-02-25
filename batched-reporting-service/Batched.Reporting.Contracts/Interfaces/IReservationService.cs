using Batched.Reporting.Contracts.Models;

namespace Batched.Reporting.Contracts.Interfaces
{
    public interface IReservationService
    {
        Task<ReservationResponse> SearchReservationsAsync(string search, string sort, int pageNum, int pageSize, List<string> facilities, CancellationToken cancellationToken);
        Task<AddReservationResponse> AddReservationAsync(ReservationPayload payload, CancellationToken cancellationToken);
        Task<EditReservationResponse> EditReservationAsync(EditReservationPayload payload, CancellationToken cancellationToken);
        Task<ApiResponse> DeleteReservationAsync(string reservationId, CancellationToken cancellationToken);
    }
}

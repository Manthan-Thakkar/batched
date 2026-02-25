using Batched.Reporting.Contracts.Models;
using Batched.Reporting.Contracts.Interfaces;
using Batched.Reporting.Core.Translators;
using Batched.Reporting.Contracts.Errormap;
using Batched.Reporting.Shared;
using DataModels = Batched.Common.Data.Tenants.Sql.Models;

namespace Batched.Reporting.Core.Services
{
    public class ReservationService : IReservationService
    {
        private readonly IReservationProvider _reservationsProvider;

        public ReservationService(IReservationProvider reservationsProvider)
        {
            _reservationsProvider = reservationsProvider;
        }

        public async Task<ReservationResponse> SearchReservationsAsync(string search, string sort, int pageNum, int pageSize, List<string> facilities, CancellationToken cancellationToken)
        {
            var response = new ReservationResponse();
            var allreservations = await _reservationsProvider.GetAllReservationsAsync(cancellationToken);
            if(facilities != null && facilities.Any())
                allreservations = allreservations.Where(x => facilities.Contains(x.FacilityId)).ToList();

            var totalCount = allreservations.Count;
            var countWithFilters = totalCount;

            if (!string.IsNullOrEmpty(search))
            {
                search = search.Replace("%", string.Empty).Trim();
                allreservations = allreservations.Where(m =>
                    m.Name.ToUpper().Contains(search.ToUpper())
                || (m.Facility.Name.ToUpper().Contains(search.ToUpper()))
                || (m.CustomerReservations.Any(x => x.Customer.CustomerName.ToUpper().Contains(search.ToUpper())))
                || (m.WorkcenterReservations.Select(x => x.WorkcenterName.ToUpper())
                                .Any(x => x.Contains(search.ToUpper())))
                || (m.WorkcenterReservations.Any(wc => wc.WorkcenterEquipmentReservations.Select(x => x.Equipment.Name)
                                                                            .Any(equip => equip.ToUpper().Contains(search.ToUpper()))))
                ).ToList();

                countWithFilters = allreservations.Count;
            }

            if(pageNum != 0 && pageSize != 0)
                allreservations = allreservations.Skip((pageNum - 1) * pageSize).Take(pageSize).ToList();

            if (sort != null)
                allreservations = SortReservations(sort, allreservations);

            response.Reservations = allreservations.Translate();
            response.Status = new Status();
            response.TotalCount = totalCount;
            response.CountWithFilters = countWithFilters;
            response.CurrentPageCount = allreservations.Count;

            AppLogger.Log($"Total {response.CurrentPageCount} reservations fetched successfully.");
            return response;
        }

        public async Task<AddReservationResponse> AddReservationAsync(ReservationPayload payload, CancellationToken cancellationToken)
        {
            if(!payload.WorkcenterReservations.Any())
                return new AddReservationResponse
                {
                    Status = GetErrorStatus(ErrorCodes.WorkcenterReservationNotFound, ErrorMessages.WorkcenterReservationNotFound)
                };

            var existingReservations = await _reservationsProvider.GetAllReservationsAsync(cancellationToken);
            var existingCombination = ReservationsTranslator.GetWorkcenterEquipmentCombinations(existingReservations);
            var combinationsFromRequest = ReservationsTranslator.GetWorkcenterEquipmentCombinations(payload);
            var existingNames = existingReservations.Select(x => x.Name).ToList();

            if(existingNames.Contains(payload.Name))
                return new AddReservationResponse
                {
                    Status = GetErrorStatus(ErrorCodes.DuplicateReservationName, ErrorMessages.DuplicateReservationName.Format(payload.Name))
                };

            var duplicateCombinations = GetDuplicateCombinations(existingCombination, combinationsFromRequest);
            if (duplicateCombinations.Any())
                return new AddReservationResponse
                {
                    Status = GetErrorStatus(ErrorCodes.ReservationCombinationExists, ErrorMessages.ReservationCombinationExists.Format(duplicateCombinations.First().ReservationName))
                };

            var reservationId = await _reservationsProvider.AddReservationAsync(payload, cancellationToken);
            AppLogger.Log($"{payload.Name} reservation added successfully.");
            return new AddReservationResponse {  ReservationId = reservationId , Status = new Status()};
        }

        public async Task<ApiResponse> DeleteReservationAsync(string reservationId, CancellationToken cancellationToken)
        {
            var reservation = await _reservationsProvider.GetReservationAsync(reservationId, cancellationToken);
            if(reservation == null)
                return new ApiResponse
                {
                    Status = GetErrorStatus(ErrorCodes.InvalidReservationId, ErrorMessages.InvalidReservationId)
                };

            await _reservationsProvider.DeleteReservationAsync(reservationId, cancellationToken);
            return new ApiResponse { Status = new Status() };    
        }

        public async Task<EditReservationResponse> EditReservationAsync(EditReservationPayload payload, CancellationToken cancellationToken)
        {
            var existingReservations = await _reservationsProvider.GetAllReservationsAsync(cancellationToken);
            var currentReservation = existingReservations.FirstOrDefault(x => x.Id == payload.Id);

            if (currentReservation == null)
                return new EditReservationResponse { Status = GetErrorStatus(ErrorCodes.InvalidReservationId, ErrorMessages.InvalidReservationId) };

            var existingCombination = ReservationsTranslator.GetWorkcenterEquipmentCombinations(existingReservations.Where(x => x.Id != payload.Id).ToList());
            var combinationsFromRequest = ReservationsTranslator.GetWorkcenterEquipmentCombinations(payload);
            var existingNames = existingReservations.Where(x => x.Id != payload.Id).Select(x => x.Name).ToList();

            if (existingNames.Contains(payload.Name))
                return new EditReservationResponse
                {
                    Status = GetErrorStatus(ErrorCodes.DuplicateReservationName, ErrorMessages.DuplicateReservationName.Format(payload.Name))
                };

            var duplicateCombinations = GetDuplicateCombinations(existingCombination, combinationsFromRequest);
            if (duplicateCombinations.Any())
                return new EditReservationResponse
                {
                    Status = GetErrorStatus(ErrorCodes.ReservationCombinationExists, ErrorMessages.ReservationCombinationExists.Format(duplicateCombinations.First().ReservationName))
                };

            await _reservationsProvider.EditReservationAsync(payload, currentReservation, cancellationToken);

            AppLogger.Log($"{payload.Name} reservation Edited successfully.");
            return new EditReservationResponse { Status = new Status() };

        }

        private static List<DuplicateReservationValidationDto> GetDuplicateCombinations(
            List<DuplicateReservationValidationDto> existingCombinations,
            List<DuplicateReservationValidationDto> combinationsFromRequest)
        {
            var result = new List<DuplicateReservationValidationDto>();
            var IsRequestRecurring = combinationsFromRequest.First().EndDate != null;

                foreach ( var requestCombination in combinationsFromRequest)
                {
                    result.AddRange(
                        existingCombinations.FindAll(x => x.FacilityId == requestCombination.FacilityId
                                        && x.WorkcenterId == requestCombination.WorkcenterId 
                                        && x.EquipmentId == requestCombination.EquipmentId
                                        && x.CustomerId == requestCombination.CustomerId
                                        && CheckIfReservationDatesOverlapping(requestCombination.StartDate, requestCombination.EndDate
                                                                                , x.StartDate, x.EndDate
                                                                                , IsRequestRecurring, x.EndDate != null )
                        )
                    );
                }

            return result;
        }

        private static bool CheckIfReservationDatesOverlapping(DateTime requestStartDate, DateTime? requestEndDate, DateTime startDate, DateTime? endDate
            , bool isRequestRecurring, bool isExistingRecurring)
        {
            if (isExistingRecurring && isRequestRecurring)
                return requestStartDate <= endDate && requestEndDate >= startDate;
            else if (!isRequestRecurring && isExistingRecurring)
                return requestStartDate <= endDate && requestStartDate >= startDate
                    || requestStartDate == startDate;
            else if (isRequestRecurring && !isExistingRecurring)
                return requestStartDate <= startDate && requestEndDate >= startDate
                    || requestStartDate == startDate;
            else
                return requestStartDate == startDate;
        }

        private static Status GetErrorStatus(string code, string message)
        {
            return new Status() { Code = code, Error = true, Message = message };
        }


        private static List<DataModels.Reservation> SortReservations(string sort, List<DataModels.Reservation> searchResults)
        {
            searchResults = sort switch
            {
                "+name" => searchResults.OrderBy(s => s.Name).ToList(),
                "-name" => searchResults.OrderByDescending(s => s.Name).ToList(),
                "+facilityName" => searchResults.OrderBy(s => s.Facility.Name).ToList(),
                "-facilityName" => searchResults.OrderByDescending(s => s.Facility.Name).ToList(),
                "+workcenters" => searchResults.OrderBy(s => s.WorkcenterReservations.FirstOrDefault().WorkcenterName).ToList(),
                "-workcenters" => searchResults.OrderByDescending(s => s.WorkcenterReservations.FirstOrDefault().WorkcenterName).ToList(),
                "+customers" => searchResults.OrderBy(s => s.CustomerReservations.FirstOrDefault()?.Customer.CustomerName).ToList(),
                "-customers" => searchResults.OrderByDescending(s => s.CustomerReservations.FirstOrDefault()?.Customer.CustomerName).ToList(),
                "+expirationDays" => searchResults.OrderBy(s => s.ExpirationDays).ToList(),
                "-expirationDays" => searchResults.OrderByDescending(s => s.ExpirationDays).ToList(),
                "+duration" => searchResults.OrderBy(s => s.StartDate).ToList(),
                "-duration" => searchResults.OrderByDescending(s => s.StartDate).ToList(),
                "+reservationHours" => searchResults.OrderBy(s => s.WorkcenterReservations.Select(x => x.ReservedHours).Sum()).ToList(),
                "-reservationHours" => searchResults.OrderByDescending(s => s.WorkcenterReservations.Select(x => x.ReservedHours).Sum()).ToList(),
                "+recurrences" => searchResults.OrderBy(s => s.ReservationRecurrence.RecurrenceType).ToList(),
                "-recurrences" => searchResults.OrderByDescending(s => s.ReservationRecurrence.RecurrenceType).ToList(),
                _ => searchResults.OrderBy(s => s.StartDate).ToList(),
            };
            return searchResults;
        }

    }
}

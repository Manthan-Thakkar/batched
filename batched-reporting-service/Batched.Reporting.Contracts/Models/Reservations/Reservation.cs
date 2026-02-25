namespace Batched.Reporting.Contracts.Models
{
    /// <summary>
    /// Represents a response object for reservation.
    /// </summary>
    public class Reservation
    {
        /// <summary>
        /// The unique identifier of the reservation object.
        /// </summary>
        /// <example>2DCA4FB7-8BBA-4F75-8BBA-983CBF3A626B</example>
        public string Id { get; set; }

        /// <summary>
        /// The name of the reservation.
        /// </summary>
        /// <example>Reservation 1</example>
        public string Name { get; set; }

        /// <summary>
        /// The unique Id of the facility associated with the reservation.
        /// </summary>
        /// <example>ee1a339c-af24-4149-b391-7c2f9bc3264c</example>
        public string FacilityId { get; set; }

        /// <summary>
        /// The name of facility associated with the reservation.
        /// </summary>
        /// <example>Creative CA</example>
        public string FacilityName { get; set; }

        /// <summary>
        /// The List of the workcenters and associated reserved hours for which the reservation is made.
        /// </summary>
        public List<WorkcenterReservation> WorkcenterReservations { get; set; }  = new List<WorkcenterReservation>();

        /// <summary>
        /// The List of the customers associated with reservation.
        /// </summary>
        public List<CustomerDto> Customers { get; set; } = new List<CustomerDto>();

        /// <summary>
        /// The date from which the reservation is becoming applicable.
        /// </summary>
        public DateTime StartDate { get; set; }

        /// <summary>
        /// The flag which states the reservation will repeat or not.
        /// </summary>
        /// <example>true</example>
        public bool IsRecurring { get; set; }

        /// <summary>
        /// The recurrence details for the recurring reservation.
        /// </summary>
        public ReservationRecurrence ReservationRecurrence {get; set;} = new ReservationRecurrence();

        /// <summary>
        /// Expiration days for the reservation.
        /// </summary>
        public int ExpirationDays { get; set; }

        /// <summary>
        /// UserId of the user who creates the reservation.
        /// </summary>
        /// <example>Abhijit.Patil</example>
        public string CreatedBy { get; set; }

        /// <summary>
        /// UserId of the user who modifies the reservation.
        /// </summary>
        /// <example>Abhijit.Patil</example>
        public string ModifiedBy { get; set; }
    }

    // <summary>
    /// Represents a response object for retrieving reservations.
    /// </summary>
    public class ReservationResponse : SearchApiResponse
    {
        /// <summary>
        /// Represents a response object list of reservations.
        /// </summary>
        public List<Reservation> Reservations { get; set; } = new List<Reservation>();
    }

    // <summary>
    /// Represents a response object for customerDetails.
    /// </summary>
    public class CustomerDto
    {
        /// <summary>
        /// The Id of the customer.
        /// </summary>
        /// <example>002B05E8-4E5B-4F49-A810-0DB141D6064E</example>
        public string Id { get; set; }

        /// <summary>
        /// The name of the customer.
        /// </summary>
        /// <example>Classic Coatings</example>
        public string Name { get; set; }
    }

    /// <summary>
    /// The response of Add Reservation Api.
    /// </summary>
    public class AddReservationResponse : ApiResponse
    { 
        /// <summary>
        /// The Id of the newly added reservation.
        /// </summary>
        /// <example>002B05E8-4E5B-4F49-A810-0DB141D6064E</example>
        public string ReservationId { get; set; }
    }

    /// <summary>
    /// The response of Edit Reservation Api.
    /// </summary>
    public class EditReservationResponse : ApiResponse
    {
    }

    /// <summary>
    /// The response of Delete Reservation Api.
    /// </summary>
    public class DeleteReservationResponse : ApiResponse
    {

    }

    /// <summary>
    /// The common object having status field for Api response.
    /// </summary>
    public class ApiResponse
    {

        /// <summary>
        /// The object of Status representing status of the reservations response.
        /// </summary>
        public Status Status { get; set; }
    }

    /// <summary>
    /// The common object for search api response having search result and pagination information.
    /// </summary>

    public class SearchApiResponse
    {
        /// <summary>
        /// The total count of search results without applying search and sort.
        /// </summary>
        public int TotalCount { get; set; }

        /// <summary>
        /// The total count of search results with applying search and sort.
        /// </summary>
        public int CountWithFilters { get; set; }

        /// <summary>
        /// The total count of search results after pageSize is applied.
        /// </summary>
        public int CurrentPageCount { get; set; }

        /// <summary>
        /// The object of Status representing status of the reservations response.
        /// </summary>
        public Status Status { get; set; }
    }
}

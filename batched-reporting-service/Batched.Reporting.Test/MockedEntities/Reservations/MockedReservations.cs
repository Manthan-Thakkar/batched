using DataModels = Batched.Common.Data.Tenants.Sql.Models;
using Batched.Reporting.Contracts.Models;
using Newtonsoft.Json;

namespace Batched.Reporting.Test.MockedEntities.Reservations
{
    public static class MockedReservations
    {
        public static List<DataModels.Reservation> GetReservations()
        {
            var jsonReservations = File.ReadAllText("./Data/Reservations.json");

            var reservations = JsonConvert.DeserializeObject<List<DataModels.Reservation>>(jsonReservations);
            return reservations;
        }

        public static List<DataModels.WorkcenterReservation> GetWorkcenterReservations()
        {
            var jsonWorkcenterReservations = File.ReadAllText("./Data/WorkcenterReservations.json");

            var workcenterReservations = JsonConvert.DeserializeObject<List<DataModels.WorkcenterReservation>>(jsonWorkcenterReservations);
            return workcenterReservations;
        }

        public static EditReservationPayload GetReservationPayloadNonRecurring()
        {
            return new EditReservationPayload()
            {
                Id = Guid.NewGuid().ToString(),
                Name = "Reservation 1",
                FacilityId = "04f6ffbc-7751-4c61-9591-ebf7fc409c6c",
                CreatedBy = "abhijit.patil",
                IsRecurring = false,
                ExpirationDays = 1,
                StartDate = DateTime.Now,
                Customers = new List<string> { "c1", "c2" },
                ReservationRecurrence = new ReservationRecurrencePayload(),
                WorkcenterReservations = new List<WorkcenterReservationPayload>
                {
                    new WorkcenterReservationPayload()
                    {
                        WorkcenterId = "wc1",
                        WorkcenterName = "Digital HP",
                        EquipmentReservations = new List<WorkcenterEquipmentReservationPayload>(),
                        ReservedHours = 10,
                    }
                }
            };
        }

        public static EditReservationPayload GetReservationPayloadRecurring()
        {
            return new EditReservationPayload()
            {
                Id = "Reservation 1",
                Name = "Test123",
                FacilityId = "04f6ffbc-7751-4c61-9591-ebf7fc409c6c",
                CreatedBy = "abhijit.patil",
                IsRecurring = true,
                ExpirationDays = 1,
                StartDate = DateTime.Now,
                Customers = new List<string> { "c1", "c2" },
                ReservationRecurrence = new ReservationRecurrencePayload()
                {
                    RecurrenceType = "Monthly",
                    EndDate = DateTime.Now,
                    IsRecurringMonthlyOnWeekDay = false,
                    RecurrenceDay = 13,
                    RecurrenceDayOfWeekIndex = null,
                    RecurrenceWeekDays = new List<string>(),
                    Frequency = 1,
                    RecurrenceMonth = null
                },
                WorkcenterReservations = new List<WorkcenterReservationPayload>
                {
                    new WorkcenterReservationPayload()
                    {
                        WorkcenterId = "w1",
                        WorkcenterName = "Digital HP",
                        EquipmentReservations = new List<WorkcenterEquipmentReservationPayload>(),
                        ReservedHours = 10,
                    }
                }
            };
        }
    }
}

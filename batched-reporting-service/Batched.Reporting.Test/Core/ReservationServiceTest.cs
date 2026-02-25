using DataModels = Batched.Common.Data.Tenants.Sql.Models;
using Batched.Reporting.Contracts.Interfaces;
using Batched.Reporting.Contracts.Models;
using Batched.Reporting.Core.Services;
using Batched.Reporting.Contracts.Errormap;
using Moq;
using Xunit;
using Batched.Reporting.Test.MockedEntities.Reservations;
using Batched.Reporting.Shared;

namespace Batched.Reporting.Test.Core
{
    public class ReservationServiceTest : BaseTest<ReservationService>
    {
        private readonly Mock<IReservationProvider> _reservationProvider;

        public ReservationServiceTest() : base(typeof(IReservationProvider))
        {
            _reservationProvider = new Mock<IReservationProvider>();
        }

        [Fact]
        public async Task GetReservations_ShouldSuccess()
        {
            _reservationProvider
                .Setup(_ => _.GetAllReservationsAsync(It.IsAny<CancellationToken>()))
                .ReturnsAsync(new List<DataModels.Reservation>());

            var reservationService = new ReservationService(_reservationProvider.Object);

            var result = await reservationService.SearchReservationsAsync(It.IsAny<string>(), It.IsAny<string>(), It.IsAny<int>(), It.IsAny<int>(), It.IsAny<List<string>>(), CancellationToken.None);

            Assert.NotNull(result);
        }

        [Fact]
        public async Task DeleteReservations_ShouldSucceed()
        {
            var reservationId = "reservation1";

            _reservationProvider
               .Setup(_ => _.GetReservationAsync(It.IsAny<string>(),It.IsAny<CancellationToken>()))
               .ReturnsAsync(MockedReservations.GetReservations().FirstOrDefault(x => x.Id == reservationId));

            _reservationProvider
                .Setup(_ => _.DeleteReservationAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
                .Returns(Task.CompletedTask);

            var reservationService = new ReservationService(_reservationProvider.Object);

            var result = await reservationService.DeleteReservationAsync(reservationId, CancellationToken.None);

            Assert.NotNull(result);
            Assert.False(result.Status.Error);
        }

        [Fact]
        public async Task DeleteReservations_ShouldGiveInvalidReservationId_Error()
        {

            _reservationProvider
                .Setup(_ => _.DeleteReservationAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
                .Returns(Task.CompletedTask);

            var reservationService = new ReservationService(_reservationProvider.Object);

            var result = await reservationService.DeleteReservationAsync(It.IsAny<string>(), CancellationToken.None);

            Assert.NotNull(result);
            Assert.True(result.Status.Error);
            Assert.Equal(result.Status.Message, ErrorMessages.InvalidReservationId);
        }

        [Fact]
        public async Task AddReservation_ShouldSuccess()
        {
            var reservationId = "reservation1";
            var reservationPayload = MockedReservations.GetReservationPayloadNonRecurring();

            _reservationProvider
               .Setup(_ => _.GetAllReservationsAsync(It.IsAny<CancellationToken>()))
               .ReturnsAsync(MockedReservations.GetReservations());

            _reservationProvider
                .Setup(_ => _.AddReservationAsync(It.IsAny<ReservationPayload>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(reservationId);

            var reservationService = new ReservationService(_reservationProvider.Object);

            var result = await reservationService.AddReservationAsync(reservationPayload, CancellationToken.None);

            Assert.NotNull(result);
            Assert.Equal(result.ReservationId, reservationId);
        }

        [Fact]
        public async Task AddReservation_ShouldFail_With_DuplicateReservtionName()
        {
            var reservationId = "reservation1";
            var mockedReservations = MockedReservations.GetReservations();
            var reservationPayload = MockedReservations.GetReservationPayloadNonRecurring();
            reservationPayload.Name = mockedReservations.First().Name;        

            _reservationProvider
               .Setup(_ => _.GetAllReservationsAsync(It.IsAny<CancellationToken>()))
               .ReturnsAsync(mockedReservations);

            _reservationProvider
                .Setup(_ => _.AddReservationAsync(It.IsAny<ReservationPayload>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(reservationId);

            var reservationService = new ReservationService(_reservationProvider.Object);

            var result = await reservationService.AddReservationAsync(reservationPayload, CancellationToken.None);

            Assert.NotNull(result);
            Assert.True(result.Status.Error);
            Assert.Equal(result.Status.Message, ErrorMessages.DuplicateReservationName.Format(reservationPayload.Name));
        }

        [Fact]
        public async Task AddReservation_ShouldFail_If_No_WorkcenterAssociated()
        {
            var reservationId = "reservation1";
            var mockedReservations = MockedReservations.GetReservations();
            var reservationPayload = MockedReservations.GetReservationPayloadNonRecurring();
            reservationPayload.WorkcenterReservations = new List<WorkcenterReservationPayload>();

            _reservationProvider
               .Setup(_ => _.GetAllReservationsAsync(It.IsAny<CancellationToken>()))
               .ReturnsAsync(mockedReservations);

            _reservationProvider
                .Setup(_ => _.AddReservationAsync(It.IsAny<ReservationPayload>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(reservationId);

            var reservationService = new ReservationService(_reservationProvider.Object);

            var result = await reservationService.AddReservationAsync(reservationPayload, CancellationToken.None);

            Assert.NotNull(result);
            Assert.True(result.Status.Error);
            Assert.Equal(result.Status.Message, ErrorMessages.WorkcenterReservationNotFound);

            _reservationProvider.Verify(_ => _.GetAllReservationsAsync(It.IsAny<CancellationToken>()), Times.Never);
            _reservationProvider.Verify(_ => _.AddReservationAsync(It.IsAny<ReservationPayload>(), It.IsAny<CancellationToken>()), Times.Never);
        }

        [Fact]
        public async Task AddReservation_ShouldFail_With_DuplicateWorkcenterEquipmentCombination()
        {
            var reservationId = "reservation1";
            var mockedReservations = MockedReservations.GetReservations();
            var mockedWorkcenterReservations = MockedReservations.GetWorkcenterReservations();

            foreach (var item in mockedReservations)
                item.WorkcenterReservations = mockedWorkcenterReservations.Where(x => x.ReservationId == item.Id).ToList();
            
            var reservationPayload = GetReservationPayloadNonRecurring();
            reservationPayload.StartDate = mockedReservations.First().StartDate;    

            _reservationProvider
               .Setup(_ => _.GetAllReservationsAsync(It.IsAny<CancellationToken>()))
               .ReturnsAsync(mockedReservations);

            _reservationProvider
                .Setup(_ => _.AddReservationAsync(It.IsAny<ReservationPayload>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(reservationId);

            var reservationService = new ReservationService(_reservationProvider.Object);

            var result = await reservationService.AddReservationAsync(reservationPayload, CancellationToken.None);

            Assert.NotNull(result);
            Assert.True(result.Status.Error);
            Assert.Equal(result.Status.Message, ErrorMessages.ReservationCombinationExists.Format(mockedReservations.First().Name));

            _reservationProvider.Verify(_ => _.GetAllReservationsAsync(It.IsAny<CancellationToken>()), Times.Once);
            _reservationProvider.Verify(_ => _.AddReservationAsync(It.IsAny<ReservationPayload>(), It.IsAny<CancellationToken>()), Times.Never);
        }

        [Fact]
        public async Task EditReservation_ShouldSuccess()
        {
            _reservationProvider
                .Setup(_ => _.GetAllReservationsAsync(It.IsAny<CancellationToken>()))
                .ReturnsAsync(new List<DataModels.Reservation>());

            _reservationProvider
                .Setup(_ => _.EditReservationAsync(It.IsAny<EditReservationPayload>(), It.IsAny<DataModels.Reservation>(), It.IsAny<CancellationToken>()))
                .Returns(Task.CompletedTask);

            var reservationService = new ReservationService(_reservationProvider.Object);

            var result = await reservationService.EditReservationAsync(It.IsAny<EditReservationPayload>(), CancellationToken.None);

            Assert.NotNull(result);
        }

        [Fact]
        public async Task EditReservation_ShouldFailWith_DuplicateReservationName()
        {
            var mockedReservations = MockedReservations.GetReservations();
            var reservationPayload = GetEditReservationPayloadNonRecurring();
            reservationPayload.Name = mockedReservations.First().Name;

            _reservationProvider
                .Setup(_ => _.GetAllReservationsAsync(It.IsAny<CancellationToken>()))
                .ReturnsAsync(mockedReservations);

            _reservationProvider
                .Setup(_ => _.EditReservationAsync(It.IsAny<EditReservationPayload>(), It.IsAny<DataModels.Reservation>(), It.IsAny<CancellationToken>()))
                .Returns(Task.CompletedTask);

            var reservationService = new ReservationService(_reservationProvider.Object);

            var result = await reservationService.EditReservationAsync(reservationPayload, CancellationToken.None);

            Assert.NotNull(result);
            Assert.True(result.Status.Error); 
            Assert.Equal(result.Status.Message, ErrorMessages.DuplicateReservationName.Format(reservationPayload.Name));

        }

        [Fact]
        public async Task EditReservation_ShouldFail_With_DuplicateWorkcenterEquipmentCombination()
        {
            var mockedReservations = MockedReservations.GetReservations();
            var mockedWorkcenterReservations = MockedReservations.GetWorkcenterReservations();

            foreach (var item in mockedReservations)
                item.WorkcenterReservations = mockedWorkcenterReservations.Where(x => x.ReservationId == item.Id).ToList();

            var reservationPayload = GetEditReservationPayloadNonRecurring();
            reservationPayload.StartDate = mockedReservations.First().StartDate;

            _reservationProvider
               .Setup(_ => _.GetAllReservationsAsync(It.IsAny<CancellationToken>()))
               .ReturnsAsync(mockedReservations);

            _reservationProvider
                .Setup(_ => _.EditReservationAsync(It.IsAny<EditReservationPayload>(),It.IsAny<DataModels.Reservation>(), It.IsAny<CancellationToken>()))
                .Returns(Task.CompletedTask);

            var reservationService = new ReservationService(_reservationProvider.Object);

            var result = await reservationService.EditReservationAsync(reservationPayload, CancellationToken.None);

            Assert.NotNull(result);
            Assert.True(result.Status.Error);
            Assert.Equal(result.Status.Message, ErrorMessages.ReservationCombinationExists.Format(mockedReservations.First().Name));

            _reservationProvider.Verify(_ => _.GetAllReservationsAsync(It.IsAny<CancellationToken>()), Times.Once);
            _reservationProvider.Verify(_ => _.EditReservationAsync(It.IsAny<EditReservationPayload>(), It.IsAny<DataModels.Reservation>(), It.IsAny<CancellationToken>()), Times.Never);
        }

        private static ReservationPayload GetReservationPayloadNonRecurring()
        {
            return new ReservationPayload()
            {
                Name = "Reservation 1",
                FacilityId = "04f6ffbc-7751-4c61-9591-ebf7fc409c6c",
                CreatedBy = "abhijit.patil",
                IsRecurring = false,
                ExpirationDays = 1,
                StartDate = DateTime.Now,
                Customers = new List<string> {},
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
        public static EditReservationPayload GetEditReservationPayloadNonRecurring()
        {
            return new EditReservationPayload()
            {
                Id = "reservation2",
                Name = "Reservation 1",
                FacilityId = "04f6ffbc-7751-4c61-9591-ebf7fc409c6c",
                CreatedBy = "abhijit.patil",
                IsRecurring = false,
                ExpirationDays = 1,
                StartDate = DateTime.Now,
                Customers = new List<string> {},
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
    }
}

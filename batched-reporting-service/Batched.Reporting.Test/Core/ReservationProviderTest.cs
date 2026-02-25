using Batched.Reporting.Contracts.Interfaces;
using Batched.Reporting.Contracts.Models;
using Batched.Reporting.Core.Core;
using Batched.Reporting.Test.MockedEntities.Reservations;
using Moq;
using Xunit;
using DataModels = Batched.Common.Data.Tenants.Sql.Models;

namespace Batched.Reporting.Test.Core
{
    public class ReservationProviderTest : BaseTest<ReservationProvider>
    {
        private readonly Mock<IReservationsRepository> _reservationRepository;


        public ReservationProviderTest() : base(typeof(IReservationsRepository))
        {
            _reservationRepository = new Mock<IReservationsRepository>();
        }

        [Fact]
        public async Task SearchReservationAsync_ShouldReturnData()
        {
            _reservationRepository
                .Setup(_ => _.GetAllReservationsAsync(It.IsAny<CancellationToken>()))
                .ReturnsAsync(new List<DataModels.Reservation>());

            var reservationProvider = new ReservationProvider(_reservationRepository.Object);
            var response = await reservationProvider.GetAllReservationsAsync(CancellationToken.None);

            Assert.NotNull(response);
        }

        [Fact]
        public async Task AddReservationAsync_ShouldSucceed_ForNonRecurringReservation()
        {
            var reservationPayload = MockedReservations.GetReservationPayloadNonRecurring();

            var reservationId = "reservation1";

            _reservationRepository
                .Setup(_ => _.AddReservationAsync(It.IsAny<DataModels.Reservation>(),It.IsAny<CancellationToken>()))
                .ReturnsAsync(reservationId);

            var reservationProvider = new ReservationProvider(_reservationRepository.Object);
            var response = await reservationProvider.AddReservationAsync(reservationPayload, CancellationToken.None);

            Assert.NotNull(response);
            Assert.Equal(response, reservationId);
        }

        [Fact]
        public async Task AddReservationAsync_ShouldSucceed_ForRecurringReservation()
        {
            var reservationPayload = MockedReservations.GetReservationPayloadRecurring();

            var reservationId = "reservation1";

            _reservationRepository
                .Setup(_ => _.AddReservationAsync(It.IsAny<DataModels.Reservation>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(reservationId);

            var reservationProvider = new ReservationProvider(_reservationRepository.Object);
            var response = await reservationProvider.AddReservationAsync(reservationPayload, CancellationToken.None);

            Assert.NotNull(response);
            Assert.Equal(response, reservationId);
        }

        [Fact]
        public async Task DeleteReservationAsync_ShouldSucceed()
        {
            var reservationId = "reservation1";

            _reservationRepository
                .Setup(_ => _.DeleteReservationAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
                .Returns(Task.CompletedTask);

            var reservationProvider = new ReservationProvider(_reservationRepository.Object);
            await reservationProvider.DeleteReservationAsync(reservationId, CancellationToken.None);

            _reservationRepository
               .Verify(_ => _.DeleteReservationAsync(It.Is<string>(r => r == reservationId), CancellationToken.None), Times.Once);
        }

        [Fact]
        public async Task EditReservationAsync_ShouldSucceed()
        {
            var reservationId = "reservation1";
            var editReservationPayload = MockedReservations.GetReservationPayloadNonRecurring();
            var payloadCustomerCount = editReservationPayload.Customers.Count;  
            
            var reservation = MockedReservations.GetReservations().FirstOrDefault(x => x.Id == reservationId);

            _reservationRepository
                .Setup(_ => _.UpdateReservationAsync(It.IsAny<DataModels.Reservation>(), It.IsAny<CancellationToken>()))
                .Returns(Task.CompletedTask);

            var reservationProvider = new ReservationProvider(_reservationRepository.Object);
            
            await reservationProvider.EditReservationAsync(editReservationPayload, reservation, CancellationToken.None);
            
            _reservationRepository
                .Verify(_ => _.UpdateReservationAsync(It.Is<DataModels.Reservation>(r => r.CustomerReservations.Count == payloadCustomerCount), CancellationToken.None), Times.Once);
        }

        [Fact]
        public async Task EditReservationAsync_ShouldSucceed_WithRecurrence()
        {
            var reservationId = "reservation1";
            var editReservationPayload = MockedReservations.GetReservationPayloadRecurring();
            var payloadCustomerCount = editReservationPayload.Customers.Count;

            var reservation = MockedReservations.GetReservations().FirstOrDefault(x => x.Id == reservationId);

            _reservationRepository
                .Setup(_ => _.UpdateReservationAsync(It.IsAny<DataModels.Reservation>(), It.IsAny<CancellationToken>()))
                .Returns(Task.CompletedTask);

            var reservationProvider = new ReservationProvider(_reservationRepository.Object);

            await reservationProvider.EditReservationAsync(editReservationPayload, reservation, CancellationToken.None);

            _reservationRepository
                .Verify(_ => _.UpdateReservationAsync(It.Is<DataModels.Reservation>(r => r.CustomerReservations.Count == payloadCustomerCount), CancellationToken.None), Times.Once);
            
            _reservationRepository
                .Verify(_ => _.UpdateReservationAsync(It.Is<DataModels.Reservation>(r => r.ReservationRecurrence != null), CancellationToken.None), Times.Once);
        }

        

    }
}

       
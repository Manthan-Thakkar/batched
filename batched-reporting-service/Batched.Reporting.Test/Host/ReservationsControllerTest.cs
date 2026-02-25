using Batched.Common;
using Batched.Reporting.Contracts;
using Batched.Reporting.Contracts.Errormap;
using Batched.Reporting.Contracts.Interfaces;
using Batched.Reporting.Contracts.Models;
using Batched.Reporting.Web.Controllers;
using Moq;
using Xunit;

namespace Batched.Reporting.Test.Host
{
    public class ReservationsControllerTest : BaseTest<ReservationsController>
    {
        private readonly Mock<IReservationService> _reservationService;

        public ReservationsControllerTest() : base(typeof(IReservationService))
        {
            _reservationService = new Mock<IReservationService>(MockBehavior.Strict);
        }

        [Fact]
        public async Task SearchReservationsAsync_Success()
        {
            _reservationService
                .Setup(_ => _.SearchReservationsAsync(It.IsAny<string>(), It.IsAny<string>(), It.IsAny<int>(), It.IsAny<int>(),
                It.IsAny<List<string>>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(new Contracts.Models.ReservationResponse());

            var controller = new ReservationsController(_reservationService.Object);

            var response = await controller.SearchReservationAsync(It.IsAny<string>(), It.IsAny<string>(), 1, 100, new List<string>(), CancellationToken.None);

            Assert.NotNull(response);
        }

        [Fact]
        public async Task SearchReservationsAsync_ThrowsException()
        {
            var exceptionMsg = "Exception message to be delivered";

            _reservationService
                .Setup(_ => _.SearchReservationsAsync(It.IsAny<string>(), It.IsAny<string>(), It.IsAny<int>(), It.IsAny<int>(),
                It.IsAny<List<string>>(), It.IsAny<CancellationToken>()))
                .ThrowsAsync(new ArgumentException(exceptionMsg));

            var controller = new ReservationsController(_reservationService.Object);

            async Task asyncAct()
            {
                await controller.SearchReservationAsync(It.IsAny<string>(), It.IsAny<string>(), 1, 100, new List<string>(), CancellationToken.None);
            }

            var exception = await Assert.ThrowsAsync<ArgumentException>(asyncAct);

            Assert.NotNull(exception);
            Assert.Equal(exceptionMsg, exception.Message);
        }

        [Fact]
        public async Task AddReservationAsync_Success()
        {
            _reservationService
                .Setup(_ => _.AddReservationAsync(It.IsAny<ReservationPayload>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(new Contracts.Models.AddReservationResponse());

            var controller = new ReservationsController(_reservationService.Object);

            var response = await controller.AddReservationAsync(It.IsAny<ReservationPayload>(), CancellationToken.None);

            Assert.NotNull(response);
        }

        [Fact]
        public async Task AddReservationAsync_ThrowsException()
        {
            var exceptionMsg = "Exception message to be delivered while adding reservation";
            _reservationService
                .Setup(_ => _.AddReservationAsync(It.IsAny<ReservationPayload>(), It.IsAny<CancellationToken>()))
                .ThrowsAsync(new ArgumentException(exceptionMsg));

            var controller = new ReservationsController(_reservationService.Object);
            async Task asyncAct()
            {
                await controller.AddReservationAsync(It.IsAny<ReservationPayload>(), CancellationToken.None);
            }

            var exception = await Assert.ThrowsAsync<ArgumentException>(asyncAct);

            Assert.NotNull(exception);
            Assert.Equal(exceptionMsg, exception.Message);
        }

        [Fact]
        public async Task EditReservationAsync_Success()
        {
            _reservationService
                .Setup(_ => _.EditReservationAsync(It.IsAny<EditReservationPayload>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(new Contracts.Models.EditReservationResponse());

            var controller = new ReservationsController(_reservationService.Object);

            var response = await controller.EditReservationAsync(It.IsAny<EditReservationPayload>(), CancellationToken.None);

            Assert.NotNull(response);
        }

        [Fact]
        public async Task EditReservationAsync_ThrowsException()
        {
            var exceptionMsg = "Exception message to be delivered while editing reservation";
            _reservationService
                .Setup(_ => _.EditReservationAsync(It.IsAny<EditReservationPayload>(), It.IsAny<CancellationToken>()))
                .ThrowsAsync(new ArgumentException(exceptionMsg));

            var controller = new ReservationsController(_reservationService.Object);
            async Task asyncAct()
            {
                await controller.EditReservationAsync(It.IsAny<EditReservationPayload>(), CancellationToken.None);
            }

            var exception = await Assert.ThrowsAsync<ArgumentException>(asyncAct);

            Assert.NotNull(exception);
            Assert.Equal(exceptionMsg, exception.Message);
        }



        [Fact]
        public async Task DeleteReservationAsync_Success()
        {
            _reservationService
                .Setup(_ => _.DeleteReservationAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(new Contracts.Models.DeleteReservationResponse());

            var controller = new ReservationsController(_reservationService.Object);

            var response = await controller.DeleteReservationAsync(It.IsAny<string>(), CancellationToken.None);

            Assert.NotNull(response);
        }

        [Fact]
        public async Task DeleteReservationAsync_ThrowsException()
        {
            var exceptionMsg = "Exception message to be delivered while editing reservation";
            _reservationService
                .Setup(_ => _.DeleteReservationAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
                .ThrowsAsync(new ArgumentException(exceptionMsg));

            var controller = new ReservationsController(_reservationService.Object);
            async Task asyncAct()
            {
                await controller.DeleteReservationAsync(It.IsAny<string>(), CancellationToken.None);
            }

            var exception = await Assert.ThrowsAsync<ArgumentException>(asyncAct);

            Assert.NotNull(exception);
            Assert.Equal(exceptionMsg, exception.Message);
        }
    }
}

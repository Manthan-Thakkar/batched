using Batched.Common;
using Batched.Reporting.Test.MockedEntities;
using Moq;
using Xunit;
using static Batched.Common.Testing.Mock.MockDbContext;
using Batched.Common.Testing.Mock;
using Batched.Reporting.Data.Repository;
using Batched.Reporting.Contracts.Errormap;
using Batched.Reporting.Contracts;

using ContractModels = Batched.Reporting.Contracts.Models.LeadTimeManager;
using CommonModels = Batched.Common.Data.Tenants.Sql.Models;

namespace Batched.Reporting.Test.Repository
{
    public class LeadTimeExceptionsRepositoryTest : BaseTest<LeadTimeExceptionsRepository>
    {
        private readonly Mock<UnitOfWorkFactory> _unitOfWorkFactory;
        private readonly Mock<CommonModels.TenantContext> _dbContext;
        private List<CommonModels.LeadTimeException> exceptions;

        public LeadTimeExceptionsRepositoryTest() : base(typeof(UnitOfWorkFactory))
        {
            _unitOfWorkFactory = new Mock<UnitOfWorkFactory>(null);
            _dbContext = new Mock<CommonModels.TenantContext>();

            _unitOfWorkFactory
                .Setup(x => x.BeginUnitOfWork(DBContextLevel.Tenant, DbAccessMode.read))
                .Returns(() => new MockUnitOfWork(_dbContext.Object));

            exceptions = MockedLeadTimeExceptions.LeadTimeExceptions;

            MockContext(_dbContext, exceptions);
        }


        [Fact]
        public async Task GetLeadTimeExceptionsAsync_ShouldReturn_LeadTimeExceptionsList()
        {
            var repo = new LeadTimeExceptionsRepository(_unitOfWorkFactory.Object);

            var response = await repo.GetLeadTimeExceptionsAsync(It.IsAny<CancellationToken>());

            Assert.NotNull(response);
            Assert.Equal(2, response.Count);
        }


        [Fact(Skip = "Failing due to EF Core mock issue.")]
        public async Task AddLeadTimeExceptionsAsync_Should_AddException()
        {
            _unitOfWorkFactory
                .Setup(x => x.BeginUnitOfWork(DBContextLevel.Tenant, DbAccessMode.write))
                .Returns(() => new MockUnitOfWork(_dbContext.Object));

            var repo = new LeadTimeExceptionsRepository(_unitOfWorkFactory.Object);

            var addRequest = new CommonModels.LeadTimeException
            {
                Id = "4233c3a8-c524-4a2f-88c2-5b177955baf2",
                LeadTimeInDays = 1,
                Name = "New Rule",
                Reason = "Reason",
                CreatedBy = "Sirius Black",
                ModifiedBy = "Sirius Black",
                CreatedOnUtc = DateTime.UtcNow,
                ModifiedOnUtc = DateTime.UtcNow
            };

            await repo.AddLeadTimeExceptionAsync(addRequest);

            Assert.NotNull(exceptions);
            Assert.Equal(3, exceptions.Count);
        }

        [Fact]
        public async Task AddLeadTimeExceptionsAsync_ShouldThrowException_DuplicateLeadTimeExceptionName()
        {
            _unitOfWorkFactory
                .Setup(x => x.BeginUnitOfWork(DBContextLevel.Tenant, DbAccessMode.write))
                .Returns(() => new MockUnitOfWork(_dbContext.Object));

            var repo = new LeadTimeExceptionsRepository(_unitOfWorkFactory.Object);

            var addRequest = new CommonModels.LeadTimeException
            {
                Id = "4233c3a8-c524-4a2f-88c2-5b177955baf2",
                LeadTimeInDays = 1,
                Name = "Priority Rule",
                Reason = "Reason",
                CreatedBy = "Sirius Black",
                ModifiedBy = "Sirius Black",
                CreatedOnUtc = DateTime.UtcNow,
                ModifiedOnUtc = DateTime.UtcNow
            };

            async Task asyncAct() { await repo.AddLeadTimeExceptionAsync(addRequest); }

            var exception = await Assert.ThrowsAsync<BadRequestException>(asyncAct);

            Assert.NotNull(exception);
            Assert.Equal(ErrorCodes.DuplicateLeadTimeExceptionName, exception.Code);
            Assert.Equal(ErrorMessages.DuplicateLeadTimeExceptionName, exception.Message);
        }


        [Fact(Skip = "Failing due to EF Core mock issue.")]
        public async Task EditLeadTimeExceptionsAsync_Should_EditException()
        {
            _unitOfWorkFactory
                .Setup(x => x.BeginUnitOfWork(DBContextLevel.Tenant, DbAccessMode.write))
                .Returns(() => new MockUnitOfWork(_dbContext.Object));

            var repo = new LeadTimeExceptionsRepository(_unitOfWorkFactory.Object);

            var editRequest = new ContractModels.EditExceptionRequest
            {
                Id = "4233c3a8-c524-4a2f-88c2-5b177955baf7",
                LeadTimeInDays = 1,
                Name = "Name",
                Reason = "Reason"
            };

            await repo.EditLeadTimeExceptionAsync(editRequest);

            Assert.NotNull(exceptions);
            Assert.Equal(2, exceptions.Count);
        }

        [Fact]
        public async Task EditLeadTimeExceptionsAsync_ShouldThrowException_InvalidExceptionId()
        {
            _unitOfWorkFactory
                .Setup(x => x.BeginUnitOfWork(DBContextLevel.Tenant, DbAccessMode.write))
                .Returns(() => new MockUnitOfWork(_dbContext.Object));

            var repo = new LeadTimeExceptionsRepository(_unitOfWorkFactory.Object);

            var editRequest = new ContractModels.EditExceptionRequest
            {
                Id = "4233c3a8-c524-4a2f-88c2-5b177955baf2",
                LeadTimeInDays = 1,
                Name = "Name",
                Reason = "Reason"
            };

            async Task asyncAct() { await repo.EditLeadTimeExceptionAsync(editRequest); }

            var exception = await Assert.ThrowsAsync<BadRequestException>(asyncAct);

            Assert.NotNull(exception);
            Assert.Equal(ErrorCodes.InvalidLeadTimeExceptionId, exception.Code);
            Assert.Equal(ErrorMessages.InvalidLeadTimeExceptionId, exception.Message);
        }

        [Fact]
        public async Task EditLeadTimeExceptionsAsync_ShouldThrowException_DuplicateLeadTimeExceptionName()
        {
            _unitOfWorkFactory
                .Setup(x => x.BeginUnitOfWork(DBContextLevel.Tenant, DbAccessMode.write))
                .Returns(() => new MockUnitOfWork(_dbContext.Object));

            var repo = new LeadTimeExceptionsRepository(_unitOfWorkFactory.Object);

            var editRequest = new ContractModels.EditExceptionRequest
            {
                Id = "4233c3a8-c524-4a2f-88c2-5b177955baf7",
                LeadTimeInDays = 1,
                Name = "Priority Rule",
                Reason = "Reason"
            };

            async Task asyncAct() { await repo.EditLeadTimeExceptionAsync(editRequest); }

            var exception = await Assert.ThrowsAsync<BadRequestException>(asyncAct);

            Assert.NotNull(exception);
            Assert.Equal(ErrorCodes.DuplicateLeadTimeExceptionName, exception.Code);
            Assert.Equal(ErrorMessages.DuplicateLeadTimeExceptionName, exception.Message);
        }


        [Fact(Skip = "Failing due to EF Core mock issue.")]
        public async Task DeleteLeadTimeExceptionsAsync_ShouldDelete_LeadTimeException()
        {
            _unitOfWorkFactory
                .Setup(x => x.BeginUnitOfWork(DBContextLevel.Tenant, DbAccessMode.write))
                .Returns(() => new MockUnitOfWork(_dbContext.Object));

            var repo = new LeadTimeExceptionsRepository(_unitOfWorkFactory.Object);

            await repo.DeleteLeadTimeExceptionAsync("4233c3a8-c524-4a2f-88c2-5b177955baf7");

            Assert.NotNull(exceptions);
            Assert.Single(exceptions);
        }

        [Fact]
        public async Task DeleteLeadTimeExceptionsAsync_ShouldThrowException_InvalidExceptionId()
        {
            _unitOfWorkFactory
                .Setup(x => x.BeginUnitOfWork(DBContextLevel.Tenant, DbAccessMode.write))
                .Returns(() => new MockUnitOfWork(_dbContext.Object));

            var repo = new LeadTimeExceptionsRepository(_unitOfWorkFactory.Object);

            async Task asyncAct() { await repo.DeleteLeadTimeExceptionAsync("4233c3a8-c524-4a2f-88c2-5b177955baf2"); }

            var exception = await Assert.ThrowsAsync<BadRequestException>(asyncAct);

            Assert.NotNull(exception);
            Assert.Equal(ErrorCodes.InvalidLeadTimeExceptionId, exception.Code);
            Assert.Equal(ErrorMessages.InvalidLeadTimeExceptionId, exception.Message);
        }
    }
}

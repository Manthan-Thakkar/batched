using Batched.Common;
using Batched.Common.Data.Sql.Models;
using Batched.Common.Testing.Mock;
using Batched.Reporting.Core.Core;
using Moq;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Xunit;    

namespace Batched.Reporting.Test
{
    public class HealthCheckUnitTest : BaseTest<HealthCheck>
    {
        private readonly Mock<UnitOfWorkFactory> _unitOfWorkFactory;
        private readonly Mock<BatchedContext> _dbContext;

        public HealthCheckUnitTest() : base(typeof(UnitOfWorkFactory))
        {
            _unitOfWorkFactory = new Mock<UnitOfWorkFactory>(null);
            _dbContext = new Mock<BatchedContext>();

            _unitOfWorkFactory
                .Setup(x => x.BeginUnitOfWork(DBContextLevel.Tenant, DbAccessMode.read))
                .Returns(() => new MockUnitOfWork(_dbContext.Object));
        }
        [Fact]
        public async Task HealthCheck_ShouldReturnTrue()
        {
            var sut = new HealthCheck(_unitOfWorkFactory.Object);
            var result = await sut.HealthCheckAsync(false, new CancellationToken());

            Assert.True(result);
        }
    }
}

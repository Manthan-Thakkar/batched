using Batched.Common;
using Batched.Reporting.Contracts.Interfaces;
using Batched.Reporting.Contracts.Models;
using Microsoft.EntityFrameworkCore;
using Commons = Batched.Common.Data.Tenants.Sql.Models;

namespace Batched.Reporting.Data
{
    public class CustomerRepository : ICustomerRepository
    {
        private readonly UnitOfWorkFactory _unitOfWorkFactory;
        public CustomerRepository(UnitOfWorkFactory unitOfWorkFactory)
        {
            _unitOfWorkFactory = unitOfWorkFactory;
        }
        public async Task<List<CustomerDetails>> GetAllCustomerDetailsAsync()
        {

            using (Tracer.Benchmark("Facility-repo-get-facility-holiday-count"))
            using (var unitOfWork = _unitOfWorkFactory.BeginUnitOfWork(DBContextLevel.Tenant, DbAccessMode.read))
            {
                return await unitOfWork.Repository<Commons.CustomerMaster>().GetQueryable()
                    .Where(x => x.IsActive ?? false)
                    .Select(x => new CustomerDetails
                    {
                        CustomerId = x.Id,
                        CustomerName = x.CustomerName,
                        SourceCustomerId = x.SourceCustomerId,
                    }).ToListAsync();
            }

        }
    }
}

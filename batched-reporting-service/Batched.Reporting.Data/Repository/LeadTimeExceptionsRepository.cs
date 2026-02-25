using Batched.Common;
using Batched.Reporting.Contracts;
using Batched.Reporting.Contracts.Errormap;
using Batched.Reporting.Contracts.Models.LeadTimeManager;
using Batched.Reporting.Data.Translators;
using Microsoft.EntityFrameworkCore;
using System;
using System.Threading;
using CommonModels = Batched.Common.Data.Tenants.Sql.Models;

namespace Batched.Reporting.Data.Repository
{
    public class LeadTimeExceptionsRepository : ILeadTimeExceptionsRepository
    {
        private readonly UnitOfWorkFactory _unitOfWorkFactory;

        public LeadTimeExceptionsRepository(UnitOfWorkFactory unitOfWorkFactory)
        {
            _unitOfWorkFactory = unitOfWorkFactory;
        }

        public async Task<List<LeadTimeException>> GetLeadTimeExceptionsAsync(CancellationToken cancellationToken)
        {
            using (Tracer.Benchmark("get-lead-time-exceptions"))
            using (var unitOfWork = _unitOfWorkFactory.BeginUnitOfWork(DBContextLevel.Tenant, DbAccessMode.read))
            {
                var exceptions = await unitOfWork.Repository<CommonModels.LeadTimeException>().GetQueryable().OrderByDescending(x => x.ModifiedOnUtc).ThenBy(x => x.Name).ToListAsync(cancellationToken);
                return exceptions.Translate();
            }
        }

        public async Task<CommonModels.LeadTimeException> GetLeadTimeExceptionByIdAsync(string exceptionId, CancellationToken cancellationToken)
        {
            using (Tracer.Benchmark("get-lead-time-exception-by-id"))
            using (var unitOfWork = _unitOfWorkFactory.BeginUnitOfWork(DBContextLevel.Tenant, DbAccessMode.read))
            {
                return await unitOfWork.Repository<CommonModels.LeadTimeException>().GetSingleAsync(x => x.Id == exceptionId);
            }
        }

        public async Task<List<CommonModels.LeadTimeException>> GetLeadTimeExceptionsByNameAsync(string exceptionName, CancellationToken cancellationToken)
        {
            using (Tracer.Benchmark("get-lead-time-exception-by-name"))
            using (var unitOfWork = _unitOfWorkFactory.BeginUnitOfWork(DBContextLevel.Tenant, DbAccessMode.read))
            {
                var exceptions = await unitOfWork.Repository<CommonModels.LeadTimeException>().GetMultiAsync(x => x.Name.ToLower() == exceptionName.ToLower());
                return exceptions.ToList();
            }
        }

        public async Task AddLeadTimeExceptionAsync(CommonModels.LeadTimeException exception)
        {
            using (Tracer.Benchmark("add-lead-time-exception"))
            using (var unitOfWork = _unitOfWorkFactory.BeginUnitOfWork(DBContextLevel.Tenant, DbAccessMode.write))
            {
                var exceptions = await unitOfWork.Repository<CommonModels.LeadTimeException>().GetMultiAsync(x => x.Name.ToLower() == exception.Name.ToLower());

                if (exceptions.ToList().Any())
                    throw new BadRequestException(ErrorCodes.DuplicateLeadTimeExceptionName, ErrorMessages.DuplicateLeadTimeExceptionName);

                await unitOfWork.Repository<CommonModels.LeadTimeException>().AddAsync(exception);
                unitOfWork.Complete();
            }
        }

        public async Task EditLeadTimeExceptionAsync(EditExceptionRequest exception)
        {
            using (Tracer.Benchmark("edit-lead-time-exception"))
            using (var unitOfWork = _unitOfWorkFactory.BeginUnitOfWork(DBContextLevel.Tenant, DbAccessMode.write))
            {
                var expt = await unitOfWork.Repository<CommonModels.LeadTimeException>().GetSingleAsync(x => x.Id == exception.Id);

                if (expt == null)
                    throw new BadRequestException(ErrorCodes.InvalidLeadTimeExceptionId, ErrorMessages.InvalidLeadTimeExceptionId);

                var exceptions = await unitOfWork.Repository<CommonModels.LeadTimeException>().GetMultiAsync(x => x.Name.ToLower() == exception.Name.ToLower() && x.Id != exception.Id);

                if (exceptions.ToList().Any())
                    throw new BadRequestException(ErrorCodes.DuplicateLeadTimeExceptionName, ErrorMessages.DuplicateLeadTimeExceptionName);

                expt.Name = exception.Name;
                expt.Reason = exception.Reason;
                expt.LeadTimeInDays = exception.LeadTimeInDays;
                expt.ModifiedOnUtc = DateTime.UtcNow;

                await unitOfWork.Repository<CommonModels.LeadTimeException>().UpdateAsync(expt);
                unitOfWork.Complete();
            }
        }

        public async Task DeleteLeadTimeExceptionAsync(string exceptionId)
        {
            using (Tracer.Benchmark("delete-lead-time-exception"))
            using (var unitOfWork = _unitOfWorkFactory.BeginUnitOfWork(DBContextLevel.Tenant, DbAccessMode.write))
            {
                var expt = await unitOfWork.Repository<CommonModels.LeadTimeException>().GetSingleAsync(x => x.Id == exceptionId);

                if (expt == null)
                    throw new BadRequestException(ErrorCodes.InvalidLeadTimeExceptionId, ErrorMessages.InvalidLeadTimeExceptionId);

                await unitOfWork.Repository<CommonModels.LeadTimeException>().RemoveAsync(expt);
                unitOfWork.Complete();
            }
        }
    }
}
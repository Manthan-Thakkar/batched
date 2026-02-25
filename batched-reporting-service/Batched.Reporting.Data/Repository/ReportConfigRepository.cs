using Batched.Common;
using Batched.Reporting.Contracts.Interfaces;
using static Batched.Reporting.Shared.BatchedConstants;
using Microsoft.EntityFrameworkCore;
using BatchedModel = Batched.Common.Data.Sql.Models;
using TenantModel = Batched.Common.Data.Tenants.Sql.Models;
using Batched.Reporting.Contracts.Models;

namespace Batched.Reporting.Data.Repository
{
    public class ReportConfigRepository : IReportConfigRepository
    {
        private readonly UnitOfWorkFactory _unitOfWorkFactory;

        public ReportConfigRepository(UnitOfWorkFactory unitOfWorkFactory)
        {
            this._unitOfWorkFactory = unitOfWorkFactory;
        }

        private async Task<List<string>> GetTenantAllTicketAttributesAsync()
        {
            using (var unitOfWork = _unitOfWorkFactory.BeginUnitOfWork(DBContextLevel.Tenant, DbAccessMode.read))
            {
                var allticketAttributes = await unitOfWork.Repository<TenantModel.TicketAttribute>()
                  .GetQueryable().Where(m => m.IsEnabled && !string.IsNullOrEmpty(m.TicketAttributeFormula.RuleText)).Select(m => m.Name)
                  .ToListAsync();

                return allticketAttributes;
            }
        }
        public async Task<List<ReportViewField>> GetBatchedDefaultFieldsAsync(string reportName)
        {
            using (var unitOfWork = _unitOfWorkFactory.BeginUnitOfWork(DBContextLevel.Batched, DbAccessMode.read))
            {
                var reportMasterRepo = unitOfWork.Repository<BatchedModel.ReportMaster>();

                var currentReport = await reportMasterRepo.GetQueryable().Where(m => m.Name.ToUpper() == reportName.ToUpper()).FirstOrDefaultAsync();

                if (currentReport != null)
                {
                    var currentReportViews = unitOfWork.Repository<BatchedModel.ReportView>().GetQueryable().Where(m => m.ReportId == currentReport.Id).ToList();

                    if (currentReportViews != null && currentReportViews.Any())
                    {
                        var reportViewId = currentReportViews.First().Id;

                        var currentReportViewFields = unitOfWork.Repository<BatchedModel.ReportViewField>().GetQueryable().Where(m => m.ReportViewId == reportViewId).ToList();

                        return currentReportViewFields.Where(m => m.IsDefault).Select(m => new ReportViewField()
                        {
                            Id = m.Id,
                            FieldName = m.FieldName,
                            DisplayName = m.DisplayName,
                            Category = m.Category,
                            Type = m.Type,
                            IsDefault = m.IsDefault,
                            JsonName = m.JsonName,
                            Sequence = m.Sequence,
                            SortField = m.SortField,
                            Action = m.Action
                        }).ToList();
                    }
                }

                return new List<ReportViewField>();
            }
        }

        public async Task<List<ReportViewField>> GetReportFields(string viewId, string reportName)
        {
            var tenantFields = await this.GetTenantFields(viewId, reportName);

            if (tenantFields == null)
            {
                var currentTenantTicketAttrbutesTask = this.GetTenantAllTicketAttributesAsync();

                var currentBatchedFieldsTask = this.GetBatchedFields(reportName);

                await Task.WhenAll(currentTenantTicketAttrbutesTask, currentBatchedFieldsTask);

                var currentTenantTicketAttrbutes = currentTenantTicketAttrbutesTask.Result;
                var currentBatchedFields = currentBatchedFieldsTask.Result;

                if (currentBatchedFields == null)
                    return null;

                List<ReportViewField> finalResult = new List<ReportViewField>();

                finalResult.AddRange(currentBatchedFields.Where(m => m.Category == FieldCategory.Ticket).ToList());
                finalResult.AddRange(currentBatchedFields.Where(m => m.Category == FieldCategory.StagingComponent).ToList());
                foreach (var item in currentBatchedFields.Where(m => m.Category == FieldCategory.TicketAttribute))
                {
                    if (currentTenantTicketAttrbutes.Contains(item.FieldName))
                    {
                        finalResult.Add(item);
                    }
                }

                return finalResult;
            }

            return tenantFields;
        }

        public async Task<List<ReportViewField>> GetTenantFields(string viewId, string reportName)
        {

            using (var unitOfWork = _unitOfWorkFactory.BeginUnitOfWork(DBContextLevel.Tenant, DbAccessMode.read))
            {
                var currentViewFields = new List<TenantModel.ReportViewField>();

                if (!string.IsNullOrEmpty(viewId))
                {
                    currentViewFields = await unitOfWork.Repository<TenantModel.ReportViewField>().GetQueryable().Where(m => m.ReportViewId == viewId).ToListAsync();
                }
                else
                {
                    var currentReport = unitOfWork.Repository<TenantModel.ReportMaster>().GetQueryable().FirstOrDefault(m => m.Name.ToUpper() == reportName.ToUpper());
                    if (currentReport != null)
                    {
                        var currentReportView = unitOfWork.Repository<TenantModel.ReportView>().GetQueryable().FirstOrDefault(m => m.ReportId == currentReport.Id && m.IsDefault == true);
                        if (currentReportView != null)
                        {
                            currentViewFields = currentReportView.ReportViewFields.ToList();
                        }
                    }
                }

                return currentViewFields.Any() ? currentViewFields.Select(m => new ReportViewField()
                {
                    Id = m.Id,
                    FieldName = m.FieldName,
                    DisplayName = m.DisplayName,
                    Category = m.Category,
                    Type = m.Type,
                    IsDefault = m.IsDefault,
                    JsonName = m.JsonName,
                    Sequence = m.Sequence,
                    Action = m.Action,
                    SortField = m.SortField,
                    ReportViewId = m.ReportViewId
                }).ToList() : null;
                ;
            }
        }

        private async Task<List<ReportViewField>> GetBatchedFields(string reportName)
        {
            //// To Do - Add code to remove Ticket atttributes which are not present in Tenant

            using (var unitOfWork = _unitOfWorkFactory.BeginUnitOfWork(DBContextLevel.Batched, DbAccessMode.read))
            {
                var currentReport = unitOfWork.Repository<BatchedModel.ReportMaster>().GetQueryable().FirstOrDefault(m => m.Name.ToUpper() == reportName.ToUpper());
                if (currentReport != null)
                {
                    var currentReportView = unitOfWork.Repository<BatchedModel.ReportView>().GetQueryable().FirstOrDefault(m => m.ReportId == currentReport.Id);
                    if (currentReportView != null)
                    {
                        var currentViewFields = await unitOfWork.Repository<BatchedModel.ReportViewField>().GetQueryable().Where(m => m.ReportViewId == currentReportView.Id).ToListAsync();

                        return currentViewFields.Select(m => new ReportViewField() { Id = m.Id, FieldName = m.FieldName, DisplayName = m.DisplayName, Category = m.Category, Type = m.Type, IsDefault = m.IsDefault, JsonName = m.JsonName, Sequence = m.Sequence, Action = m.Action, SortField = m.SortField, ReportViewId = m.ReportViewId }).ToList();
                    }
                }
            }

            return null;
        }

    }
}

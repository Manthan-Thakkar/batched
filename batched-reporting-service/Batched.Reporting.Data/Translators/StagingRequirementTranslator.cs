using Batched.Common.Data.Sql.Extensions;
using Batched.Reporting.Contracts.Models.StagingRequirement;
using Batched.Reporting.Data.DataModels;
using Batched.Reporting.Shared;
using Batched.Scheduling.Data;
using System.Data;
using static Batched.Reporting.Shared.BatchedConstants;


namespace Batched.Reporting.Data.Translators
{
    public static class StagingRequirementTranslator
    {
        public static StagingRequirementData TranslateToReportData(DataTableCollection dataTables, DateTime tenantLocalDateTime, List<StagingRequirements> stagingRequirements, StagingRequirementReportFilter filter, List<string> configurableViewTicketAttributes)
        {
            var stagingRequirementsReportData = dataTables.ParseTable<StagingRequirementsDataRow>("StagingRequirementReport");
            var totalCount = dataTables.ParseTable<TotalCountDataRow>("StagingRequirementReport_count");
            var ticketTaskStagingInfo = dataTables.ParseTable<TicketTaskStagingInfoDataRow>("TicketTaskStagingInfo");
            var timeWindow = dataTables.ParseTable<TimeWindowDatarow>("timeWindow");
            var ticketAttributeValues = dataTables.ParseTable<TicketAttributeValueDataRow>("ticketAttributeValues");

            var scheduledTicketTaskStagingData = TranslateToScheduledTaskStagingData(stagingRequirementsReportData, ticketAttributeValues, ticketTaskStagingInfo, tenantLocalDateTime, configurableViewTicketAttributes);

            var sortBy = filter.SortBy;
            var isSortByStagingComponent = sortBy != null && sortBy != ""
                                                && StagingRequirementReportConstant.StagingRequirementAttributes.Keys.Select(x => x.ToUpper()).ToList()
                                                        .Contains(sortBy.Substring(1).ToUpper());

            if (isSortByStagingComponent)
            {
                scheduledTicketTaskStagingData = OrderStagingDataByStagingComponent(scheduledTicketTaskStagingData, sortBy, filter);
            }
            else if (sortBy == null || sortBy == "")
            {
                scheduledTicketTaskStagingData = scheduledTicketTaskStagingData
                                    .OrderByDescending(x => x.IsStagingUrgent).ToList();
            }

            return new StagingRequirementData
            {
                ScheduledTasksStagingData = scheduledTicketTaskStagingData
                                    .Skip(filter.PageSize * (filter.PageNumber - 1))
                                    .Take(filter.PageSize).ToList(),

                TotalCount = totalCount.Count > 0 ? totalCount[0].TotalCount : 0
            };
        }

        public static List<TicketTaskStagingData> TranslateToKPIData(DataTableCollection dataTables)
        {
            var kpiData = dataTables.ParseTable<StagingRequirementKPIDataRow>("StagingRequirement_FinalData");

            return kpiData
                    .GroupBy(x => new
                    {
                        x.TicketId,
                        x.TicketNumber,
                        x.TaskName,
                        x.StagingReq,
                        x.StartsAt,
                        x.EndsAt
                    })
                    .Select(z => new TicketTaskStagingData
                    {
                        TicketId = z.Key.TicketId,
                        TicketNumber = z.Key.TicketNumber,
                        TaskName = z.Key.TaskName,
                        StagingReq = z.Key.StagingReq,
                        StartsAt = z.Key.StartsAt,
                        EndsAt = z.Key.EndsAt,
                        StagingStatus = z
                                        .Where(y => y.StagingNameKey != null)
                                        .Select(y => new StagingStatus
                                        {
                                            StagingNameKey = y.StagingNameKey,
                                            IsStaged = y.IsStaged
                                        }).ToList()
                    })
                    .ToList();
        }

        private static List<ScheduledTasksStagingData> TranslateToScheduledTaskStagingData(List<StagingRequirementsDataRow> stagingRequirementsReportData
            , List<TicketAttributeValueDataRow> ticketAttributeValues, List<TicketTaskStagingInfoDataRow> ticketTaskStagingInfo, DateTime tenantLocalDateTime, List<string> configurableViewTicketAttributes)
        {
            var result = new List<ScheduledTasksStagingData>();
            var ticketAttributesDictionary = ticketAttributeValues
                                    .GroupBy(m => m.TicketId)
                                    .ToDictionary(m => m.Key, m => m.ToDictionary(x => x.Name, x => x.Value));

            var stagingInfoDictionary = ticketTaskStagingInfo
                                .GroupBy(m => m.TicketId)
                                .ToDictionary(m => m.Key, m => m.ToDictionary(x => (x.TaskName, x.StagingNameKey), x => x.IsStaged ?? false));

            foreach (var item in stagingRequirementsReportData)
            {
                var stagingComponents = new List<StagingComponent>();

                if (item.StagingRequirements != null && item.StagingRequirements.Count > 0)
                {
                    foreach (var stagingName in item.StagingRequirements)
                    {
                        var stagingNameKey = GetStagingNameKey(stagingName);

                        var isStaged = stagingInfoDictionary.TryGetValue(item.TicketId, out var taskStagingDict) &&
                                       taskStagingDict.TryGetValue((item.TaskName, stagingNameKey), out var staged) && staged;

                        var stagingComponent = new StagingComponent
                        {
                            Name = stagingName,
                            IsStaged = isStaged
                        };

                        if (ticketAttributesDictionary.TryGetValue(item.TicketId, out var attributeDict))
                        {
                            var stagingComponentValue = GetTicketAttributeValues(StagingRequirementReportConstant.StagingRequirementAttributes, attributeDict, stagingName);

                            stagingComponent.TicketTaskStagingHoverData = GetTicketAttributeValues(StagingRequirementReportConstant.StagingRequirementInfoAttributes, attributeDict, stagingName);
                            stagingComponent.Value = string.Join(",", stagingComponentValue.Select(x => x.Value).Where(v => !string.IsNullOrEmpty(v)));
                        }

                        stagingComponents.Add(stagingComponent);
                    }
                }

                var ticketAttributesList = ticketAttributesDictionary.ContainsKey(item.TicketId)
                                            ? ticketAttributesDictionary[item.TicketId]
                                                .Where(attr => configurableViewTicketAttributes.Contains(attr.Key))
                                                .Select(attr => new TicketAttributeValue
                                                {
                                                    Name = attr.Key,
                                                    Value = attr.Value
                                                }).ToList()
                                            : new List<TicketAttributeValue>();

                result.Add(new ScheduledTasksStagingData
                {
                    TicketNumber = item.TicketNumber,
                    TicketId = item.TicketId,
                    CustomerName = item.CustomerName,
                    GeneralDescription = item.GeneralDescription,
                    TicketPoints = item.TicketPoints,
                    ShipByDate = item.ShipByDate,
                    OrderDate = item.OrderDate,
                    SourceCustomerId = item.SourceCustomerId,
                    CustomerPO = item.CustomerPO,
                    TicketPriority = item.TicketPriority,
                    FinishType = item.FinishType,
                    IsBackSidePrinted = item.IsBackSidePrinted,
                    IsSlitOnRewind = item.IsSlitOnRewind,
                    UseTurretRewinder = item.UseTurretRewinder,
                    EstTotalRevenue = item.EstTotalRevenue,
                    TicketType = item.TicketType,
                    PriceMode = item.PriceMode,
                    FinalUnwind = item.FinalUnwind,
                    TicketStatus = item.TicketStatus,
                    BackStageColorStrategy = item.BackStageColorStrategy,
                    Pinfeed = item.Pinfeed,
                    IsPrintReversed = item.IsPrintReversed,
                    TicketNotes = item.TicketNotes,
                    EndUserNum = item.EndUserNum,
                    EndUserName = item.EndUserName,
                    CreatedOn = item.CreatedOn,
                    ModifiedOn = item.ModifiedOn,
                    Tab = item.Tab,
                    SizeAround = item.SizeAround,
                    ShrinkSleeveLayFlat = item.ShrinkSleeveLayFlat,
                    Shape = item.Shape,
                    ArtWorkComplete = item.ArtWorkComplete,
                    ProofComplete = item.ProofComplete,
                    PlateComplete = item.PlateComplete,
                    ToolsReceived = item.ToolsReceived,
                    InkReceived = item.InkReceived,
                    StockReceived = item.StockReceived,
                    StockTicketType = item.StockTicketType,
                    ITSName = item.ITSName,
                    OTSName = item.OTSName,
                    ConsecutiveNumber = item.ConsecutiveNumber,
                    Quantity = item.Quantity,
                    ActualQuantity = item.ActualQuantity,
                    SizeAcross = item.SizeAcross,
                    ColumnSpace = item.ColumnSpace,
                    RowSpace = item.RowSpace,
                    NumAcross = item.NumAcross,
                    NumAroundPlate = item.NumAroundPlate,
                    LabelRepeat = item.LabelRepeat,
                    FinishedNumAcross = item.FinishedNumAcross,
                    FinishedNumLabels = item.FinishedNumLabels,
                    Coresize = item.Coresize,
                    OutsideDiameter = item.OutsideDiameter,
                    EstimatedLength = item.EstimatedLength,
                    OverRunLength = item.OverRunLength,
                    NoOfPlateChanges = item.NoOfPlateChanges,
                    ShippedOnDate = item.ShippedOnDate,
                    ShipVia = item.ShipVia,
                    DueOnsiteDate = item.DueOnsiteDate,
                    ShippingStatus = item.ShippingStatus,
                    ShippingAddress = item.ShippingAddress,
                    Shippingcity = item.Shippingcity,
                    ColumnPerf = item.ColumnPerf,
                    RowPerf = item.RowPerf,
                    ITSAssocNum = item.ITSAssocNum,
                    OTSAssocNum = item.OTSAssocNum,
                    ShippingInstruc = item.ShippingInstruc,
                    DateDone = item.DateDone,
                    ShipAttnEmailAddress = item.ShipAttnEmailAddress,
                    ShipLocation = item.ShipLocation,
                    ShipZip = item.ShipZip,
                    BillAddr1 = item.BillAddr1,
                    BillAddr2 = item.BillAddr2,
                    BillCity = item.BillCity,
                    BillZip = item.BillZip,
                    BillCountry = item.BillCountry,
                    IsStockAllocated = item.IsStockAllocated,
                    EndUserPO = item.EndUserPO,
                    Tool1Descr = item.Tool1Descr,
                    Tool2Descr = item.Tool2Descr,
                    Tool3Descr = item.Tool3Descr,
                    Tool4Descr = item.Tool4Descr,
                    Tool5Descr = item.Tool5Descr,
                    ActFootage = item.ActFootage,
                    EstPackHrs = item.EstPackHrs,
                    ActPackHrs = item.ActPackHrs,
                    InkStatus = item.InkStatus,
                    BillState = item.BillState,
                    CustContact = item.CustContact,
                    CoreType = item.CoreType,
                    RollUnit = item.RollUnit,
                    RollLength = item.RollLength,
                    FinishNotes = item.FinishNotes,
                    ShipCounty = item.ShipCounty,
                    StockNotes = item.StockNotes,
                    CreditHoldOverride = item.CreditHoldOverride,
                    ShrinkSleeveOverLap = item.ShrinkSleeveOverLap,
                    ShrinkSleeveCutHeight = item.ShrinkSleeveCutHeight,
                    StockDesc1 = item.StockDesc1,
                    StockDesc2 = item.StockDesc2,
                    StockDesc3 = item.StockDesc3,

                    TaskName = item.TaskName,
                    EquipmentName = item.EquipmentName,
                    StartsAt = item.StartsAt,
                    EndsAt = item.EndsAt,
                    ChangeoverMinutes = item.ChangeoverMinutes,
                    TaskMinutes = item.TaskMinutes,
                    TaskStatus = item.TaskStatus,
                    WorkcenterName = item.WorkcenterName,
                    TaskEstimatedMeters = item.TaskEstimatedMeters,
                    SchedulingNotes = item.SchedulingNotes,

                    ScheduleId = item.ScheduleId,
                    IsPinned = item.IsPinned,
                    PinType = item.PinType,
                    LockStatus = item.LockStatus,
                    LockType = item.LockType,
                    IsOnPress = item.IsOnPress,
                    Highlight = item.Highlight,
                    ManuallyScheduled = item.ManuallyScheduled,
                    FeasibilityOverride = item.FeasibilityOverride,
                    IsRollingLock = item.IsRollingLock,
                    MasterRollNumber = item.MasterRollNumber,
                    IsMasterRollGroup = item.IsMasterRollGroup,
                    CanBeUnscheduled = item.CanBeUnscheduled,
                    IsTicketEdited = item.TaskList.Any(task => task.IsEstMinsEdited || task.IsStatusEdited),
                    TaskList = item.TaskList.Select(m => new TaskInformation()
                    {
                        TaskName = m.TaskName,
                        StartsAt = m.StartsAt,
                        EndsAt = m.EndsAt,
                        IsOnPress = m.IsOnPress,
                        Status = m.Status,
                        IsEstMinsEdited = m.IsEstMinsEdited,
                        IsStatusEdited = m.IsStatusEdited,

                    }).ToList(),
                    StagingComponents = stagingComponents,
                    IsStagingCompleted = stagingComponents.All(sc => sc.IsStaged),
                    IsStagingUrgent = (item.StartsAt - tenantLocalDateTime).TotalHours <= 4 && !stagingComponents.All(sc => sc.IsStaged),
                    ForcedGroup = string.IsNullOrEmpty(item.ForcedGroup) ? string.Empty : item.ForcedGroup,
                    EquipmentId = item.EquipmentId,
                    WorkcenterId = item.WorkcenterId,
                    IsMasterRoll = item.IsMasterRoll,
                    TicketAttribute = ticketAttributesList,
                    RecordCreatedOn = item.RecordCreatedOn,
                    TicketCategory = item.TicketCategory,
                    IsTicketGeneralNotePresent = item.IsTicketGeneralNotePresent,
                    StockStatus = item.StockStatus,
                    WorkcenterMaterialTicketCategory = item.WorkcenterMaterialTicketCategory,
                    IsCompletingOnTime = item.IsCompletingOnTime,
                    IsFirstDay = item.IsFirstDay,
                    ValueStreams = (item.ValueStreams != null && item.ValueStreams.Count > 0) ? item.ValueStreams : new List<string>(),
                    WIPValue = item.WIPValue,
                    HasPreviousTaskPartiallyRan = item.HasPreviousTaskPartiallyRan
                });
            }

            return result;
        }

        private static List<TicketAttributeValue> GetTicketAttributeValues(Dictionary<string, List<string>> ticketAttributesDictionary, Dictionary<string, string> attributeDict, string stagingName)
        {
            if (ticketAttributesDictionary.TryGetValue(stagingName, out var requiredAttributes))
            {
                return requiredAttributes.Select(attribute => new TicketAttributeValue
                {
                    Name = attribute,
                    Value = attributeDict.TryGetValue(attribute, out var value) ? value : null
                }).ToList();
            }

            return new List<TicketAttributeValue>();
        }

        private static string GetStagingNameKey(string stagingName)
        {
            return string.Concat("Is", stagingName.Replace(" ", ""), "Staged");
        }

        private static List<ScheduledTasksStagingData> OrderStagingDataByStagingComponent(List<ScheduledTasksStagingData> stagingData, string sortBy, StagingRequirementReportFilter filter)
        {
            var isAscending = sortBy.Substring(0, 1) == "+";

            return isAscending ? stagingData.OrderBy(x => string.IsNullOrEmpty(x.StagingComponents.FirstOrDefault(x => x.Name.ToUpper() == sortBy.Substring(1).ToUpper())?.Value))
                                                                          .ThenBy(x => x.StagingComponents.FirstOrDefault(x => x.Name.ToUpper() == sortBy.Substring(1).ToUpper())?.Value).ToList()
                                         : stagingData.OrderBy(x => string.IsNullOrEmpty(x.StagingComponents.FirstOrDefault(x => x.Name.ToUpper() == sortBy.Substring(1).ToUpper())?.Value))
                                                                          .ThenByDescending(x => x.StagingComponents.FirstOrDefault(x => x.Name.ToUpper() == sortBy.Substring(1).ToUpper())?.Value).ToList();


        }

    }
}
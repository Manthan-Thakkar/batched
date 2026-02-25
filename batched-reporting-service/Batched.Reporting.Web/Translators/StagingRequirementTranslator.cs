using Batched.Reporting.Contracts.Models;
using Batched.Reporting.Web.Models.StagingRequirement;
using ContractModels = Batched.Reporting.Contracts.Models.StagingRequirement;

namespace Batched.Reporting.Web.Translators
{
    /// <summary>
    /// Trasnslator for Staging Requirement objects.
    /// </summary>
    public static class StagingRequirementTranslator
    {
        /// <summary>
        /// Trasnslator for Staging requirement object.
        /// </summary>
        public static StagingRequirementComponents TranslateStagingRequirementComponent(this List<ContractModels.StagingRequirements> stagingRequirements)
        {
            if (stagingRequirements == null)
                return new StagingRequirementComponents
                {
                    Status = new Status
                    {
                        Code = "400",
                        Error = true,
                        Message = "Invalid request",
                        Type = "failure"
                    }
                };

            return new StagingRequirementComponents
            {
                Status = new(),
                StagingRequirements = stagingRequirements.TranslateStagingRequirements()
            };
        }

        private static List<StagingRequirements> TranslateStagingRequirements(this List<ContractModels.StagingRequirements> stagingRequirements)
        {
            var response = new List<StagingRequirements>();

            foreach (var item in stagingRequirements)
            {
                response.Add(new StagingRequirements
                {
                    StagingRequirementId = item.StagingRequirementId,
                    StagingRequirementName = item.StagingRequirementName
                });
            }

            return response;
        }


        /// <summary>
        /// Trasnslator for Filter object.
        /// </summary>
        public static ContractModels.StagingRequirementFilterDataPayload Translate(this StagingRequirementFilterDataPayload payload)
        {
            if (payload == null)
                return null;

            return new ContractModels.StagingRequirementFilterDataPayload
            {
                UserAssignedFacilities = payload.UserAssignedFacilities,
                StartDate = payload.StartDate,
                EndDate = payload.EndDate
            };
        }

        /// <summary>
        /// Trasnslator for Filter object of KPI data and Report data.
        /// </summary>
        public static ContractModels.StagingRequirementFilter Translate(this StagingRequirementFilter filter)
        {
            if (filter == null)
                return null;

            return new ContractModels.StagingRequirementFilter
            {
                Facilities = filter.Facilities,
                ValueStreams = filter.ValueStreams,
                Workcenters = filter.Workcenters,
                Equipments = filter.Equipments,
                Tickets = filter.Tickets,
                Components = filter.Components,
                StartDate = filter.StartDate,
                EndDate = filter.EndDate
            };
        }

        /// <summary>
        /// Trasnslator for Filter object of Staging Requirement Report data.
        /// </summary>
        public static ContractModels.StagingRequirementReportFilter Translate(this StagingRequirementReportFilter filter)
        {
            if (filter == null)
                return null;

            return new ContractModels.StagingRequirementReportFilter
            {
                Facilities = filter.Facilities,
                ValueStreams = filter.ValueStreams,
                Workcenters = filter.Workcenters,
                Equipments = filter.Equipments,
                Tickets = filter.Tickets,
                Components = filter.Components,
                StartDate = filter.StartDate,
                EndDate = filter.EndDate,
                PageNumber = filter.PageNumber,
                PageSize = filter.PageSize,
                ReportName = filter.ReportName,
                ViewId = filter.ViewId,
                SortBy = filter.SortBy,
                TenantId = filter.TenantId
            };
        }

        public static List<ContractModels.TicketTaskStagingPayload> Translate(this List<TicketTaskStagingPayload> ticketTaskMarkAsStagingData)
        {
            return ticketTaskMarkAsStagingData.Select(data => new ContractModels.TicketTaskStagingPayload
            {
                TicketId = data.TicketId,
                TaskName = data.TaskName,
                StagingComponents = data.StagingComponents.Select(sc => new ContractModels.StagingComponent
                {
                    Name = sc.Name,
                    IsStaged = sc.IsStaged
                }).ToList()
            }).ToList();
        }

        /// <summary>
        /// Trasnslator for response object of KPI data.
        /// </summary>
        public static StagingRequirementKPIData Translate(this ContractModels.StagingRequirementKPIData kpiData)
        {
            if (kpiData == null)
                return null;

            return new StagingRequirementKPIData
            {
                TotalTicketTasks = kpiData.TotalTicketTasks,
                UrgentTicketTasks = kpiData.UrgentTicketTasks,
                UnstagedArtProofs = kpiData.UnstagedArtProofs,
                UnstagedPlates = kpiData.UnstagedPlates,
                UnstagedInks = kpiData.UnstagedInks,
                UnstagedCylinders = kpiData.UnstagedCylinders,
                UnstagedTools = kpiData.UnstagedTools,
                UnstagedSubstrates = kpiData.UnstagedSubstrates,
                UnstagedCores = kpiData.UnstagedCores,
                NextFacilityScheduledTime = kpiData.NextFacilityScheduledTime.Translate()
            };
        }

        public static StagingRequirementData Translate(this ContractModels.StagingRequirementData stagingData)
        {
            if (stagingData == null)
                return null;

            return new StagingRequirementData
            {
                ScheduledTasksStagingData = stagingData.ScheduledTasksStagingData.Translate(),
                TotalCount = stagingData.TotalCount
            };
        }

        private static List<ScheduledTasksStagingData> Translate(this List<ContractModels.ScheduledTasksStagingData> scheduledTasksStagingData)
        {
            var result = new List<ScheduledTasksStagingData>();

            foreach (var data in scheduledTasksStagingData)
            {
                result.Add(new ScheduledTasksStagingData
                {
                    TicketId = data.TicketId,
                    TicketNumber = data.TicketNumber,
                    TaskName = data.TaskName,
                    TicketCategory = data.TicketCategory,
                    WorkcenterId = data.WorkcenterId,
                    WorkcenterName = data.WorkcenterName,
                    EquipmentId = data.EquipmentId,
                    DateDone = data.DateDone,
                    DueOnsiteDate = data.DueOnsiteDate,
                    TaskEstimatedMeters = data.TaskEstimatedMeters,
                    TaskStatus = data.TaskStatus,
                    TaskMinutes = data.TaskMinutes,
                    TicketNotes = data.TicketNotes,
                    TicketStatus = data.TicketStatus,
                    TicketType = data.TicketType,
                    TicketPriority = data.TicketPriority,
                    Tab = data.Tab,
                    GeneralDescription = data.GeneralDescription,
                    IsFirstDay = data.IsFirstDay,
                    OrderDate = data.OrderDate,
                    Quantity = data.Quantity,
                    OutsideDiameter = data.OutsideDiameter,
                    ShipByDate = data.ShipByDate,
                    ShippedOnDate = data.ShippedOnDate,
                    StockDesc1 = data.StockDesc1,
                    StockDesc2 = data.StockDesc2,
                    StockDesc3 = data.StockDesc3,
                    Tool1Descr = data.Tool1Descr,
                    Tool2Descr = data.Tool2Descr,
                    Tool3Descr = data.Tool3Descr,
                    Tool4Descr = data.Tool4Descr,
                    Tool5Descr = data.Tool5Descr,
                    ActFootage = data.ActFootage,
                    ActPackHrs = data.ActPackHrs,
                    ActualQuantity = data.ActualQuantity,
                    ArtWorkComplete = data.ArtWorkComplete,
                    BackStageColorStrategy = data.BackStageColorStrategy,
                    BillAddr1 = data.BillAddr1,
                    BillAddr2 = data.BillAddr2,
                    BillCity = data.BillCity,
                    BillCountry = data.BillCountry,
                    BillState = data.BillState,
                    BillZip = data.BillZip,
                    CanBeUnscheduled = data.CanBeUnscheduled,
                    ChangeoverMinutes = data.ChangeoverMinutes,
                    ColumnPerf = data.ColumnPerf,
                    ColumnSpace = data.ColumnSpace,
                    ConsecutiveNumber = data.ConsecutiveNumber,
                    Coresize = data.Coresize,
                    CoreType = data.CoreType,
                    CreatedOn = data.CreatedOn,
                    CreditHoldOverride = data.CreditHoldOverride,
                    CustContact = data.CustContact,
                    CustomerName = data.CustomerName,
                    CustomerPO = data.CustomerPO,
                    EndsAt = data.EndsAt,
                    EndUserName = data.EndUserName,
                    EndUserNum = data.EndUserNum,
                    EndUserPO = data.EndUserPO,
                    EquipmentName = data.EquipmentName,
                    EstimatedLength = data.EstimatedLength,
                    EstPackHrs = data.EstimatedLength,
                    EstTotalRevenue = data.EstTotalRevenue,
                    FeasibilityOverride = data.FeasibilityOverride,
                    FinalUnwind = data.FinalUnwind,
                    FinishedNumAcross = data.FinishedNumAcross,
                    FinishedNumLabels = data.FinishedNumLabels,
                    FinishNotes = data.FinishNotes,
                    FinishType = data.FinishType,
                    ForcedGroup = data.ForcedGroup,
                    HasPreviousTaskPartiallyRan = data.HasPreviousTaskPartiallyRan,
                    Highlight = data.Highlight,
                    InkReceived = data.InkReceived,
                    InkStatus = data.InkStatus,
                    IsBackSidePrinted = data.IsBackSidePrinted,
                    IsCompletingOnTime = data.IsCompletingOnTime,
                    IsMasterRoll = data.IsMasterRoll,
                    IsMasterRollGroup = data.IsMasterRollGroup,
                    IsOnPress = data.IsOnPress,
                    IsPinned = data.IsPinned,
                    IsPrintReversed = data.IsPrintReversed,
                    IsRollingLock = data.IsRollingLock,
                    IsSlitOnRewind = data.IsSlitOnRewind,
                    IsStockAllocated = data.IsStockAllocated,
                    IsTicketEdited = data.IsTicketEdited,
                    IsTicketGeneralNotePresent = data.IsTicketGeneralNotePresent,
                    ITSAssocNum = data.ITSAssocNum,
                    ITSName = data.ITSName,
                    LabelRepeat = data.LabelRepeat,
                    LockStatus = data.LockStatus,
                    LockType = data.LockType,
                    ManuallyScheduled = data.ManuallyScheduled,
                    MasterRollNumber = data.MasterRollNumber,
                    ModifiedOn = data.ModifiedOn,
                    NoOfPlateChanges = data.NoOfPlateChanges,
                    NumAcross = data.NumAcross,
                    NumAroundPlate = data.NumAroundPlate,
                    OTSAssocNum = data.OTSAssocNum,
                    OTSName = data.OTSName,
                    OverRunLength = data.OverRunLength,
                    Pinfeed = data.Pinfeed,
                    PinType = data.PinType,
                    PlateComplete = data.PlateComplete,
                    PriceMode = data.PriceMode,
                    ProofComplete = data.ProofComplete,
                    RollLength = data.RollLength,
                    RollUnit = data.RollUnit,
                    RowPerf = data.RowPerf,
                    RowSpace = data.RowSpace,
                    ScheduleId = data.ScheduleId,
                    SchedulingNotes = data.SchedulingNotes,
                    Shape = data.Shape,
                    ShipAttnEmailAddress = data.ShipAttnEmailAddress,
                    ShipCounty = data.ShipCounty,
                    ShipLocation = data.ShipLocation,
                    ShippingAddress = data.ShippingAddress,
                    Shippingcity = data.Shippingcity,
                    ShippingInstruc = data.ShippingInstruc,
                    ShippingStatus = data.ShippingStatus,
                    ShipVia = data.ShipVia,
                    ShipZip = data.ShipZip,
                    ShrinkSleeveCutHeight = data.ShrinkSleeveCutHeight,
                    ShrinkSleeveLayFlat = data.ShrinkSleeveLayFlat,
                    ShrinkSleeveOverLap = data.ShrinkSleeveOverLap,
                    SizeAcross = data.SizeAcross,
                    SizeAround = data.SizeAround,
                    SourceCustomerId = data.SourceCustomerId,
                    StagingComponents = data.StagingComponents.Select(x => new StagingComponent()
                    {
                        Name = x.Name,
                        IsStaged = x.IsStaged,
                        Value = x.Value,
                        TicketTaskStagingHoverData = x.TicketTaskStagingHoverData.Select(ta => new TicketAttributeValue()
                        {
                            Name = ta.Name,
                            Value = ta.Value,
                        }).ToList(),
                    }).ToList(),
                    StartsAt = data.StartsAt,
                    StockNotes = data.StockNotes,
                    StockReceived = data.StockReceived,
                    StockStatus = data.StockStatus,
                    StockTicketType = data.StockTicketType,
                    TaskList = data.TaskList.Select(m => new TaskInformation()
                    {
                        TaskName = m.TaskName,
                        StartsAt = m.StartsAt,
                        EndsAt = m.EndsAt,
                        IsOnPress = m.IsOnPress,
                        Status = m.Status,
                        IsEstMinsEdited = m.IsEstMinsEdited,
                        IsStatusEdited = m.IsStatusEdited,

                    }).ToList(),
                    TicketAttribute = data.TicketAttribute.Select(x => new TicketAttributeValue()
                    {
                        Name = x.Name,
                        Value = x.Value,
                    }).ToList(),
                    TicketPoints = data.TicketPoints,
                    ToolsReceived = data.ToolsReceived,
                    UseTurretRewinder = data.UseTurretRewinder,
                    ValueStreams = data.ValueStreams,
                    WorkcenterMaterialTicketCategory = data.WorkcenterMaterialTicketCategory,
                    IsStagingCompleted = data.IsStagingCompleted,
                    IsStagingUrgent = data.IsStagingUrgent,
                    WIPValue = data.WIPValue
                });
            }

            return result;
        }

        private static FacilityScheduledTime Translate(this ContractModels.FacilityScheduledTime scheduledTime)
        {
            if (scheduledTime == null)
                return null;

            return new FacilityScheduledTime
            {
                NextScheduledTime = scheduledTime.NextScheduledTime,
                ScheduledFacilities = scheduledTime.ScheduledFacilities.Translate()
            };
        }

        private static List<ScheduledFacility> Translate(this List<ContractModels.ScheduledFacility> scheduledFacility)
        {
            if (scheduledFacility == null)
                return null;

            var response = new List<ScheduledFacility>();

            foreach (var facility in scheduledFacility)
            {
                if (!response.Any(x => x.FacilityId == facility.FacilityId))
                {
                    ScheduledFacility scheduledFacilityObj = new()
                    {
                        FacilityId = facility.FacilityId,
                        FacilityName = facility.FacilityName,
                        TimeZone = facility.TimeZone,
                        FacilityTimeStamp = facility.FacilityTimeStamp,
                        UTCTimeStamp = facility.UTCTimeStamp
                    };

                    var valueStreams = scheduledFacility
                                            .FindAll(x => x.FacilityId == facility.FacilityId && !string.IsNullOrEmpty(x.ValueStreamId))
                                            .Select(schedules => new Models.DataDTO
                                            {
                                                Id = schedules.ValueStreamId,
                                                Name = schedules.ValueStreamName
                                            })?
                                            .ToList();

                    if (valueStreams != null)
                    {
                        scheduledFacilityObj.ValueStreams = new();
                        scheduledFacilityObj.ValueStreams.AddRange(valueStreams);
                    }

                    response.Add(scheduledFacilityObj);
                }
            }

            return response;
        }


        /// <summary>
        /// Trasnslator for Filter data object.
        /// </summary>
        public static List<StagingReportFilterData> Translate(this List<ContractModels.StagingReportFilterData> filterData)
        {
            if (filterData == null)
                return null;

            var response = new List<StagingReportFilterData>();

            foreach (var item in filterData)
            {
                response.Add(item.Translate());
            }

            return response;
        }

        private static StagingReportFilterData Translate(this ContractModels.StagingReportFilterData filterData)
        {
            if (filterData == null)
                return null;

            return new StagingReportFilterData
            {
                EquipmentId = filterData.EquipmentId,
                EquipmentName = filterData.EquipmentName,
                FacilityId = filterData.FacilityId,
                FacilityName = filterData.FacilityName,
                WorkcenterId = filterData.WorkcenterId,
                WorkcenterName = filterData.WorkcenterName,
                Tickets = filterData.Tickets,
                ValueStreams = filterData.ValueStreams.Translate(),
                StagingRequirements = filterData.StagingRequirements.Translate()
            };
        }

        /// <summary>
        /// Trasnslator for payload of fetching staging data.
        /// </summary>
        public static ContractModels.TicketTaskStagingInfoPayload Translate(this TicketTaskStagingInfoPayload stagingPayload)
        {
            if (stagingPayload == null)
                return null;

            return new ContractModels.TicketTaskStagingInfoPayload
            {
                TicketId = stagingPayload.TicketId,
                TicketNumber = stagingPayload.TicketNumber,
                TaskName = stagingPayload.TaskName
            };
        }

        /// <summary>
        /// Trasnslator for response of fetching staging data.
        /// </summary>
        public static TicketStagingInfo Translate(this ContractModels.TicketStagingInfo ticketStagingInfo)
        {
            if (ticketStagingInfo == null)
                return null;

            return new TicketStagingInfo
            {
                TicketId = ticketStagingInfo.TicketId,
                TicketNumber = ticketStagingInfo.TicketNumber,
                TaskName = ticketStagingInfo.TaskName,
                StagingInfo = ticketStagingInfo.StagingInfo.Select(x => new StagingInfo
                                {
                                    StagingRequirement = x.StagingRequirement,
                                    IsStaged = x.IsStaged,
                                    IsRequirementApplicable = x.IsRequirementApplicable,
                                    StagingData = x.StagingData.Select(y => new TicketAttributeValue
                                                    {
                                                        Name = y.Name,
                                                        Value = y.Value
                                                    }).ToList()
                                }).ToList()
            };
        }
    }
}
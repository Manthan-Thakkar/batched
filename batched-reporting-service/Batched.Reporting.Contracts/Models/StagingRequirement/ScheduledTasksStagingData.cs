using Batched.Common;
using System.Collections;

namespace Batched.Reporting.Contracts.Models.StagingRequirement
{
    public class ScheduledTasksStagingData
    {
        public string TicketNumber { get; set; }
        public string TicketId { get; set; }
        public string CustomerName { get; set; }
        public string GeneralDescription { get; set; }
        public string TicketPoints { get; set; }
        public DateTime ShipByDate { get; set; }
        public DateTime OrderDate { get; set; }
        public string SourceCustomerId { get; set; }
        public string CustomerPO { get; set; }
        public string TicketPriority { get; set; }
        public string FinishType { get; set; }
        public bool IsBackSidePrinted { get; set; }
        public bool IsSlitOnRewind { get; set; }
        public bool UseTurretRewinder { get; set; }
        public string EstTotalRevenue { get; set; }
        public int TicketType { get; set; }
        public string PriceMode { get; set; }
        public string FinalUnwind { get; set; }
        public string TicketStatus { get; set; }
        public string BackStageColorStrategy { get; set; }
        public bool Pinfeed { get; set; }
        public bool IsPrintReversed { get; set; }
        public string TicketNotes { get; set; }
        public string EndUserNum { get; set; }
        public string EndUserName { get; set; }
        public DateTime CreatedOn { get; set; }
        public DateTime ModifiedOn { get; set; }
        public string Tab { get; set; }
        public string SizeAround { get; set; }
        public string ShrinkSleeveLayFlat { get; set; }
        public string Shape { get; set; }
        public bool ArtWorkComplete { get; set; }
        public bool ProofComplete { get; set; }
        public bool PlateComplete { get; set; }
        public bool ToolsReceived { get; set; }
        public bool InkReceived { get; set; }
        public bool StockReceived { get; set; }
        public int StockTicketType { get; set; }
        public string ITSName { get; set; }
        public string OTSName { get; set; }
        public bool ConsecutiveNumber { get; set; }
        public int Quantity { get; set; }
        public int ActualQuantity { get; set; }
        public decimal SizeAcross { get; set; }
        public decimal ColumnSpace { get; set; }
        public decimal RowSpace { get; set; }
        public int NumAcross { get; set; }
        public int NumAroundPlate { get; set; }
        public decimal LabelRepeat { get; set; }
        public decimal FinishedNumAcross { get; set; }
        public int FinishedNumLabels { get; set; }
        public decimal Coresize { get; set; }
        public decimal OutsideDiameter { get; set; }
        public int EstimatedLength { get; set; }
        public decimal OverRunLength { get; set; }
        public int NoOfPlateChanges { get; set; }
        public DateTime? ShippedOnDate { get; set; }
        public string ShipVia { get; set; }
        public DateTime? DueOnsiteDate { get; set; }
        public string ShippingStatus { get; set; }
        public string ShippingAddress { get; set; }
        public string Shippingcity { get; set; }

        public decimal ColumnPerf { get; set; }
        public decimal RowPerf { get; set; }
        public string ITSAssocNum { get; set; }
        public string OTSAssocNum { get; set; }
        public string ShippingInstruc { get; set; }
        public DateTime? DateDone { get; set; }
        public string ShipAttnEmailAddress { get; set; }
        public string ShipLocation { get; set; }
        public string ShipZip { get; set; }
        public string BillAddr1 { get; set; }
        public string BillAddr2 { get; set; }
        public string BillCity { get; set; }
        public string BillZip { get; set; }
        public string BillCountry { get; set; }
        public bool IsStockAllocated { get; set; }
        public string EndUserPO { get; set; }
        public string Tool1Descr { get; set; }
        public string Tool2Descr { get; set; }
        public string Tool3Descr { get; set; }
        public string Tool4Descr { get; set; }
        public string Tool5Descr { get; set; }
        public int ActFootage { get; set; }
        public decimal EstPackHrs { get; set; }
        public decimal ActPackHrs { get; set; }
        public string InkStatus { get; set; }
        public string BillState { get; set; }
        public string FinishNotes { get; set; }
        public string ShipCounty { get; set; }
        public string StockNotes { get; set; }
        public bool? CreditHoldOverride { get; set; }
        public bool? ShrinkSleeveOverLap { get; set; }
        public bool? ShrinkSleeveCutHeight { get; set; }
        public string StockDesc1 { get; set; }
        public string StockDesc2 { get; set; }
        public string StockDesc3 { get; set; }
        public string CustContact { get; set; }
        public string CoreType { get; set; }
        public string RollUnit { get; set; }
        public int RollLength { get; set; }


        public string TaskName { get; set; }
        public string EquipmentName { get; set; }
        public DateTime StartsAt { get; set; }
        public DateTime EndsAt { get; set; }
        public double? ChangeoverMinutes { get; set; }
        public double? TaskMinutes { get; set; }
        public string TaskStatus { get; set; }
        public string WorkcenterName { get; set; }
        public string TaskEstimatedMeters { get; set; }
        public string SchedulingNotes { get; set; }

        public string ScheduleId { get; set; }
        public bool? IsPinned { get; set; }
        public string PinType { get; set; }
        public string LockStatus { get; set; }
        public string LockType { get; set; }
        public bool IsOnPress { get; set; }
        public bool Highlight { get; set; }
        public bool ManuallyScheduled { get; set; }
        public bool FeasibilityOverride { get; set; }
        public bool IsRollingLock { get; set; }
        public string MasterRollNumber { get; set; }
        public bool IsMasterRollGroup { get; set; }
        public string EquipmentId { get; set; }
        public string WorkcenterId { get; set; }
        public bool IsMasterRoll { get; set; }
        public bool CanBeUnscheduled { get; set; }
        public string ForcedGroup { get; set; }
        public int TicketCategory { get; set; }
        public DateTime RecordCreatedOn { get; set; }
        public bool IsTicketEdited { get; set; }
        public bool IsTicketGeneralNotePresent { get; set; }
        public string StockStatus { get; set; }
        public int WorkcenterMaterialTicketCategory { get; set; }
        public int? IsCompletingOnTime { get; set; }
        public bool HasPreviousTaskPartiallyRan { get; set; }
        public bool IsFirstDay { get; set; }
        public bool IsStagingCompleted { get; set; }
        public bool IsStagingUrgent { get; set; }

        public List<TaskInformation> TaskList { get; set; }
        public List<TicketAttributeValue> TicketAttribute { get; set; }
        public List<StagingComponent> StagingComponents { get; set; }
        public List<string> ValueStreams { get; set; } = new List<string>();
        public string WIPValue { get; set; }
    }

    public class TaskInformation
    {
        public string TaskName { get; set; }
        public DateTime StartsAt { get; set; }
        public DateTime EndsAt { get; set; }
        public string Status { get; set; }
        public bool IsOnPress { get; set; }
        public bool IsEstMinsEdited { get; set; }
        public bool IsStatusEdited { get; set; }
    }

    public class TicketAttributeValue
    {
        public string Name { get; set; }
        public string Value { get; set; }
    }

    public class StagingComponent
    {
        public string Name { get; set; }
        public bool IsStaged { get; set; }
        public string Value { get; set; }
        public List<TicketAttributeValue> TicketTaskStagingHoverData { get; set; } = new List<TicketAttributeValue>();
    }



    public class ScheduledTasksStagingDataPropertyMapper : IEnumerable<KeyValuePair<string, object>>
    {
        private readonly ScheduledTasksStagingData _stagingData;
        public ScheduledTasksStagingDataPropertyMapper(ScheduledTasksStagingData stagingData)
        {
            _stagingData = stagingData;
        }

        public IEnumerator<KeyValuePair<string, object>> GetEnumerator()
        {
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.ActFootage), _stagingData.ActFootage.FormatNumber());
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.ActPackHrs), _stagingData.ActPackHrs.FormatNumber());
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.ActualQuantity), _stagingData.ActualQuantity.FormatNumber());
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.ArtWorkComplete), _stagingData.ArtWorkComplete);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.BackStageColorStrategy), _stagingData.BackStageColorStrategy);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.BillAddr1), _stagingData.BillAddr1);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.BillAddr2), _stagingData.BillAddr2);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.BillCity), _stagingData.BillCity);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.BillCountry), _stagingData.BillCountry);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.BillState), _stagingData.BillState);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.BillZip), _stagingData.BillZip);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.CanBeUnscheduled), _stagingData.CanBeUnscheduled);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.ChangeoverMinutes), _stagingData.ChangeoverMinutes.FormatNumber());
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.ColumnPerf), _stagingData.ColumnPerf.FormatNumber());
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.ColumnSpace), _stagingData.ColumnSpace.FormatNumber());
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.ConsecutiveNumber), _stagingData.ConsecutiveNumber);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.CoreType), _stagingData.CoreType);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.Coresize), _stagingData.Coresize.FormatNumber());
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.CreatedOn), _stagingData.CreatedOn.FormatDateTime());
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.CreditHoldOverride), _stagingData.CreditHoldOverride);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.CustContact), _stagingData.CustContact);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.CustomerName), _stagingData.CustomerName);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.CustomerPO), _stagingData.CustomerPO);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.DateDone), _stagingData.DateDone.FormatDate());
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.DueOnsiteDate), _stagingData.DueOnsiteDate.FormatDate());
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.EndUserName), _stagingData.EndUserName);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.EndUserNum), _stagingData.EndUserNum);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.EndUserPO), _stagingData.EndUserPO);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.EndsAt), _stagingData.EndsAt.FormatDateTime());
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.EquipmentId), _stagingData.EquipmentId);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.EquipmentName), _stagingData.EquipmentName);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.EstPackHrs), _stagingData.EstPackHrs.FormatNumber());
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.EstTotalRevenue), _stagingData.EstTotalRevenue.FormatNumber());
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.EstimatedLength), _stagingData.EstimatedLength.FormatNumber());
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.FeasibilityOverride), _stagingData.FeasibilityOverride);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.FinalUnwind), _stagingData.FinalUnwind);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.FinishNotes), _stagingData.FinishNotes);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.FinishType), _stagingData.FinishType);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.FinishedNumAcross), _stagingData.FinishedNumAcross.FormatNumber());
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.FinishedNumLabels), _stagingData.FinishedNumLabels.FormatNumber());
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.ForcedGroup), _stagingData.ForcedGroup);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.GeneralDescription), _stagingData.GeneralDescription);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.HasPreviousTaskPartiallyRan), _stagingData.HasPreviousTaskPartiallyRan);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.Highlight), _stagingData.Highlight);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.ITSAssocNum), _stagingData.ITSAssocNum);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.ITSName), _stagingData.ITSName);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.InkReceived), _stagingData.InkReceived);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.InkStatus), _stagingData.InkStatus);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.IsBackSidePrinted), _stagingData.IsBackSidePrinted);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.IsCompletingOnTime), _stagingData.IsCompletingOnTime);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.IsFirstDay), _stagingData.IsFirstDay);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.IsMasterRoll), _stagingData.IsMasterRoll);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.IsMasterRollGroup), _stagingData.IsMasterRollGroup);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.IsOnPress), _stagingData.IsOnPress);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.IsPinned), _stagingData.IsPinned);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.IsPrintReversed), _stagingData.IsPrintReversed);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.IsRollingLock), _stagingData.IsRollingLock);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.IsSlitOnRewind), _stagingData.IsSlitOnRewind);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.IsStagingCompleted), _stagingData.IsStagingCompleted);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.IsStagingUrgent), _stagingData.IsStagingUrgent);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.IsStockAllocated), _stagingData.IsStockAllocated);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.IsTicketEdited), _stagingData.IsTicketEdited);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.IsTicketGeneralNotePresent), _stagingData.IsTicketGeneralNotePresent);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.LabelRepeat), _stagingData.LabelRepeat);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.LockStatus), _stagingData.LockStatus);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.LockType), _stagingData.LockType);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.ManuallyScheduled), _stagingData.ManuallyScheduled);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.MasterRollNumber), _stagingData.MasterRollNumber);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.ModifiedOn), _stagingData.ModifiedOn.FormatDateTime());
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.NoOfPlateChanges), _stagingData.NoOfPlateChanges.FormatNumber());
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.NumAcross), _stagingData.NumAcross.FormatNumber());
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.NumAroundPlate), _stagingData.NumAroundPlate.FormatNumber());
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.OTSAssocNum), _stagingData.OTSAssocNum);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.OTSName), _stagingData.OTSName);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.OrderDate), _stagingData.OrderDate);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.OutsideDiameter), _stagingData.OutsideDiameter.FormatNumber());
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.OverRunLength), _stagingData.OverRunLength.FormatNumber());
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.PinType), _stagingData.PinType);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.Pinfeed), _stagingData.Pinfeed);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.PlateComplete), _stagingData.PlateComplete);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.PriceMode), _stagingData.PriceMode);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.ProofComplete), _stagingData.ProofComplete);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.Quantity), _stagingData.Quantity.FormatNumber());
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.RecordCreatedOn), _stagingData.RecordCreatedOn);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.RollLength), _stagingData.RollLength.FormatNumber());
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.RollUnit), _stagingData.RollUnit);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.RowPerf), _stagingData.RowPerf.FormatNumber());
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.RowSpace), _stagingData.RowSpace.FormatNumber());
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.ScheduleId), _stagingData.ScheduleId);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.SchedulingNotes), _stagingData.SchedulingNotes);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.Shape), _stagingData.Shape);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.ShipAttnEmailAddress), _stagingData.ShipAttnEmailAddress);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.ShipByDate), _stagingData.ShipByDate.FormatDate());
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.ShipCounty), _stagingData.ShipCounty);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.ShipLocation), _stagingData.ShipLocation);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.ShipVia), _stagingData.ShipVia);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.ShipZip), _stagingData.ShipZip);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.ShippedOnDate), _stagingData.ShippedOnDate.FormatDate());
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.ShippingAddress), _stagingData.ShippingAddress);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.ShippingInstruc), _stagingData.ShippingInstruc);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.ShippingStatus), _stagingData.ShippingStatus);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.Shippingcity), _stagingData.Shippingcity);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.ShrinkSleeveCutHeight), _stagingData.ShrinkSleeveCutHeight);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.ShrinkSleeveLayFlat), _stagingData.ShrinkSleeveLayFlat);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.ShrinkSleeveOverLap), _stagingData.ShrinkSleeveOverLap);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.SizeAcross), _stagingData.SizeAcross.FormatNumber());
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.SizeAround), _stagingData.SizeAround.FormatNumber());
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.SourceCustomerId), _stagingData.SourceCustomerId);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.StagingComponents), _stagingData.StagingComponents);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.StartsAt), _stagingData.StartsAt.FormatDateTime());
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.StockDesc1), _stagingData.StockDesc1);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.StockDesc2), _stagingData.StockDesc2);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.StockDesc3), _stagingData.StockDesc3);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.StockNotes), _stagingData.StockNotes);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.StockReceived), _stagingData.StockReceived);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.StockStatus), _stagingData.StockStatus);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.StockTicketType), _stagingData.StockTicketType);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.Tab), _stagingData.Tab);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.TaskEstimatedMeters), _stagingData.TaskEstimatedMeters.FormatNumber());
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.TaskList), _stagingData.TaskList);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.TaskMinutes), _stagingData.TaskMinutes.FormatNumber());
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.TaskName), _stagingData.TaskName);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.TaskStatus), _stagingData.TaskStatus);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.TicketAttribute), _stagingData.TicketAttribute);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.TicketCategory), _stagingData.TicketCategory);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.TicketId), _stagingData.TicketId);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.TicketNotes), _stagingData.TicketNotes);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.TicketNumber), _stagingData.TicketNumber);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.TicketPoints), _stagingData.TicketPoints);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.TicketPriority), _stagingData.TicketPriority);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.TicketStatus), _stagingData.TicketStatus);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.TicketType), _stagingData.TicketType);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.Tool1Descr), _stagingData.Tool1Descr);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.Tool2Descr), _stagingData.Tool2Descr);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.Tool3Descr), _stagingData.Tool3Descr);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.Tool4Descr), _stagingData.Tool4Descr);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.Tool5Descr), _stagingData.Tool5Descr);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.ToolsReceived), _stagingData.ToolsReceived);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.UseTurretRewinder), _stagingData.UseTurretRewinder);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.ValueStreams), _stagingData.ValueStreams);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.WIPValue), _stagingData.WIPValue);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.WorkcenterId), _stagingData.WorkcenterId);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.WorkcenterMaterialTicketCategory), _stagingData.WorkcenterMaterialTicketCategory);
            yield return new KeyValuePair<string, object>(nameof(ScheduledTasksStagingData.WorkcenterName), _stagingData.WorkcenterName);
        }

        IEnumerator IEnumerable.GetEnumerator()
        {
            return GetEnumerator();
        }
    }
}

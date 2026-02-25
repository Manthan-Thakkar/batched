using System.Text.Json.Serialization;

namespace Batched.Reporting.Web.Models.StagingRequirement
{
    public class ScheduledTasksStagingData
    {
        [JsonPropertyName("ticketNumber")]
        public string TicketNumber { get; set; }

        [JsonPropertyName("ticketId")]
        public string TicketId { get; set; }

        [JsonPropertyName("customerName")]
        public string CustomerName { get; set; }

        [JsonPropertyName("generalDescription")]
        public string GeneralDescription { get; set; }

        [JsonPropertyName("ticketPoints")]
        public string TicketPoints { get; set; }

        [JsonPropertyName("shipByDate")]
        public DateTime ShipByDate { get; set; }

        [JsonPropertyName("orderDate")]
        public DateTime OrderDate { get; set; }

        [JsonPropertyName("sourceCustomerId")]
        public string SourceCustomerId { get; set; }

        [JsonPropertyName("customerPO")]
        public string CustomerPO { get; set; }

        [JsonPropertyName("priority")]
        public string TicketPriority { get; set; }

        [JsonPropertyName("finishType")]
        public string FinishType { get; set; }

        [JsonPropertyName("isBackSidePrinted")]
        public bool IsBackSidePrinted { get; set; }

        [JsonPropertyName("isSlitOnRewind")]
        public bool IsSlitOnRewind { get; set; }

        [JsonPropertyName("useTurretRewinder")]
        public bool UseTurretRewinder { get; set; }

        [JsonPropertyName("estTotalRevenue")]
        public string EstTotalRevenue { get; set; }

        [JsonPropertyName("ticketType")]
        public int TicketType { get; set; }

        [JsonPropertyName("priceMode")]
        public string PriceMode { get; set; }

        [JsonPropertyName("finalUnwind")]
        public string FinalUnwind { get; set; }

        [JsonPropertyName("status")]
        public string TicketStatus { get; set; }

        [JsonPropertyName("backStageColorStrategy")]
        public string BackStageColorStrategy { get; set; }

        [JsonPropertyName("pinfeed")]
        public bool Pinfeed { get; set; }

        [JsonPropertyName("isPrintReversed")]
        public bool IsPrintReversed { get; set; }

        [JsonPropertyName("ticketNotes")]
        public string TicketNotes { get; set; }

        [JsonPropertyName("endUserNum")]
        public string EndUserNum { get; set; }

        [JsonPropertyName("endUserName")]
        public string EndUserName { get; set; }

        [JsonPropertyName("createdOn")]
        public DateTime CreatedOn { get; set; }

        [JsonPropertyName("modifiedOn")]
        public DateTime ModifiedOn { get; set; }

        [JsonPropertyName("tab")]
        public string Tab { get; set; }

        [JsonPropertyName("sizeAround")]
        public string SizeAround { get; set; }

        [JsonPropertyName("shrinkSleeveLayFlat")]
        public string ShrinkSleeveLayFlat { get; set; }

        [JsonPropertyName("shape")]
        public string Shape { get; set; }

        [JsonPropertyName("artWorkComplete")]
        public bool ArtWorkComplete { get; set; }

        [JsonPropertyName("proofComplete")]
        public bool ProofComplete { get; set; }

        [JsonPropertyName("plateComplete")]
        public bool PlateComplete { get; set; }

        [JsonPropertyName("toolsReceived")]
        public bool ToolsReceived { get; set; }

        [JsonPropertyName("inkReceived")]
        public bool InkReceived { get; set; }

        [JsonPropertyName("stockReceived")]
        public bool StockReceived { get; set; }

        [JsonPropertyName("stockTicketType")]
        public int StockTicketType { get; set; }

        [JsonPropertyName("itsName")]
        public string ITSName { get; set; }

        [JsonPropertyName("otsName")]
        public string OTSName { get; set; }

        [JsonPropertyName("consecutiveNumber")]
        public bool ConsecutiveNumber { get; set; }

        [JsonPropertyName("quantity")]
        public int Quantity { get; set; }

        [JsonPropertyName("actualQuantity")]
        public int ActualQuantity { get; set; }

        [JsonPropertyName("sizeAcross")]
        public decimal SizeAcross { get; set; }

        [JsonPropertyName("columnSpace")]
        public decimal ColumnSpace { get; set; }

        [JsonPropertyName("rowSpace")]
        public decimal RowSpace { get; set; }

        [JsonPropertyName("numAcross")]
        public int NumAcross { get; set; }

        [JsonPropertyName("numAroundPlate")]
        public int NumAroundPlate { get; set; }

        [JsonPropertyName("labelRepeat")]
        public decimal LabelRepeat { get; set; }

        [JsonPropertyName("finishedNumAcross")]
        public decimal FinishedNumAcross { get; set; }

        [JsonPropertyName("finishedNumLabels")]
        public int FinishedNumLabels { get; set; }

        [JsonPropertyName("coresize")]
        public decimal Coresize { get; set; }

        [JsonPropertyName("outsideDiameter")]
        public decimal OutsideDiameter { get; set; }

        [JsonPropertyName("estimatedLength")]
        public int EstimatedLength { get; set; }

        [JsonPropertyName("overRunLength")]
        public decimal OverRunLength { get; set; }

        [JsonPropertyName("noOfPlateChanges")]
        public int NoOfPlateChanges { get; set; }

        [JsonPropertyName("shippedOnDate")]
        public DateTime? ShippedOnDate { get; set; }

        [JsonPropertyName("shipVia")]
        public string ShipVia { get; set; }

        [JsonPropertyName("dueOnsiteDate")]
        public DateTime? DueOnsiteDate { get; set; }

        [JsonPropertyName("shippingStatus")]
        public string ShippingStatus { get; set; }

        [JsonPropertyName("shippingAddress")]
        public string ShippingAddress { get; set; }

        [JsonPropertyName("Shippingcity")]
        public string Shippingcity { get; set; }


        [JsonPropertyName("columnPerf")]
        public decimal ColumnPerf { get; set; }

        [JsonPropertyName("rowPerf")]
        public decimal RowPerf { get; set; }

        [JsonPropertyName("iTSAssocNum")]
        public string ITSAssocNum { get; set; }

        [JsonPropertyName("oTSAssocNum")]
        public string OTSAssocNum { get; set; }

        [JsonPropertyName("shippingInstruc")]
        public string ShippingInstruc { get; set; }

        [JsonPropertyName("dateDone")]
        public DateTime? DateDone { get; set; }

        [JsonPropertyName("shipAttnEmailAddress")]
        public string ShipAttnEmailAddress { get; set; }

        [JsonPropertyName("shipLocation")]
        public string ShipLocation { get; set; }

        [JsonPropertyName("shipZip")]
        public string ShipZip { get; set; }

        [JsonPropertyName("billAddr1")]
        public string BillAddr1 { get; set; }

        [JsonPropertyName("billAddr2")]
        public string BillAddr2 { get; set; }

        [JsonPropertyName("billCity")]
        public string BillCity { get; set; }

        [JsonPropertyName("billZip")]
        public string BillZip { get; set; }

        [JsonPropertyName("billCountry")]
        public string BillCountry { get; set; }

        [JsonPropertyName("isStockAllocated")]
        public bool IsStockAllocated { get; set; }

        [JsonPropertyName("endUserPO")]
        public string EndUserPO { get; set; }

        [JsonPropertyName("tool1Descr")]
        public string Tool1Descr { get; set; }

        [JsonPropertyName("tool2Descr")]
        public string Tool2Descr { get; set; }

        [JsonPropertyName("tool3Descr")]
        public string Tool3Descr { get; set; }

        [JsonPropertyName("tool4Descr")]
        public string Tool4Descr { get; set; }

        [JsonPropertyName("tool5Descr")]
        public string Tool5Descr { get; set; }

        [JsonPropertyName("actFootage")]
        public int ActFootage { get; set; }

        [JsonPropertyName("estPackHrs")]
        public decimal EstPackHrs { get; set; }

        [JsonPropertyName("actPackHrs")]
        public decimal ActPackHrs { get; set; }

        [JsonPropertyName("inkStatus")]
        public string InkStatus { get; set; }

        [JsonPropertyName("billState")]
        public string BillState { get; set; }

        [JsonPropertyName("finishNotes")]
        public string FinishNotes { get; set; }

        [JsonPropertyName("shipCounty")]
        public string ShipCounty { get; set; }

        [JsonPropertyName("stockNotes")]
        public string StockNotes { get; set; }

        [JsonPropertyName("creditHoldOverride")]
        public bool? CreditHoldOverride { get; set; }

        [JsonPropertyName("shrinkSleeveOverLap")]
        public bool? ShrinkSleeveOverLap { get; set; }

        [JsonPropertyName("shrinkSleeveCutHeight")]
        public bool? ShrinkSleeveCutHeight { get; set; }

        [JsonPropertyName("stockDesc1")]
        public string StockDesc1 { get; set; }

        [JsonPropertyName("stockDesc2")]
        public string StockDesc2 { get; set; }

        [JsonPropertyName("stockDesc3")]
        public string StockDesc3 { get; set; }

        [JsonPropertyName("custContact")]
        public string CustContact { get; set; }

        [JsonPropertyName("coreType")]
        public string CoreType { get; set; }

        [JsonPropertyName("rollUnit")]
        public string RollUnit { get; set; }

        [JsonPropertyName("rollLength")]
        public int RollLength { get; set; }


        [JsonPropertyName("taskName")]
        public string TaskName { get; set; }

        [JsonPropertyName("equipmentName")]
        public string EquipmentName { get; set; }

        [JsonPropertyName("startsAt")]
        public DateTime StartsAt { get; set; }

        [JsonPropertyName("endsAt")]
        public DateTime EndsAt { get; set; }

        [JsonPropertyName("changeoverMinutes")]
        public double? ChangeoverMinutes { get; set; }

        [JsonPropertyName("taskMinutes")]
        public double? TaskMinutes { get; set; }

        [JsonPropertyName("taskStatus")]
        public string TaskStatus { get; set; }

        [JsonPropertyName("workcenterName")]
        public string WorkcenterName { get; set; }

        [JsonPropertyName("taskMeters")]
        public string TaskEstimatedMeters { get; set; }

        [JsonPropertyName("schedulingNotes")]
        public string SchedulingNotes { get; set; }

        [JsonPropertyName("scheduleId")]
        public string ScheduleId { get; set; }

        [JsonPropertyName("isPinned")]
        public bool? IsPinned { get; set; }

        [JsonPropertyName("pinType")]
        public string PinType { get; set; }

        [JsonPropertyName("lockStatus")]
        public string LockStatus { get; set; }

        [JsonPropertyName("lockType")]
        public string LockType { get; set; }

        [JsonPropertyName("isOnPress")]
        public bool IsOnPress { get; set; }

        [JsonPropertyName("highlight")]
        public bool Highlight { get; set; }

        [JsonPropertyName("manuallyScheduled")]
        public bool ManuallyScheduled { get; set; }

        [JsonPropertyName("feasibilityOverride")]
        public bool FeasibilityOverride { get; set; }

        [JsonPropertyName("isRollingLock")]
        public bool IsRollingLock { get; set; }

        [JsonPropertyName("masterRollNumber")]
        public string MasterRollNumber { get; set; }

        [JsonPropertyName("isMasterRollGroup")]
        public bool IsMasterRollGroup { get; set; }

        [JsonPropertyName("equipmentId")]
        public string EquipmentId { get; set; }

        [JsonPropertyName("workcenterId")]
        public string WorkcenterId { get; set; }

        [JsonPropertyName("canBeUnscheduled")]
        public bool CanBeUnscheduled { get; set; }

        [JsonPropertyName("isTicketEdited")]
        public bool IsTicketEdited { get; set; }

        [JsonPropertyName("forcedGroup")]
        public string ForcedGroup { get; set; }

        [JsonPropertyName("isMasterRoll")]
        public bool IsMasterRoll { get; set; }

        [JsonPropertyName("ticketCategory")]
        public int TicketCategory { get; set; }

        [JsonPropertyName("isTicketGeneralNotePresent")]
        public bool IsTicketGeneralNotePresent { get; set; }

        [JsonPropertyName("stockStatus")]
        public string StockStatus { get; set; }

        [JsonPropertyName("workcenterMaterialTicketCategory")]
        public int WorkcenterMaterialTicketCategory { get; set; }

        [JsonPropertyName("isCompletingOnTime")]
        public int? IsCompletingOnTime { get; set; }

        [JsonPropertyName("hasPreviousTaskPartiallyRan")]
        public bool HasPreviousTaskPartiallyRan { get; set; }

        [JsonPropertyName("isFirstDay")]
        public bool IsFirstDay { get; set; }

        [JsonPropertyName("isStagingCompleted")]
        public bool IsStagingCompleted { get; set; }

        [JsonPropertyName("isStagingUrgent")]
        public bool IsStagingUrgent { get; set; }

        [JsonPropertyName("taskList")]
        public List<TaskInformation> TaskList { get; set; }

        [JsonPropertyName("ticketAttributes")]
        public List<TicketAttributeValue> TicketAttribute { get; set; }

        [JsonPropertyName("stagingComponents")]
        public List<StagingComponent> StagingComponents { get; set; }

        [JsonPropertyName("valuestreams")]
        public List<string> ValueStreams { get; set; } = new List<string>();

        [JsonPropertyName("wipValue")]
        public string WIPValue { get; set; }
    }

    public class TaskInformation
    {
        [JsonPropertyName("taskName")]
        public string TaskName { get; set; }

        [JsonPropertyName("startsAt")]
        public DateTime StartsAt { get; set; }

        [JsonPropertyName("endsAt")]
        public DateTime EndsAt { get; set; }

        [JsonPropertyName("status")]
        public string Status { get; set; }

        [JsonPropertyName("isOnPress")]
        public bool IsOnPress { get; set; }

        [JsonPropertyName("isEstMinsEdited")]
        public bool IsEstMinsEdited { get; set; }

        [JsonPropertyName("isStatusEdited")]
        public bool IsStatusEdited { get; set; }
    }

    public class TicketAttributeValue
    {
        [JsonPropertyName("name")]
        public string Name { get; set; }

        [JsonPropertyName("value")]
        public string Value { get; set; }
    }

    public class StagingComponent
    {

        [JsonPropertyName("name")]
        public string Name { get; set; }

        [JsonPropertyName("isStaged")]
        public bool IsStaged { get; set; }

        [JsonPropertyName("value")]
        public string Value { get; set; }

        [JsonPropertyName("ticketTaskStagingHoverData")]
        public List<TicketAttributeValue> TicketTaskStagingHoverData { get; set; } = new List<TicketAttributeValue>();
    }
}

using Batched.Common.Data.Sql.Extensions;
using System.Data;

namespace Batched.Reporting.Data.DataModels
{
    public class OpenTicketDetailsLTMDataRow : DataRowParser
    {
        public decimal ActFootage { get; set; }
        public decimal ActPackHrs { get; set; }
        public decimal ActualEstTotalHours { get; set; }
        public decimal ActualQuantity { get; set; }
        public bool ArtWorkComplete { get; set; }
        public string BackStageColorStrategy { get; set; }
        public string BillAddr1 { get; set; }
        public string BillAddr2 { get; set; }
        public string BillCity { get; set; }
        public string BillCountry { get; set; }
        public string BillState { get; set; }
        public string BillZip { get; set; }
        public string Colors { get; set; }
        public decimal ColumnPerf { get; set; }
        public decimal ColumnSpace { get; set; }
        public bool ConsecutiveNumber { get; set; }
        public decimal Coresize { get; set; }
        public string CoreType { get; set; }
        public DateTime CreatedOn { get; set; }
        public bool CreditHoldOverride { get; set; }
        public string CustContact { get; set; }
        public string CustomerName { get; set; }
        public string CustomerPO { get; set; }
        public DateTime DateDone { get; set; }
        public DateTime DueOnsiteDate { get; set; }
        public DateTime EndsAt { get; set; }
        public string EndUserName { get; set; }
        public string EndUserNum { get; set; }
        public string EndUserPO { get; set; }
        public string EquipmentId { get; set; }
        public string EquipmentName { get; set; }
        public string EstimatedLength { get; set; }
        public DateTime EstMaxDueDateTime { get; set; }
        public decimal EstPackHrs { get; set; }
        public string EstTotalRevenue { get; set; }
        public string FacilityId { get; set; }
        public string FacilityName { get; set; }
        public string FinalUnwind { get; set; }
        public decimal FinishedNumAcross { get; set; }
        public decimal FinishedNumLabels { get; set; }
        public string FinishNotes { get; set; }
        public string FinishType { get; set; }
        public string GeneralDescription { get; set; }
        public bool InkReceived { get; set; }
        public string InkStatus { get; set; }
        public bool IsBackSidePrinted { get; set; }
        public bool IsComplete { get; set; }
        public bool IsOnPress { get; set; }
        public bool IsPrintReversed { get; set; }
        public bool IsSlitOnRewind { get; set; }
        public bool IsStockAllocated { get; set; }
        public bool IsTicketGeneralNotePresent { get; set; }
        public string ITSAssocNum { get; set; }
        public string ITSName { get; set; }
        public decimal LabelRepeat { get; set; }
        public DateTime ModifiedOn { get; set; }
        public decimal NoOfPlateChanges { get; set; }
        public decimal NumAcross { get; set; }
        public decimal NumAroundPlate { get; set; }
        public DateTime OrderDate { get; set; }
        public string OriginalEquipmentId { get; set; }
        public string OriginalEquipmentName { get; set; }
        public string OTSAssocNum { get; set; }
        public string OTSName { get; set; }
        public decimal OutsideDiameter { get; set; }
        public decimal OverRunLength { get; set; }
        public bool Pinfeed { get; set; }
        public bool PlateComplete { get; set; }
        public string Plates { get; set; }
        public string PriceMode { get; set; }
        public bool ProofComplete { get; set; }
        public decimal Quantity { get; set; }
        public decimal RollLength { get; set; }
        public string RollUnit { get; set; }
        public decimal RowPerf { get; set; }
        public decimal RowSpace { get; set; }
        public decimal ScheduledHours { get; set; }
        public string ScheduleId { get; set; }
        public string Shape { get; set; }
        public string ShipAttnEmailAddress { get; set; }
        public DateTime ShipByDate { get; set; }
        public string ShipCounty { get; set; }
        public string ShipLocation { get; set; }
        public DateTime ShippedOnDate { get; set; }
        public string ShippingAddress { get; set; }
        public string Shippingcity { get; set; }
        public string ShippingInstruc { get; set; }
        public string ShippingStatus { get; set; }
        public string ShipVia { get; set; }
        public string ShipZip { get; set; }
        public bool ShrinkSleeveCutHeight { get; set; }
        public string ShrinkSleeveLayFlat { get; set; }
        public bool ShrinkSleeveOverLap { get; set; }
        public decimal SizeAcross { get; set; }
        public string SizeAround { get; set; }
        public string SourceCustomerId { get; set; }
        public DateTime StartsAt { get; set; }
        public string StockDesc1 { get; set; }
        public string StockDesc2 { get; set; }
        public string StockDesc3 { get; set; }
        public string StockNotes { get; set; }
        public bool StockReceived { get; set; }
        public decimal StockTicketType { get; set; }
        public string Tab { get; set; }
        public string TaskName { get; set; }
        public string TaskStatus { get; set; }
        public string TicketId { get; set; }
        public string TicketNotes { get; set; }
        public string TicketNumber { get; set; }
        public string TicketPoints { get; set; }
        public string TicketPriority { get; set; }
        public string TicketStatus { get; set; }
        public decimal TicketType { get; set; }
        public string Tool1Descr { get; set; }
        public string Tool2Descr { get; set; }
        public string Tool3Descr { get; set; }
        public string Tool4Descr { get; set; }
        public string Tool5Descr { get; set; }
        public bool ToolsReceived { get; set; }
        public bool UseTurretRewinder { get; set; }
        public string WorkcenterId { get; set; }
        public string WorkcenterName { get; set; }

        public override void Fill(DataRow dataRow)
        {
            if (dataRow.Table.Columns.Contains("ActFootage") && !dataRow.IsNull("ActFootage"))
                ActFootage = Convert.ToDecimal(dataRow["ActFootage"]);

            if (dataRow.Table.Columns.Contains("ActPackHrs") && !dataRow.IsNull("ActPackHrs"))
                ActPackHrs = Convert.ToDecimal(dataRow["ActPackHrs"]);

            if (dataRow.Table.Columns.Contains("ActualEstTotalHours") && !dataRow.IsNull("ActualEstTotalHours"))
                ActualEstTotalHours = Convert.ToDecimal(dataRow["ActualEstTotalHours"]);

            if (dataRow.Table.Columns.Contains("ActualQuantity") && !dataRow.IsNull("ActualQuantity"))
                ActualQuantity = Convert.ToDecimal(dataRow["ActualQuantity"]);

            if (dataRow.Table.Columns.Contains("ArtWorkComplete") && !dataRow.IsNull("ArtWorkComplete"))
                ArtWorkComplete = Convert.ToBoolean(dataRow["ArtWorkComplete"]);

            if (dataRow.Table.Columns.Contains("BackStageColorStrategy") && !dataRow.IsNull("BackStageColorStrategy"))
                BackStageColorStrategy = Convert.ToString(dataRow["BackStageColorStrategy"]);

            if (dataRow.Table.Columns.Contains("BillAddr1") && !dataRow.IsNull("BillAddr1"))
                BillAddr1 = Convert.ToString(dataRow["BillAddr1"]);

            if (dataRow.Table.Columns.Contains("BillAddr2") && !dataRow.IsNull("BillAddr2"))
                BillAddr2 = Convert.ToString(dataRow["BillAddr2"]);

            if (dataRow.Table.Columns.Contains("BillCity") && !dataRow.IsNull("BillCity"))
                BillCity = Convert.ToString(dataRow["BillCity"]);

            if (dataRow.Table.Columns.Contains("BillCountry") && !dataRow.IsNull("BillCountry"))
                BillCountry = Convert.ToString(dataRow["BillCountry"]);

            if (dataRow.Table.Columns.Contains("BillState") && !dataRow.IsNull("BillState"))
                BillState = Convert.ToString(dataRow["BillState"]);

            if (dataRow.Table.Columns.Contains("BillZip") && !dataRow.IsNull("BillZip"))
                BillZip = Convert.ToString(dataRow["BillZip"]);

            if (dataRow.Table.Columns.Contains("Colors") && !dataRow.IsNull("Colors"))
                Colors = Convert.ToString(dataRow["Colors"]);

            if (dataRow.Table.Columns.Contains("ColumnPerf") && !dataRow.IsNull("ColumnPerf"))
                ColumnPerf = Convert.ToDecimal(dataRow["ColumnPerf"]);

            if (dataRow.Table.Columns.Contains("ColumnSpace") && !dataRow.IsNull("ColumnSpace"))
                ColumnSpace = Convert.ToDecimal(dataRow["ColumnSpace"]);

            if (dataRow.Table.Columns.Contains("ConsecutiveNumber") && !dataRow.IsNull("ConsecutiveNumber"))
                ConsecutiveNumber = Convert.ToBoolean(dataRow["ConsecutiveNumber"]);

            if (dataRow.Table.Columns.Contains("Coresize") && !dataRow.IsNull("Coresize"))
                Coresize = Convert.ToDecimal(dataRow["Coresize"]);

            if (dataRow.Table.Columns.Contains("CoreType") && !dataRow.IsNull("CoreType"))
                CoreType = Convert.ToString(dataRow["CoreType"]);

            if (dataRow.Table.Columns.Contains("CreatedOn") && !dataRow.IsNull("CreatedOn"))
                CreatedOn = Convert.ToDateTime(dataRow["CreatedOn"]);

            if (dataRow.Table.Columns.Contains("CreditHoldOverride") && !dataRow.IsNull("CreditHoldOverride"))
                CreditHoldOverride = Convert.ToBoolean(dataRow["CreditHoldOverride"]);

            if (dataRow.Table.Columns.Contains("CustContact") && !dataRow.IsNull("CustContact"))
                CustContact = Convert.ToString(dataRow["CustContact"]);

            if (dataRow.Table.Columns.Contains("CustomerName") && !dataRow.IsNull("CustomerName"))
                CustomerName = Convert.ToString(dataRow["CustomerName"]);

            if (dataRow.Table.Columns.Contains("CustomerPO") && !dataRow.IsNull("CustomerPO"))
                CustomerPO = Convert.ToString(dataRow["CustomerPO"]);

            if (dataRow.Table.Columns.Contains("DateDone") && !dataRow.IsNull("DateDone"))
                DateDone = Convert.ToDateTime(dataRow["DateDone"]);

            if (dataRow.Table.Columns.Contains("DueOnsiteDate") && !dataRow.IsNull("DueOnsiteDate"))
                DueOnsiteDate = Convert.ToDateTime(dataRow["DueOnsiteDate"]);

            if (dataRow.Table.Columns.Contains("EndsAt") && !dataRow.IsNull("EndsAt"))
                EndsAt = Convert.ToDateTime(dataRow["EndsAt"]);

            if (dataRow.Table.Columns.Contains("EndUserName") && !dataRow.IsNull("EndUserName"))
                EndUserName = Convert.ToString(dataRow["EndUserName"]);

            if (dataRow.Table.Columns.Contains("EndUserNum") && !dataRow.IsNull("EndUserNum"))
                EndUserNum = Convert.ToString(dataRow["EndUserNum"]);

            if (dataRow.Table.Columns.Contains("EndUserPO") && !dataRow.IsNull("EndUserPO"))
                EndUserPO = Convert.ToString(dataRow["EndUserPO"]);

            if (dataRow.Table.Columns.Contains("EquipmentId") && !dataRow.IsNull("EquipmentId"))
                EquipmentId = Convert.ToString(dataRow["EquipmentId"]);

            if (dataRow.Table.Columns.Contains("EquipmentName") && !dataRow.IsNull("EquipmentName"))
                EquipmentName = Convert.ToString(dataRow["EquipmentName"]);

            if (dataRow.Table.Columns.Contains("EstimatedLength") && !dataRow.IsNull("EstimatedLength"))
                EstimatedLength = Convert.ToString(dataRow["EstimatedLength"]);

            if (dataRow.Table.Columns.Contains("EstMaxDueDateTime") && !dataRow.IsNull("EstMaxDueDateTime"))
                EstMaxDueDateTime = Convert.ToDateTime(dataRow["EstMaxDueDateTime"]);

            if (dataRow.Table.Columns.Contains("EstPackHrs") && !dataRow.IsNull("EstPackHrs"))
                EstPackHrs = Convert.ToDecimal(dataRow["EstPackHrs"]);

            if (dataRow.Table.Columns.Contains("EstTotalRevenue") && !dataRow.IsNull("EstTotalRevenue"))
                EstTotalRevenue = Convert.ToString(dataRow["EstTotalRevenue"]);

            if (dataRow.Table.Columns.Contains("FacilityId") && !dataRow.IsNull("FacilityId"))
                FacilityId = Convert.ToString(dataRow["FacilityId"]);

            if (dataRow.Table.Columns.Contains("FacilityName") && !dataRow.IsNull("FacilityName"))
                FacilityName = Convert.ToString(dataRow["FacilityName"]);

            if (dataRow.Table.Columns.Contains("FinalUnwind") && !dataRow.IsNull("FinalUnwind"))
                FinalUnwind = Convert.ToString(dataRow["FinalUnwind"]);

            if (dataRow.Table.Columns.Contains("FinishedNumAcross") && !dataRow.IsNull("FinishedNumAcross"))
                FinishedNumAcross = Convert.ToDecimal(dataRow["FinishedNumAcross"]);

            if (dataRow.Table.Columns.Contains("FinishedNumLabels") && !dataRow.IsNull("FinishedNumLabels"))
                FinishedNumLabels = Convert.ToDecimal(dataRow["FinishedNumLabels"]);

            if (dataRow.Table.Columns.Contains("FinishNotes") && !dataRow.IsNull("FinishNotes"))
                FinishNotes = Convert.ToString(dataRow["FinishNotes"]);

            if (dataRow.Table.Columns.Contains("FinishType") && !dataRow.IsNull("FinishType"))
                FinishType = Convert.ToString(dataRow["FinishType"]);

            if (dataRow.Table.Columns.Contains("GeneralDescription") && !dataRow.IsNull("GeneralDescription"))
                GeneralDescription = Convert.ToString(dataRow["GeneralDescription"]);

            if (dataRow.Table.Columns.Contains("InkReceived") && !dataRow.IsNull("InkReceived"))
                InkReceived = Convert.ToBoolean(dataRow["InkReceived"]);

            if (dataRow.Table.Columns.Contains("InkStatus") && !dataRow.IsNull("InkStatus"))
                InkStatus = Convert.ToString(dataRow["InkStatus"]);

            if (dataRow.Table.Columns.Contains("IsBackSidePrinted") && !dataRow.IsNull("IsBackSidePrinted"))
                IsBackSidePrinted = Convert.ToBoolean(dataRow["IsBackSidePrinted"]);

            if (dataRow.Table.Columns.Contains("IsComplete") && !dataRow.IsNull("IsComplete"))
                IsComplete = Convert.ToBoolean(dataRow["IsComplete"]);

            if (dataRow.Table.Columns.Contains("IsOnPress") && !dataRow.IsNull("IsOnPress"))
                IsOnPress = Convert.ToBoolean(dataRow["IsOnPress"]);

            if (dataRow.Table.Columns.Contains("IsPrintReversed") && !dataRow.IsNull("IsPrintReversed"))
                IsPrintReversed = Convert.ToBoolean(dataRow["IsPrintReversed"]);

            if (dataRow.Table.Columns.Contains("IsSlitOnRewind") && !dataRow.IsNull("IsSlitOnRewind"))
                IsSlitOnRewind = Convert.ToBoolean(dataRow["IsSlitOnRewind"]);

            if (dataRow.Table.Columns.Contains("IsStockAllocated") && !dataRow.IsNull("IsStockAllocated"))
                IsStockAllocated = Convert.ToBoolean(dataRow["IsStockAllocated"]);

            if (dataRow.Table.Columns.Contains("IsTicketGeneralNotePresent") && !dataRow.IsNull("IsTicketGeneralNotePresent"))
                IsTicketGeneralNotePresent = Convert.ToBoolean(dataRow["IsTicketGeneralNotePresent"]);

            if (dataRow.Table.Columns.Contains("ITSAssocNum") && !dataRow.IsNull("ITSAssocNum"))
                ITSAssocNum = Convert.ToString(dataRow["ITSAssocNum"]);

            if (dataRow.Table.Columns.Contains("ITSName") && !dataRow.IsNull("ITSName"))
                ITSName = Convert.ToString(dataRow["ITSName"]);

            if (dataRow.Table.Columns.Contains("LabelRepeat") && !dataRow.IsNull("LabelRepeat"))
                LabelRepeat = Convert.ToDecimal(dataRow["LabelRepeat"]);

            if (dataRow.Table.Columns.Contains("ModifiedOn") && !dataRow.IsNull("ModifiedOn"))
                ModifiedOn = Convert.ToDateTime(dataRow["ModifiedOn"]);

            if (dataRow.Table.Columns.Contains("NoOfPlateChanges") && !dataRow.IsNull("NoOfPlateChanges"))
                NoOfPlateChanges = Convert.ToDecimal(dataRow["NoOfPlateChanges"]);

            if (dataRow.Table.Columns.Contains("NumAcross") && !dataRow.IsNull("NumAcross"))
                NumAcross = Convert.ToDecimal(dataRow["NumAcross"]);

            if (dataRow.Table.Columns.Contains("NumAroundPlate") && !dataRow.IsNull("NumAroundPlate"))
                NumAroundPlate = Convert.ToDecimal(dataRow["NumAroundPlate"]);

            if (dataRow.Table.Columns.Contains("OrderDate") && !dataRow.IsNull("OrderDate"))
                OrderDate = Convert.ToDateTime(dataRow["OrderDate"]);

            if (dataRow.Table.Columns.Contains("OriginalEquipmentId") && !dataRow.IsNull("OriginalEquipmentId"))
                OriginalEquipmentId = Convert.ToString(dataRow["OriginalEquipmentId"]);

            if (dataRow.Table.Columns.Contains("OriginalEquipmentName") && !dataRow.IsNull("OriginalEquipmentName"))
                OriginalEquipmentName = Convert.ToString(dataRow["OriginalEquipmentName"]);

            if (dataRow.Table.Columns.Contains("OTSAssocNum") && !dataRow.IsNull("OTSAssocNum"))
                OTSAssocNum = Convert.ToString(dataRow["OTSAssocNum"]);

            if (dataRow.Table.Columns.Contains("OTSName") && !dataRow.IsNull("OTSName"))
                OTSName = Convert.ToString(dataRow["OTSName"]);

            if (dataRow.Table.Columns.Contains("OutsideDiameter") && !dataRow.IsNull("OutsideDiameter"))
                OutsideDiameter = Convert.ToDecimal(dataRow["OutsideDiameter"]);

            if (dataRow.Table.Columns.Contains("OverRunLength") && !dataRow.IsNull("OverRunLength"))
                OverRunLength = Convert.ToDecimal(dataRow["OverRunLength"]);

            if (dataRow.Table.Columns.Contains("Pinfeed") && !dataRow.IsNull("Pinfeed"))
                Pinfeed = Convert.ToBoolean(dataRow["Pinfeed"]);

            if (dataRow.Table.Columns.Contains("PlateComplete") && !dataRow.IsNull("PlateComplete"))
                PlateComplete = Convert.ToBoolean(dataRow["PlateComplete"]);

            if (dataRow.Table.Columns.Contains("Plates") && !dataRow.IsNull("Plates"))
                Plates = Convert.ToString(dataRow["Plates"]);

            if (dataRow.Table.Columns.Contains("PriceMode") && !dataRow.IsNull("PriceMode"))
                PriceMode = Convert.ToString(dataRow["PriceMode"]);

            if (dataRow.Table.Columns.Contains("Priority") && !dataRow.IsNull("Priority"))
                TicketPriority = Convert.ToString(dataRow["Priority"]);

            if (dataRow.Table.Columns.Contains("ProofComplete") && !dataRow.IsNull("ProofComplete"))
                ProofComplete = Convert.ToBoolean(dataRow["ProofComplete"]);

            if (dataRow.Table.Columns.Contains("Quantity") && !dataRow.IsNull("Quantity"))
                Quantity = Convert.ToDecimal(dataRow["Quantity"]);

            if (dataRow.Table.Columns.Contains("RollLength") && !dataRow.IsNull("RollLength"))
                RollLength = Convert.ToDecimal(dataRow["RollLength"]);

            if (dataRow.Table.Columns.Contains("RollUnit") && !dataRow.IsNull("RollUnit"))
                RollUnit = Convert.ToString(dataRow["RollUnit"]);

            if (dataRow.Table.Columns.Contains("RowPerf") && !dataRow.IsNull("RowPerf"))
                RowPerf = Convert.ToDecimal(dataRow["RowPerf"]);

            if (dataRow.Table.Columns.Contains("RowSpace") && !dataRow.IsNull("RowSpace"))
                RowSpace = Convert.ToDecimal(dataRow["RowSpace"]);

            if (dataRow.Table.Columns.Contains("ScheduledHours") && !dataRow.IsNull("ScheduledHours"))
                ScheduledHours = Convert.ToDecimal(dataRow["ScheduledHours"]);

            if (dataRow.Table.Columns.Contains("ScheduleId") && !dataRow.IsNull("ScheduleId"))
                ScheduleId = Convert.ToString(dataRow["ScheduleId"]);

            if (dataRow.Table.Columns.Contains("Shape") && !dataRow.IsNull("Shape"))
                Shape = Convert.ToString(dataRow["Shape"]);

            if (dataRow.Table.Columns.Contains("ShipAttnEmailAddress") && !dataRow.IsNull("ShipAttnEmailAddress"))
                ShipAttnEmailAddress = Convert.ToString(dataRow["ShipAttnEmailAddress"]);

            if (dataRow.Table.Columns.Contains("ShipByDate") && !dataRow.IsNull("ShipByDate"))
                ShipByDate = Convert.ToDateTime(dataRow["ShipByDate"]);

            if (dataRow.Table.Columns.Contains("ShipCounty") && !dataRow.IsNull("ShipCounty"))
                ShipCounty = Convert.ToString(dataRow["ShipCounty"]);

            if (dataRow.Table.Columns.Contains("ShipLocation") && !dataRow.IsNull("ShipLocation"))
                ShipLocation = Convert.ToString(dataRow["ShipLocation"]);

            if (dataRow.Table.Columns.Contains("ShippedOnDate") && !dataRow.IsNull("ShippedOnDate"))
                ShippedOnDate = Convert.ToDateTime(dataRow["ShippedOnDate"]);

            if (dataRow.Table.Columns.Contains("ShippingAddress") && !dataRow.IsNull("ShippingAddress"))
                ShippingAddress = Convert.ToString(dataRow["ShippingAddress"]);

            if (dataRow.Table.Columns.Contains("Shippingcity") && !dataRow.IsNull("Shippingcity"))
                Shippingcity = Convert.ToString(dataRow["Shippingcity"]);

            if (dataRow.Table.Columns.Contains("ShippingInstruc") && !dataRow.IsNull("ShippingInstruc"))
                ShippingInstruc = Convert.ToString(dataRow["ShippingInstruc"]);

            if (dataRow.Table.Columns.Contains("ShippingStatus") && !dataRow.IsNull("ShippingStatus"))
                ShippingStatus = Convert.ToString(dataRow["ShippingStatus"]);

            if (dataRow.Table.Columns.Contains("ShipVia") && !dataRow.IsNull("ShipVia"))
                ShipVia = Convert.ToString(dataRow["ShipVia"]);

            if (dataRow.Table.Columns.Contains("ShipZip") && !dataRow.IsNull("ShipZip"))
                ShipZip = Convert.ToString(dataRow["ShipZip"]);

            if (dataRow.Table.Columns.Contains("ShrinkSleeveCutHeight") && !dataRow.IsNull("ShrinkSleeveCutHeight"))
                ShrinkSleeveCutHeight = Convert.ToBoolean(dataRow["ShrinkSleeveCutHeight"]);

            if (dataRow.Table.Columns.Contains("ShrinkSleeveLayFlat") && !dataRow.IsNull("ShrinkSleeveLayFlat"))
                ShrinkSleeveLayFlat = Convert.ToString(dataRow["ShrinkSleeveLayFlat"]);

            if (dataRow.Table.Columns.Contains("ShrinkSleeveOverLap") && !dataRow.IsNull("ShrinkSleeveOverLap"))
                ShrinkSleeveOverLap = Convert.ToBoolean(dataRow["ShrinkSleeveOverLap"]);

            if (dataRow.Table.Columns.Contains("SizeAcross") && !dataRow.IsNull("SizeAcross"))
                SizeAcross = Convert.ToDecimal(dataRow["SizeAcross"]);

            if (dataRow.Table.Columns.Contains("SizeAround") && !dataRow.IsNull("SizeAround"))
                SizeAround = Convert.ToString(dataRow["SizeAround"]);

            if (dataRow.Table.Columns.Contains("StartsAt") && !dataRow.IsNull("StartsAt"))
                StartsAt = Convert.ToDateTime(dataRow["StartsAt"]);

            if (dataRow.Table.Columns.Contains("SourceCustomerId") && !dataRow.IsNull("SourceCustomerId"))
                SourceCustomerId = Convert.ToString(dataRow["SourceCustomerId"]);

            if (dataRow.Table.Columns.Contains("StockDesc1") && !dataRow.IsNull("StockDesc1"))
                StockDesc1 = Convert.ToString(dataRow["StockDesc1"]);

            if (dataRow.Table.Columns.Contains("StockDesc2") && !dataRow.IsNull("StockDesc2"))
                StockDesc2 = Convert.ToString(dataRow["StockDesc2"]);

            if (dataRow.Table.Columns.Contains("StockDesc3") && !dataRow.IsNull("StockDesc3"))
                StockDesc3 = Convert.ToString(dataRow["StockDesc3"]);

            if (dataRow.Table.Columns.Contains("StockNotes") && !dataRow.IsNull("StockNotes"))
                StockNotes = Convert.ToString(dataRow["StockNotes"]);

            if (dataRow.Table.Columns.Contains("StockReceived") && !dataRow.IsNull("StockReceived"))
                StockReceived = Convert.ToBoolean(dataRow["StockReceived"]);

            if (dataRow.Table.Columns.Contains("StockTicketType") && !dataRow.IsNull("StockTicketType"))
                StockTicketType = Convert.ToDecimal(dataRow["StockTicketType"]);

            if (dataRow.Table.Columns.Contains("Tab") && !dataRow.IsNull("Tab"))
                Tab = Convert.ToString(dataRow["Tab"]);

            if (dataRow.Table.Columns.Contains("TaskName") && !dataRow.IsNull("TaskName"))
                TaskName = Convert.ToString(dataRow["TaskName"]);

            if (dataRow.Table.Columns.Contains("TaskStatus") && !dataRow.IsNull("TaskStatus"))
                TaskStatus = Convert.ToString(dataRow["TaskStatus"]);

            if (dataRow.Table.Columns.Contains("TicketId") && !dataRow.IsNull("TicketId"))
                TicketId = Convert.ToString(dataRow["TicketId"]);

            if (dataRow.Table.Columns.Contains("TicketNotes") && !dataRow.IsNull("TicketNotes"))
                TicketNotes = Convert.ToString(dataRow["TicketNotes"]);

            if (dataRow.Table.Columns.Contains("TicketNumber") && !dataRow.IsNull("TicketNumber"))
                TicketNumber = Convert.ToString(dataRow["TicketNumber"]);

            if (dataRow.Table.Columns.Contains("TicketPoints") && !dataRow.IsNull("TicketPoints"))
                TicketPoints = Math.Round(Convert.ToDecimal(dataRow["TicketPoints"]), 2).ToString();

            if (dataRow.Table.Columns.Contains("TicketStatus") && !dataRow.IsNull("TicketStatus"))
                TicketStatus = Convert.ToString(dataRow["TicketStatus"]);

            if (dataRow.Table.Columns.Contains("TicketType") && !dataRow.IsNull("TicketType"))
                TicketType = Convert.ToDecimal(dataRow["TicketType"]);

            if (dataRow.Table.Columns.Contains("Tool1Descr") && !dataRow.IsNull("Tool1Descr"))
                Tool1Descr = Convert.ToString(dataRow["Tool1Descr"]);

            if (dataRow.Table.Columns.Contains("Tool2Descr") && !dataRow.IsNull("Tool2Descr"))
                Tool2Descr = Convert.ToString(dataRow["Tool2Descr"]);

            if (dataRow.Table.Columns.Contains("Tool3Descr") && !dataRow.IsNull("Tool3Descr"))
                Tool3Descr = Convert.ToString(dataRow["Tool3Descr"]);

            if (dataRow.Table.Columns.Contains("Tool4Descr") && !dataRow.IsNull("Tool4Descr"))
                Tool4Descr = Convert.ToString(dataRow["Tool4Descr"]);

            if (dataRow.Table.Columns.Contains("Tool5Descr") && !dataRow.IsNull("Tool5Descr"))
                Tool5Descr = Convert.ToString(dataRow["Tool5Descr"]);

            if (dataRow.Table.Columns.Contains("ToolsReceived") && !dataRow.IsNull("ToolsReceived"))
                ToolsReceived = Convert.ToBoolean(dataRow["ToolsReceived"]);

            if (dataRow.Table.Columns.Contains("UseTurretRewinder") && !dataRow.IsNull("UseTurretRewinder"))
                UseTurretRewinder = Convert.ToBoolean(dataRow["UseTurretRewinder"]);

            if (dataRow.Table.Columns.Contains("WorkcenterId") && !dataRow.IsNull("WorkcenterId"))
                WorkcenterId = Convert.ToString(dataRow["WorkcenterId"]);

            if (dataRow.Table.Columns.Contains("WorkcenterName") && !dataRow.IsNull("WorkcenterName"))
                WorkcenterName = Convert.ToString(dataRow["WorkcenterName"]);
        }
    }
}

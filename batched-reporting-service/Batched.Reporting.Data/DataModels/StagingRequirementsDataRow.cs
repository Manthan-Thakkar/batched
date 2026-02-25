using Batched.Common.Data.Sql.Extensions;
using Batched.Reporting.Data.Translators;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Batched.Reporting.Data.DataModels
{

    internal class StagingRequirementsDataRow : DataRowParser
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
        public bool ProofStatus { get; set; }
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
        public bool CanBeUnscheduled { get; set; }
        public bool IsMasterRoll { get; set; }
        public List<TaskInformation> TaskList { get; set; }
        public List<string> ValueStreams { get; set; } = new List<string>();
        public List<string> StagingRequirements { get; set; } = new List<string>();
        public string ForcedGroup { get; set; }
        public int TicketCategory { get; set; }
        public bool IsTicketGeneralNotePresent { get; set; }
        public DateTime RecordCreatedOn { get; set; }
        public string StockStatus { get; set; }
        public int WorkcenterMaterialTicketCategory { get; set; }
        public int? IsCompletingOnTime { get; set; }
        public bool IsFirstDay { get; set; }
        public string WIPValue { get; set; }
        public bool HasPreviousTaskPartiallyRan { get; set; }


        public override void Fill(DataRow dataRow)
        {
            #region Ticket Fields

            if (!dataRow.IsNull("TicketNumber"))
                TicketNumber = dataRow["TicketNumber"].ToString();

            if (!dataRow.IsNull("TicketId"))
                TicketId = dataRow["TicketId"].ToString();

            if (!dataRow.IsNull("CustomerName"))
                CustomerName = dataRow["CustomerName"].ToString();

            if (!dataRow.IsNull("GeneralDescription"))
                GeneralDescription = dataRow["GeneralDescription"].ToString();

            if (!dataRow.IsNull("TicketPoints"))
                TicketPoints = Math.Round(Convert.ToDecimal(dataRow["TicketPoints"]), 2).ToString();

            if (!dataRow.IsNull("ShipByDate"))
                ShipByDate = dataRow.Field<DateTime>("ShipByDate");

            if (!dataRow.IsNull("OrderDate"))
                OrderDate = dataRow.Field<DateTime>("OrderDate");

            if (!dataRow.IsNull("SourceCustomerId"))
                SourceCustomerId = dataRow["SourceCustomerId"].ToString();

            if (!dataRow.IsNull("CustomerPO"))
                CustomerPO = dataRow["CustomerPO"].ToString();

            if (!dataRow.IsNull("TicketPriority"))
                TicketPriority = dataRow["TicketPriority"].ToString();

            if (!dataRow.IsNull("FinishType"))
                FinishType = dataRow["FinishType"].ToString();

            if (!dataRow.IsNull("IsBackSidePrinted"))
                IsBackSidePrinted = dataRow.Field<bool>("IsBackSidePrinted");

            if (!dataRow.IsNull("IsSlitOnRewind"))
                IsSlitOnRewind = dataRow.Field<bool>("IsSlitOnRewind");

            if (!dataRow.IsNull("UseTurretRewinder"))
                IsSlitOnRewind = dataRow.Field<bool>("UseTurretRewinder");

            if (!dataRow.IsNull("EstTotalRevenue"))
                EstTotalRevenue = dataRow["EstTotalRevenue"].ToString();

            if (!dataRow.IsNull("TicketType"))
                TicketType = Convert.ToInt32(dataRow["TicketType"]);

            if (!dataRow.IsNull("PriceMode"))
                PriceMode = dataRow["PriceMode"].ToString();

            if (!dataRow.IsNull("FinalUnwind"))
                FinalUnwind = dataRow["FinalUnwind"].ToString();

            if (!dataRow.IsNull("TicketStatus"))
                TicketStatus = dataRow["TicketStatus"].ToString();

            if (!dataRow.IsNull("BackStageColorStrategy"))
                BackStageColorStrategy = dataRow["BackStageColorStrategy"].ToString();

            if (!dataRow.IsNull("Pinfeed"))
                Pinfeed = dataRow.Field<bool>("Pinfeed");

            if (!dataRow.IsNull("IsPrintReversed"))
                Pinfeed = dataRow.Field<bool>("IsPrintReversed");

            if (!dataRow.IsNull("TicketNotes"))
                TicketNotes = dataRow["TicketNotes"].ToString();

            if (!dataRow.IsNull("EndUserNum"))
                EndUserNum = dataRow["EndUserNum"].ToString();

            if (!dataRow.IsNull("EndUserName"))
                EndUserName = dataRow["EndUserName"].ToString();

            if (!dataRow.IsNull("CreatedOn"))
                CreatedOn = dataRow.Field<DateTime>("CreatedOn");

            if (!dataRow.IsNull("ModifiedOn"))
                ModifiedOn = dataRow.Field<DateTime>("ModifiedOn");

            if (!dataRow.IsNull("Tab"))
                Tab = dataRow["Tab"].ToString();

            if (!dataRow.IsNull("SizeAround"))
                SizeAround = dataRow["SizeAround"].ToString();

            if (!dataRow.IsNull("ShrinkSleeveLayFlat"))
                ShrinkSleeveLayFlat = dataRow["ShrinkSleeveLayFlat"].ToString();

            if (!dataRow.IsNull("Shape"))
                Shape = dataRow["Shape"].ToString();

            if (!dataRow.IsNull("StockTicketType"))
                StockTicketType = Convert.ToInt32(dataRow["StockTicketType"]);

            if (!dataRow.IsNull("ArtWorkComplete"))
                ArtWorkComplete = Convert.ToBoolean(dataRow["ArtWorkComplete"]);

            if (!dataRow.IsNull("ProofComplete"))
                ProofComplete = Convert.ToBoolean(dataRow["ProofComplete"]);

            if (!dataRow.IsNull("ProofStatus"))
                Shape = dataRow["ProofStatus"].ToString();

            if (!dataRow.IsNull("PlateComplete"))
                PlateComplete = Convert.ToBoolean(dataRow["PlateComplete"]);

            if (!dataRow.IsNull("ToolsReceived"))
                ToolsReceived = Convert.ToBoolean(dataRow["ToolsReceived"]);

            if (!dataRow.IsNull("InkReceived"))
                InkReceived = Convert.ToBoolean(dataRow["InkReceived"]);

            if (!dataRow.IsNull("StockReceived"))
                StockReceived = Convert.ToBoolean(dataRow["StockReceived"]);

            if (!dataRow.IsNull("ITSName"))
                ITSName = dataRow["ITSName"].ToString();

            if (!dataRow.IsNull("OTSName"))
                OTSName = dataRow["OTSName"].ToString();

            if (!dataRow.IsNull("ConsecutiveNumber"))
                ConsecutiveNumber = Convert.ToBoolean(dataRow["ConsecutiveNumber"]);

            if (!dataRow.IsNull("Quantity"))
                Quantity = Convert.ToInt32(dataRow["Quantity"]);

            if (!dataRow.IsNull("ActualQuantity"))
                ActualQuantity = Convert.ToInt32(dataRow["ActualQuantity"]);

            if (!dataRow.IsNull("SizeAcross"))
                SizeAcross = Convert.ToDecimal(dataRow["SizeAcross"]);

            if (!dataRow.IsNull("ColumnSpace"))
                ColumnSpace = Convert.ToDecimal(dataRow["ColumnSpace"]);

            if (!dataRow.IsNull("RowSpace"))
                RowSpace = Convert.ToDecimal(dataRow["RowSpace"]);

            if (!dataRow.IsNull("NumAcross"))
                NumAcross = Convert.ToInt32(dataRow["NumAcross"]);

            if (!dataRow.IsNull("NumAroundPlate"))
                NumAroundPlate = Convert.ToInt32(dataRow["NumAroundPlate"]);

            if (!dataRow.IsNull("LabelRepeat"))
                LabelRepeat = Convert.ToDecimal(dataRow["LabelRepeat"]);

            if (!dataRow.IsNull("FinishedNumAcross"))
                FinishedNumAcross = Convert.ToDecimal(dataRow["FinishedNumAcross"]);

            if (!dataRow.IsNull("FinishedNumLabels"))
                FinishedNumLabels = Convert.ToInt32(dataRow["FinishedNumLabels"]);

            if (!dataRow.IsNull("Coresize"))
                Coresize = Convert.ToDecimal(dataRow["Coresize"]);

            if (!dataRow.IsNull("OutsideDiameter"))
                OutsideDiameter = Convert.ToDecimal(dataRow["OutsideDiameter"]);

            if (!dataRow.IsNull("EstimatedLength"))
                EstimatedLength = Convert.ToInt32(dataRow["EstimatedLength"]);

            if (!dataRow.IsNull("OverRunLength"))
                OverRunLength = Convert.ToDecimal(dataRow["OverRunLength"]);

            if (!dataRow.IsNull("NoOfPlateChanges"))
                NoOfPlateChanges = Convert.ToInt32(dataRow["NoOfPlateChanges"]);

            if (!dataRow.IsNull("ShippedOnDate"))
                ShippedOnDate = Convert.ToDateTime(dataRow["ShippedOnDate"]);

            if (!dataRow.IsNull("ShipVia"))
                ShipVia = Convert.ToString(dataRow["ShipVia"]);

            if (!dataRow.IsNull("DueOnsiteDate"))
                DueOnsiteDate = Convert.ToDateTime(dataRow["DueOnsiteDate"]);

            if (!dataRow.IsNull("ShippingStatus"))
                ShippingStatus = Convert.ToString(dataRow["ShippingStatus"]);

            if (!dataRow.IsNull("ShippingAddress"))
                ShippingAddress = Convert.ToString(dataRow["ShippingAddress"]);

            if (!dataRow.IsNull("Shippingcity"))
                Shippingcity = Convert.ToString(dataRow["Shippingcity"]);


            if (!dataRow.IsNull("ColumnPerf"))
                ColumnPerf = Convert.ToDecimal(dataRow["ColumnPerf"]);

            if (!dataRow.IsNull("RowPerf"))
                RowPerf = Convert.ToDecimal(dataRow["RowPerf"]);

            if (!dataRow.IsNull("ITSAssocNum"))
                ITSAssocNum = Convert.ToString(dataRow["ITSAssocNum"]);

            if (!dataRow.IsNull("OTSAssocNum"))
                OTSAssocNum = Convert.ToString(dataRow["OTSAssocNum"]);

            if (!dataRow.IsNull("ShippingInstruc"))
                ShippingInstruc = Convert.ToString(dataRow["ShippingInstruc"]);

            if (!dataRow.IsNull("DateDone"))
                DateDone = Convert.ToDateTime(dataRow["DateDone"]);

            if (!dataRow.IsNull("ShipAttnEmailAddress"))
                ShipAttnEmailAddress = Convert.ToString(dataRow["ShipAttnEmailAddress"]);

            if (!dataRow.IsNull("ShipLocation"))
                ShipLocation = Convert.ToString(dataRow["ShipLocation"]);

            if (!dataRow.IsNull("ShipZip"))
                ShipZip = Convert.ToString(dataRow["ShipZip"]);

            if (!dataRow.IsNull("BillAddr1"))
                BillAddr1 = Convert.ToString(dataRow["BillAddr1"]);

            if (!dataRow.IsNull("BillAddr2"))
                BillAddr2 = Convert.ToString(dataRow["BillAddr2"]);

            if (!dataRow.IsNull("BillCity"))
                BillCity = Convert.ToString(dataRow["BillCity"]);

            if (!dataRow.IsNull("BillZip"))
                BillZip = Convert.ToString(dataRow["BillZip"]);

            if (!dataRow.IsNull("BillCountry"))
                BillCountry = Convert.ToString(dataRow["BillCountry"]);

            if (!dataRow.IsNull("IsStockAllocated"))
                IsStockAllocated = Convert.ToBoolean(dataRow["IsStockAllocated"]);

            if (!dataRow.IsNull("EndUserPO"))
                EndUserPO = Convert.ToString(dataRow["EndUserPO"]);

            if (!dataRow.IsNull("Tool1Descr"))
                Tool1Descr = Convert.ToString(dataRow["Tool1Descr"]);

            if (!dataRow.IsNull("Tool2Descr"))
                Tool2Descr = Convert.ToString(dataRow["Tool2Descr"]);

            if (!dataRow.IsNull("Tool3Descr"))
                Tool3Descr = Convert.ToString(dataRow["Tool3Descr"]);

            if (!dataRow.IsNull("Tool4Descr"))
                Tool4Descr = Convert.ToString(dataRow["Tool4Descr"]);

            if (!dataRow.IsNull("Tool5Descr"))
                Tool5Descr = Convert.ToString(dataRow["Tool5Descr"]);

            if (!dataRow.IsNull("ActFootage"))
                ActFootage = Convert.ToInt32(dataRow["ActFootage"]);

            if (!dataRow.IsNull("EstPackHrs"))
                EstPackHrs = Convert.ToDecimal(dataRow["EstPackHrs"]);

            if (!dataRow.IsNull("ActPackHrs"))
                ActPackHrs = Convert.ToDecimal(dataRow["ActPackHrs"]);

            if (!dataRow.IsNull("InkStatus"))
                InkStatus = Convert.ToString(dataRow["InkStatus"]);

            if (!dataRow.IsNull("BillState"))
                BillState = Convert.ToString(dataRow["BillState"]);

            if (!dataRow.IsNull("CustContact"))
                CustContact = Convert.ToString(dataRow["CustContact"]);

            if (!dataRow.IsNull("CoreType"))
                CoreType = Convert.ToString(dataRow["CoreType"]);

            if (!dataRow.IsNull("RollUnit"))
                RollUnit = Convert.ToString(dataRow["RollUnit"]);

            if (!dataRow.IsNull("RollLength"))
                RollLength = Convert.ToInt32(dataRow["RollLength"]);

            if (!dataRow.IsNull("FinishNotes"))
                FinishNotes = Convert.ToString(dataRow["FinishNotes"]);

            if (!dataRow.IsNull("ShipCounty"))
                ShipCounty = Convert.ToString(dataRow["ShipCounty"]);

            if (!dataRow.IsNull("StockNotes"))
                StockNotes = Convert.ToString(dataRow["StockNotes"]);

            if (!dataRow.IsNull("CreditHoldOverride"))
                CreditHoldOverride = Convert.ToBoolean(dataRow["CreditHoldOverride"]);

            if (!dataRow.IsNull("ShrinkSleeveOverLap"))
                ShrinkSleeveOverLap = Convert.ToBoolean(dataRow["ShrinkSleeveOverLap"]);

            if (!dataRow.IsNull("ShrinkSleeveCutHeight"))
                ShrinkSleeveCutHeight = Convert.ToBoolean(dataRow["ShrinkSleeveCutHeight"]);

            if (!dataRow.IsNull("StockDesc1"))
                StockDesc1 = Convert.ToString(dataRow["StockDesc1"]);

            if (!dataRow.IsNull("StockDesc2"))
                StockDesc2 = Convert.ToString(dataRow["StockDesc2"]);

            if (!dataRow.IsNull("StockDesc3"))
                StockDesc3 = Convert.ToString(dataRow["StockDesc3"]);

            if (dataRow.Table.Columns.Contains("WIPValue") && !dataRow.IsNull("WIPValue"))
                WIPValue = dataRow["WIPValue"].ToString();

            if (dataRow.Table.Columns.Contains("HasPreviousTaskPartiallyRan") && !dataRow.IsNull("HasPreviousTaskPartiallyRan"))
                HasPreviousTaskPartiallyRan = dataRow.Field<bool>("HasPreviousTaskPartiallyRan");

            #endregion

            #region Schedule Fields

            if (!dataRow.IsNull("TaskName"))
                TaskName = dataRow["TaskName"].ToString();

            if (!dataRow.IsNull("EquipmentName"))
                EquipmentName = dataRow["EquipmentName"].ToString();

            if (!dataRow.IsNull("StartsAt"))
                StartsAt = dataRow.Field<DateTime>("StartsAt");

            if (!dataRow.IsNull("EndsAt"))
                EndsAt = dataRow.Field<DateTime>("EndsAt");

            if (!dataRow.IsNull("ChangeoverMinutes"))
                ChangeoverMinutes = dataRow.Field<double>("ChangeoverMinutes");

            if (!dataRow.IsNull("TaskMinutes"))
                TaskMinutes = dataRow.Field<double>("TaskMinutes");

            if (!dataRow.IsNull("TaskStatus"))
                TaskStatus = dataRow["TaskStatus"].ToString();

            if (!dataRow.IsNull("workcenterName"))
                WorkcenterName = dataRow["workcenterName"].ToString();

            if (!dataRow.IsNull("TaskEstimatedMeters"))
                TaskEstimatedMeters = Math.Ceiling(Convert.ToDecimal(dataRow["TaskEstimatedMeters"])).ToString();

            if (!dataRow.IsNull("SchedulingNotes"))
                SchedulingNotes = dataRow["SchedulingNotes"].ToString();

            if (dataRow.Table.Columns.Contains("StockStatus") && !dataRow.IsNull("StockStatus"))
                StockStatus = Convert.ToString(dataRow["StockStatus"]);

            #endregion

            #region Mandatory Fields

            if (!dataRow.IsNull("ScheduleId"))
                ScheduleId = dataRow["ScheduleId"].ToString();

            if (!dataRow.IsNull("IsPinned"))
                IsPinned = dataRow.Field<bool>("IsPinned");

            if (!dataRow.IsNull("PinType"))
                PinType = dataRow["PinType"].ToString();

            if (!dataRow.IsNull("LockStatus"))
                LockStatus = dataRow["LockStatus"].ToString();

            if (!dataRow.IsNull("LockType"))
                LockType = dataRow["LockType"].ToString();

            if (!dataRow.IsNull("IsOnPress"))
                IsOnPress = dataRow.Field<bool>("IsOnPress");

            if (dataRow.Table.Columns.Contains("Highlight"))
                if (!dataRow.IsNull("Highlight"))
                    Highlight = dataRow.Field<bool>("Highlight");

            if (!dataRow.IsNull("ManuallyScheduled"))
                ManuallyScheduled = Convert.ToInt32(dataRow["ManuallyScheduled"]) == 1;

            if (dataRow.Table.Columns.Contains("FeasibilityOverride"))
                if (!dataRow.IsNull("FeasibilityOverride"))
                    FeasibilityOverride = dataRow.Field<bool>("FeasibilityOverride");

            if (!dataRow.IsNull("IsRollingLock"))
                IsRollingLock = Convert.ToInt32(dataRow["IsRollingLock"]) == 1;

            if (!dataRow.IsNull("MasterRollNumber"))
                MasterRollNumber = dataRow["MasterRollNumber"].ToString();

            if (dataRow.Table.Columns.Contains("IsMasterRollGroup"))
                if (!dataRow.IsNull("IsMasterRollGroup"))
                    IsMasterRollGroup = dataRow.Field<bool>("IsMasterRollGroup");

            if (dataRow.Table.Columns.Contains("IsMasterRoll"))
                if (!dataRow.IsNull("IsMasterRoll"))
                    IsMasterRoll = dataRow.Field<bool>("IsMasterRoll");

            if (!dataRow.IsNull("EquipmentId"))
                EquipmentId = dataRow["EquipmentId"].ToString();

            if (!dataRow.IsNull("WorkcenterId"))
                WorkcenterId = dataRow["WorkcenterId"].ToString();


            if (!dataRow.IsNull("TaskString"))
            {
                TaskList = this.GetTaskList(dataRow["TaskString"].ToString());
                CanBeUnscheduled = !TaskList.Any(m => m.Status == "Complete" || m.IsOnPress);
            }
            else
            {
                TaskList = new List<TaskInformation>();
            }

            if (dataRow.Table.Columns.Contains("valuestreams") && !dataRow.IsNull("valuestreams"))
                ValueStreams = ScheduleTransalator.GetValueStreams(dataRow["valuestreams"].ToString());

            if (dataRow.Table.Columns.Contains("StagingRequirements") && !dataRow.IsNull("StagingRequirements"))
                StagingRequirements = ScheduleTransalator.GetValueStreams(dataRow["StagingRequirements"].ToString());

            ForcedGroup = dataRow.GetString("ForcedGroup");


            if (!dataRow.IsNull("RecordCreatedOn"))
                RecordCreatedOn = Convert.ToDateTime(dataRow["RecordCreatedOn"]);

            if (!dataRow.IsNull("TicketCategory"))
                TicketCategory = Convert.ToInt32(dataRow["TicketCategory"]);

            if (dataRow.Table.Columns.Contains("IsTicketGeneralNotePresent") && !dataRow.IsNull("IsTicketGeneralNotePresent"))
                IsTicketGeneralNotePresent = Convert.ToBoolean(dataRow["IsTicketGeneralNotePresent"]);

            if (dataRow.Table.Columns.Contains("WorkcenterMaterialTicketCategory") && !dataRow.IsNull("WorkcenterMaterialTicketCategory"))
                WorkcenterMaterialTicketCategory = Convert.ToInt32(dataRow["WorkcenterMaterialTicketCategory"]);

            if (dataRow.Table.Columns.Contains("IsCompletingOnTime") && !dataRow.IsNull("IsCompletingOnTime"))
                IsCompletingOnTime = Convert.ToInt32(dataRow["IsCompletingOnTime"]);

            if (dataRow.Table.Columns.Contains("IsFirstDay") && !dataRow.IsNull("IsFirstDay"))
                IsFirstDay = Convert.ToBoolean(dataRow["IsFirstDay"]);

            #endregion

        }

        private List<TaskInformation> GetTaskList(string taskString)
        {
            string[] tasksArray = taskString.Split("|||");

            List<TaskInformation> tasks = new List<TaskInformation>();

            foreach (var item in tasksArray)
            {
                var currentTaskInfo = item.Split("*,*");
                tasks.Add(new TaskInformation()
                {
                    TaskName = currentTaskInfo[0],
                    StartsAt = Convert.ToDateTime(currentTaskInfo[1]),
                    EndsAt = Convert.ToDateTime(currentTaskInfo[2]),
                    Status = currentTaskInfo[3],
                    IsOnPress = Convert.ToInt32(currentTaskInfo[4]) == 1,
                    IsEstMinsEdited = Convert.ToInt32(currentTaskInfo[5]) == 1,
                    IsStatusEdited = Convert.ToInt32(currentTaskInfo[6]) == 1
                });
            }

            return tasks;

        }

        internal class TaskInformation
        {
            public string TaskName { get; set; }
            public DateTime StartsAt { get; set; }
            public DateTime EndsAt { get; set; }
            public string Status { get; set; }
            public bool IsEstMinsEdited { get; set; }
            public bool IsStatusEdited { get; set; }
            public bool IsOnPress { get; set; }
        }
    }
}

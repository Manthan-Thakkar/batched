DECLARE @AssocQuery varchar(max) = 'SELECT [Number]      ,[FirstName]      ,[MidInitial]      ,[LastName]      ,[Addr1]      ,[Addr2]      ,[City]      ,[State_Province]      ,[Zip]      ,[Phone]      ,[SocSec]      ,[StartDate]      ,[EndDate]      ,[Dept]      ,[Birthday]      ,[Anniversary]      ,[AllotedVacation]      ,[AllotedHoliday]      ,[AllotedPersonal]      ,[TotVacation]      ,[TotHoliday]      ,[TotalPersonal]      ,[Mug]      ,[Notes]      ,[EmergContact]      ,[EmergPhone]      ,[Password]      ,[Group_Unused]      ,[CustomerEdit]      ,[AllotedSick]      ,[TotalSick]      ,[ProspectBtn]      ,[CustomerBtn]      ,[MFGRepsBtn]      ,[EstimateBtn]      ,[StockBtn]      ,[EquipmentBtn]      ,[ToolPricingBtn]      ,[ToolingBtn]      ,[KnowledgeBtn]      ,[SupplierBtn]      ,[AssociatesBtn]      ,[ConstantsBtn]      ,[ProductsBtn]      ,[TicketsBtn]      ,[PackingSlipBtn]      ,[InventoryBtn]      ,[PurchaseBtn]      ,[TicketStatBtn]      ,[POStatBtn]      ,[InvoicesBtn]      ,[CashReceiptsBtn]      ,[TimeCardsBtn]      ,[StockProductsBtn]      ,[SwitchUserBtn]      ,[PassWordBtn]      ,[AdditionalReports_Access]      ,[AddNewCustomer_Access]      ,[CustCreditApproval_Access]      ,[ConvertProspToCust_Access]      ,[QuickReport_Access]      ,[AccountingReports_Access]      ,[CustomerReports_Access]      ,[StockReports_Access]      ,[TickettReports_Access]      ,[TimeCardReports_Access]      ,[AllowDelete_Access]      ,[EditPopUp_Access]      ,[EditSuperReport_Access]      ,[ManageStockProduct_Access]      ,[CustomExport_Access]      ,[RebuildTikEst_v_Act_Access]      ,[StockInventory_Access]      ,[AccountingDelete_Access]      ,[AccountingReissue_Access]      ,[FC_Affiliates_Btn]      ,[FC_Projects_Btn]      ,[WebServer_Control_Btn]      ,[GetTonerUsage_Btn]      ,[PressTimeClock_Access]      ,[FinishTimeClock_Access]      ,[EditSchedule_Access]      ,[AR_Aging_Btn]      ,[AR_Maintenance_Btn]      ,[AccountingConstants_Btn]      ,[ChartOfAccounts_Btn]      ,[StockProdEstimatesBtn]      ,[StockProdTicketsBtn]      ,[StockProdTikStatsBtn]      ,[JournalEntryBtn]      ,[OverrideSoftClose_Access]      ,[FinancialStatementBtn]      ,[Dash_Display_Btn]      ,[API_Btn]      ,[AP_InvoiceBtn]      ,[OfficePhoneExtension]      ,[AP_AgingBtn]      ,[AP_Maintenance_Btn]      ,[AP_PrintChecksBtn]      ,[AP_HandChecksBtn]      ,[AP_CheckRegisterBtn]      ,[Display_Tool_Tips]      ,[E_Mail_Address]      ,[AP_BankReconciliationBtn]      ,[Access_4D_Write]      ,[Edit_4D_Write]      ,[ModifyAP_DueDates]      ,[ModifyAR_DueDates]      ,[Quality_Procedures_Btn]      ,[Return_Materials_Btn]      ,[NonConform_Materials_Btn]      ,[Complaint_Log_Btn]      ,[Documentation_Btn]      ,[Edit_PhraseList]      ,[Commissions_Btn]      ,[CannotEditSecurity]      ,[BudgetingNotes]      ,[ExecutiveTrends_Btn]      ,[IncludeInOutBoard]      ,[ViewInOutBoard]      ,[AdminInOutBoard]      ,[Rate_Class]      ,[ABC_Btn]      ,[EstPriceTunerPage]      ,[SMTP_Auth_UserName]      ,[SMTP_Auth_Password]      ,[Edit_Inactive]      ,[Hide_Commission]      ,[GL_Analysis_Btn]      ,[AccessAnyEstimate]      ,[Language_Btn]      ,[LanguageChoice]      ,[SalesTax_AccessToTaxSetUp]      ,[SalesTax_Btn]      ,[Access_RemoveTiksToInv]      ,[Access_ReverseInvoices]      ,[UEF_Btn]      ,[eTraxxLog_Btn]      ,[Product_Is_GroupUpdateOn]      ,[Country]      ,[DeDuplication_Btn]      ,[GL_Budgets_Btn]      ,[Edit_TicketBillings]      ,[Edit_ExchangeRates]      ,[PDF_Email_Report_Access]      ,[eTraxxConstants_Btn]      ,[Cust_Restrict_AR_Reports]      ,[Cust_Lock_Budgets_Tab]      ,[Cust_Restrict_AR_Tabs]      ,[ESC_Art]      ,[ESC_Proof]      ,[ESC_Plate]      ,[ESC_Tool]      ,[ESC_Ink]      ,[ESC_Stock]      ,[ESC_Press]      ,[ESC_Equip]      ,[ESC_Finish]      ,[ESC_Ship]      ,[ESC_TickStat]      ,[ESC_On]      ,[ESS_Ship]      ,[ESS_TickStat]      ,[ESS_On]      ,[Address_Add_Btn]      ,[Address_Class_Unlimited]      ,[Address_Edit_SalesTax]      ,[ElectronicPayments_Btn]      ,[Are_TimeCardPasswordsRequired]      ,[SupplierTab_Accounting]      ,[SupplierTab_InvHist]      ,[SupplierTab_AP_Bal]      ,[SupplierTab_eCommerce]      ,[SupplierTab_Activity]      ,[SupplierTab_POs]      ,[SupplierTab_Inventory]      ,[PressMetricsReport]      ,[ReceiveStockAtTimeClock]      ,[ViewRestrictedSuppliers]      ,[ViewTicketEstvAct]      ,[StockProductsReports]      ,[CommissionPercent]      ,[TimeClock_Btn]      ,[UnlockEstimates]      ,[JDF_Diagnostics]      ,[JDF_Constants]      ,[AssignGLDistProduct]      ,[Edit_TicketCommonPage]      ,[Send_Ticket_JDF]      ,[Remove_Ticket_JDF]      ,[ESC_Equip3]      ,[ESC_Equip4]      ,[AssignBOMs]      ,[EntryBy]      ,[ModifiedBy]      ,[EntryDate]      ,[ModifiedDate]      ,[EntryTime]      ,[ModifiedTime]      ,[eTraxxPrefs_x]      ,[Web_Enable_Login]      ,[SchedTicketStatus_Btn]      ,[SchedEmployeeStatus_Btn]      ,[MultiSchedule_Btn]      ,[SchedProductPrepressStatus_Btn]      ,[SchedCapacityPlanning_Btn]      ,[SchedAdvancedVisual_Btn]      ,[ServerAdminWindow]      ,[Foreign_Currencies_Btn]      ,[Estimate_Permitted_Forms]      ,[Inactive]      ,[Allow_MultipleDeletion]      ,[Allow_MultiDupe]      ,[ExternalDoc_Btn]      ,[Inspection_Btn]      ,[CompleteAll_Btn]      ,[PK_UUID]      ,[Dash_Goal_Display_Btn]      ,[Product_Permitted_Forms]      ,[Ticket_Permitted_Forms]      ,[Password_Expiration_date]      ,[Password_user_set]      ,[Password_Encrypted]      ,[iPodTouch_Btn]      ,[IMAP_sentFolderName]  FROM';
DECLARE @CustomerQuery varchar(max) = 'SELECT [Number]      ,[Company]      ,[Source]      ,[OrderReq]      ,[CreditStatus]      ,[DistributorNum]      ,[MFGRepNum]      ,[Notes]      ,[Phone]      ,[Fax]      ,[NextCallDate]      ,[Sales_Rep_No]      ,[Cust_Serv_No]      ,[SICNum]      ,[Customer]      ,[Distributor]      ,[DateOpened]      ,[OTSName]      ,[ITSName]      ,[Prosp_Customer]      ,[MFGRepComm]      ,[DistribName]      ,[ZipCode]      ,[Territory]      ,[Area]      ,[EntryDate]      ,[EntryBy]      ,[ModifyDate]      ,[ModifyBy]      ,[Inactive]      ,[Credit_Limit]      ,[BudgetingNotes]      ,[Internal_Customer]      ,[SoldToEndUser]      ,[EntryTime]      ,[ModifyTime]      ,[Type_of_Customer]      ,[Name1]      ,[Name2]      ,[Name3]      ,[Name4]      ,[PopUpName1]      ,[PopUpName2]      ,[CheckBoxName1]      ,[CheckBoxName2]      ,[MarketingNotes]      ,[PK_UUID]      ,[On_hold]  FROM';
DECLARE @EquipmentQuery varchar(max) = 'SELECT [Number]      ,[PType]      ,[MaxStockWidth]      ,[MinStockWidth]      ,[MaxColors]      ,[MaxTools]      ,[MaxPrintRepeat]      ,[MinPrintRepeat]      ,[MaxDieRepeat]      ,[MinDieRepeat]      ,[MaxPrintWidth]      ,[UVCoat]      ,[ConsecutiveNo]      ,[Turnbar]      ,[Sheeter]      ,[WIP_Rate]      ,[EstimateRate]      ,[Description]      ,[Notes]      ,[Inactive]      ,[ModifiedDate]      ,[ModifiedTime]      ,[ModifiedBy]      ,[EnteredBy]      ,[EnteredDate]      ,[EnteredTime]      ,[HP_Indigo_Model]      ,[Has_TurretRewinder]      ,[ID]      ,[PK_UUID]      ,[PressMfg]  FROM';
DECLARE @InvoiceQuery varchar(max) = 'SELECT [Number]      ,[TicketNum]      ,[CustomerName]      ,[CustomerNumber]      ,[Terms]      ,[TaxRate]      ,[STotal]      ,[Tax]      ,[Freight]      ,[MiscText]      ,[Misc]      ,[Total]      ,[Notes]      ,[County]      ,[TotalPaid]      ,[iDate]      ,[iType]      ,[PurchItems]      ,[Balance]      ,[Taxed]      ,[Discount]      ,[Closed]      ,[PlateCharge]      ,[ColorCharge]      ,[RInvoice]      ,[SalesRepNo]      ,[ZipCode]      ,[Territory]      ,[Area]      ,[PO_Art]      ,[PO_Plate]      ,[PO_Tool]      ,[PO_Generic]      ,[IsLocked]      ,[Tax_STotal]      ,[Tax_Plate]      ,[Tax_Color]      ,[Tax_PO]      ,[Tax_Misc]      ,[Tax_Freight]      ,[StockProdDiscnt]      ,[STotalDiscount]      ,[TaxRate2]      ,[Tax2]      ,[State_Province]      ,[EntryDate]      ,[EntryBy]      ,[ModifyDate]      ,[ModifyBy]      ,[AR_PostingStatus]      ,[Distributed_Amount]      ,[Undistributed_Amount]      ,[GL_PostingStatus]      ,[GL_Detail_ID]      ,[BilledOnMasterInvoiceNum]      ,[MasterInvoicePO_Num]      ,[Tax_TotalSaleAmount]      ,[Tax_ExemptSaleAmount]      ,[Tax_ResaleAmount]      ,[Tax_NonTaxableSalesAmount]      ,[Tax_TotalAmountSubjectToTax]      ,[Tax_SalesTaxAmount]      ,[TaxCB_STotal_i]      ,[TaxAmount_Total]      ,[EntryTime]      ,[ModifyTime]      ,[Enduser_ID]      ,[MiscChargeDesc1]      ,[MiscChargeDesc2]      ,[MiscChargeDesc3]      ,[MiscChargeDesc4]      ,[MiscCharge1]      ,[MiscCharge2]      ,[MiscCharge3]      ,[MiscCharge4]      ,[PK_UUID]  FROM';
DECLARE @POQuery varchar(max) = 'SELECT [PONumber]      ,[TicketNum]      ,[PODate]      ,[DateReq]      ,[Received]      ,[Description]      ,[SupplierNum]      ,[OrderStockNum]      ,[MFGSpec]      ,[Quantity]      ,[ShipVia]      ,[QCOType]      ,[POType]      ,[MasterWidth]      ,[ToolNum]      ,[FaceColor]      ,[FaceCaliper]      ,[Adhesive]      ,[CostMSI]      ,[Notes]      ,[TotalPO]      ,[LinerCaliper]      ,[FaceStock]      ,[SellPrice]      ,[Supplier]      ,[Invoiced]      ,[InvoiceNum]      ,[Closed]      ,[ActShipDate]      ,[PhoneNo]      ,[EntryDate]      ,[EntryBy]      ,[ModifyDate]      ,[ModifyBy]      ,[ShipCountry]      ,[Ship_Address_ID]      ,[ShipName]      ,[ShipAddr1]      ,[ShipAddr2]      ,[ShipCity]      ,[ShipState]      ,[ShipZip]      ,[ShipAttention]      ,[TimeDue]      ,[Status]      ,[PO_Subtotal]      ,[Tax]      ,[Freight]      ,[Received_Total]      ,[RequestedDeliveryDate]      ,[EntryTime]      ,[ModifyTime]      ,[TaxRegionID]      ,[TaxRegionRate]      ,[Received_Tax]      ,[Price_Weight]      ,[Inventory_Location]      ,[BillTo_AddressID]      ,[BillTo_Name]      ,[BillTo_Addr1]      ,[BillTo_Addr2]      ,[BillTo_City]      ,[BillTo_State]      ,[BillTo_Zip]      ,[BillTo_Country]      ,[BillTo_Attention]      ,[PK_UUID]      ,[Tag]';
DECLARE @RollStockQuery varchar(max) = 'SELECT [IDNumber]      ,[StockNum]      ,[PONumber]      ,[AllocTikNum]      ,[UsedTikNum]      ,[Width]      ,[FootLength]      ,[Location]      ,[Description]      ,[DeleteFlag]      ,[RollNum]      ,[StkDate]      ,[StkUsed]      ,[Slitted]      ,[SlitFootage]      ,[CostMSI]      ,[CostOfRoll]      ,[DateRollUsed]      ,[CreatedDate]      ,[DateStamp]      ,[Used_TimeStamp]      ,[Orig_RollID]      ,[Press]      ,[PK_UUID]      ,[TAG]  FROM';
DECLARE @StockQuery varchar(max) = 'SELECT [StockNum]      ,[Classification]      ,[SupplierNum]      ,[MFGSpecNum]      ,[MasterWidth]      ,[CostMSI]      ,[FaceStock]      ,[FaceColor]      ,[FaceCaliper]      ,[LinerCaliper]      ,[Adhesive]      ,[AdhClass]      ,[TotalInvMSI]      ,[InventoryCost]      ,[ULRecognized]      ,[CSACertified]      ,[TopCoat]      ,[Notes]      ,[Inactive]      ,[SupplierName]      ,[Location]      ,[Caliper]      ,[EnteredBy]      ,[ModifiedBy]      ,[EnteredDate]      ,[ModifiedDate]      ,[EnteredTime]      ,[ModifiedTime]      ,[InvMSI_Minimum]      ,[InvMSI_Maximum]      ,[StockSubstitute_1]      ,[StockSubstitute_2]      ,[StockSubstitute_3]      ,[PK_UUID]  FROM'
DECLARE @TicketQuery varchar(max) = 'SELECT [Number]      ,[OrderDate]      ,[Ship_by_Date]      ,[ArtStat]      ,[ProofStat]      ,[PlateStat]      ,[ToolStat]      ,[PressStat]      ,[FinishStat]      ,[ShipStat]      ,[ArtDone]      ,[ProofDone]      ,[PlateDone]      ,[ToolsIn]      ,[StockIn]      ,[PressDone]      ,[FinishDone]      ,[NoPlateChanges]      ,[PrevJobNum]      ,[GeneralDescr]      ,[EstTime]      ,[SizeAcross]      ,[SizeAround]      ,[ColSpace]      ,[RowSpace]      ,[LabelRepeat]      ,[NoAcross]      ,[NoArounPlate]      ,[NoColorChanges]      ,[FinishType]      ,[Pinfeed]      ,[LabelsPer_]      ,[NoLabAcrossFin]      ,[CoreSize]      ,[FinalUnwind]      ,[Tab]      ,[Press]      ,[MainTool]      ,[CustPONum]      ,[TurnBar]      ,[ColumnPerf]      ,[RowPerf]      ,[OverRun]      ,[CustomerNum]      ,[EndUserNum]      ,[StockNum1]      ,[StockWidth1]      ,[EstFootage]      ,[StockNum2]      ,[StockWidth2]      ,[ToolNo2]      ,[StockNum3]      ,[StockWidth3]      ,[Tool2Descr]      ,[ITSAssocNum]      ,[OTSAssocNum]      ,[ShipVia]      ,[ShippingInstruc]      ,[ShipAttn]      ,[Notes]      ,[DateDone]      ,[ShipAttn_EmailAddress]      ,[ShipLocation]      ,[ShipAddr1]      ,[ShipAddr2]      ,[ShipCity]      ,[ShipSt]      ,[ShipZip]      ,[BillLocation]      ,[BillAddr1]      ,[BillAddr2]      ,[BillCity]      ,[BillZip]      ,[BillCountry]      ,[ShippingStatus]      ,[ShipCountry]      ,[StockTicketType]      ,[Stock_Allocated]      ,[EndUserPO]      ,[CustomerName]      ,[ToolNo3]      ,[Tool3Descr]      ,[ToolNo4]      ,[Tool4Descr]      ,[ToolNo5]      ,[Tool5Descr]      ,[DateShipped]      ,[OTSName]      ,[TicketType]      ,[TicQuantity]      ,[ITSName]      ,[ActFootage]      ,[EstMRHrs]      ,[ActMRHrs]      ,[EstWuHrs]      ,[ActWuHrs]      ,[EstRunHrs]      ,[ActRunHrs]      ,[EstFinHrs]      ,[ActualFanfoldHours]      ,[EstPackHrs]      ,[ActPackHrs]      ,[EstPressSpd]      ,[ActPressSpd]      ,[ActQuantity]      ,[Act_MakeReady_Footage]      ,[Is_Ink_In]      ,[Ink_Status]      ,[EstTotal]      ,[ActTotalCost]      ,[EstStockCost]      ,[ActStockCost]      ,[EstFinMaterial]      ,[ActFinMaterial]      ,[Shape]      ,[TabPosition]      ,[LastModified]      ,[StockDesc1]      ,[StockDesc2]      ,[StockDesc3]      ,[EndUserName]      ,[MFGRepName]      ,[BillState]      ,[CustContact]      ,[CSA]      ,[UL]      ,[ConsecNo]      ,[POTotal]      ,[TicketStatus]      ,[PlateChangeCost]      ,[ColorChangeCost]      ,[MiscChargeDesc]      ,[MiscCharge]      ,[CoreType]      ,[RollLength]      ,[RollUnit]      ,[PriceMode]      ,[Priority]      ,[OutsideDiameter]      ,[FinishNotes]      ,[EstPressTime]      ,[RewindEquipNum]      ,[RewindEquipNam]      ,[SubTicket]      ,[EntryBy]      ,[EntryDate]      ,[Terms]      ,[ActualPressHours]      ,[ActualTotalHours]      ,[ActualPressRate]      ,[ActualPressCost]      ,[ActualRewindingRate]      ,[ActualRewindingCost]      ,[ActualFanfoldRate]      ,[ActualFanFoldCost]      ,[ActualPackagingRate]      ,[ActualPackingLaborCost]      ,[ActualNumOfStockRolls]      ,[ActualFootage_StockRolls]      ,[ActualMSI_StockRolls]      ,[ActualBillings_NetOfSalesTax]      ,[ActualGrossMargin_Dollars]      ,[ActualGrossMargin_Percent]      ,[ActualRewindingHours]      ,[ActualTotalFinishing]      ,[ActualTotalLaborCosts]      ,[ActualTotalPOCosts]      ,[ActualTotalMatAndFreightCost]      ,[Est_SetupFootage]      ,[Est_SpoilFootage]      ,[ShipCounty]      ,[Est_v_Act_Notes]      ,[EstPostPressHours]      ,[ActPostPressHours]      ,[Act_OTHER_Hours]      ,[ActualPostPressLaborCost]      ,[StockNotes]      ,[SlitOnRewind]      ,[ActualOtherLaborCost]      ,[Ship_Address_ID]      ,[Ship_TaxRegion_ID]      ,[EntryTime]      ,[ModifyTime]      ,[ModifyBy]      ,[ModifyDate]      ,[Equip_ID]      ,[Equip_MakeReadyHours]      ,[Equip_WashUpHours]      ,[Equip_EstSpeed]      ,[Equip_EstRunHrs]      ,[Equip_Actual_MR_Hours]      ,[Equip_Actual_MR_Length]      ,[Equip_Actual_Length]      ,[Equip_Actual_Run_Hours]      ,[Equip_Actual_WU_Hours]      ,[Equip_Actual_Speed]      ,[Equip_EstTime]      ,[Equip_Actual_Hours]      ,[Equip_Actual_Rate]      ,[Equip_Actual_Cost]      ,[Equip_Status]      ,[Equip_Done]      ,[Due_on_Site_Date]      ,[CreditHoldOverride]      ,[Use_TurretRewinder]      ,[ShrinkSleeve_OverLap]      ,[ShrinkSleeve_LayFlat]      ,[ShrinkSleeve_CutHeight]      ,[BackStage_ColorStrategy]      ,[BackStage_SmartMarkSet]      ,[Equip3_ID]      ,[Equip3_MakeReadyHours]      ,[Equip3_WashUpHours]      ,[Equip3_EstSpeed]      ,[Equip3_EstRunHrs]      ,[Equip3_EstTime]      ,[Equip3_Actual_Length]      ,[Equip3_Actual_MR_Length]      ,[Equip3_Actual_Speed]      ,[Equip3_Actual_MR_Hours]      ,[Equip3_Actual_Run_Hours]      ,[Equip3_Actual_WU_Hours]      ,[Equip3_Actual_Hours]      ,[Equip3_Actual_Rate]      ,[Equip3_Actual_Cost]      ,[Equip3_Status]      ,[Equip3_Done]      ,[Equip4_ID]      ,[Equip4_MakeReadyHours]      ,[Equip4_WashUpHours]      ,[Equip4_EstSpeed]      ,[Equip4_EstRunHrs]      ,[Equip4_EstTime]      ,[Equip4_Actual_Length]      ,[Equip4_Actual_MR_Length]      ,[Equip4_Actual_Speed]      ,[Equip4_Actual_MR_Hours]      ,[Equip4_Actual_Run_Hours]      ,[Equip4_Actual_WU_Hours]      ,[Equip4_Actual_Hours]      ,[Equip4_Actual_Rate]      ,[Equip4_Actual_Cost]      ,[Equip4_Status]      ,[Equip4_Done]      ,[Equip_NoAcross]      ,[Equip_NoAround]      ,[Equip_NumUp_Multiplier]      ,[Equip3_NoAcross]      ,[Equip3_NoAround]      ,[Equip3_NumUp_Multiplier]      ,[Equip4_NoAcross]      ,[Equip4_NoAround]      ,[Equip4_NumUp_Multiplier]      ,[Tool_NumberAround]      ,[Roto_Quote_Number]      ,[ID]      ,[Customer_Total]      ,[MiscChargeDesc1]      ,[MiscChargeDesc2]      ,[MiscChargeDesc3]      ,[MiscChargeDesc4]      ,[MiscCharge1]      ,[MiscCharge2]      ,[MiscCharge3]      ,[MiscCharge4]      ,[Frames_Lead_In]      ,[Frames_Lead_Out]      ,[PK_UUID]      ,[IsPrintReversed]      ,[FlexPack_Type]      ,[FlexPack_Height]      ,[FlexPack_Gusset]      ,[FlexPack_LeftTrim]      ,[FlexPack_RightTrim]      ,[INTERNET_SUBMISSION] FROM'
DECLARE @TimecardQuery varchar(max) = 'SELECT [ID],[AssocNo],[Ticket_No],[WorkOperation],[SDate],[EDate],[STime],[ETime],[Elapsed],[Closed],[FinishedPieces],[PressNo],[FootUsed],[Totalizer],[Notes],[OffPress],[Packaged],[Labels_Est_to_Produce],[Labels_Act_Net],[Labels_Act_Waste],[Labels_Act_Gross],[Length_Est_Required],[Length_Act_Net],[Length_Act_Waste],[Length_Act_Gross],[Speed_Est_Length_Min],[Speed_Act_Length_Min],[Speed_Act_Labels_Min],[Time_Est_Total],[SC_MasterEvent_Code],[SC_Event_ID],[PK_UUID], '''' as [UpdateTimeDateStamp], '''' as [Tag]  FROM'
DECLARE @ToolingQuery varchar(max) = 'SELECT [Number]      ,[Flexo_HotS]      ,[DieSize]      ,[SizeAcross]      ,[SizeAround]      ,[ColSpace]      ,[RowSpace]      ,[NoAcross]      ,[NoAround]      ,[LabelRepeat]      ,[GearTeeth]      ,[Pitch]      ,[Shape]      ,[LinerCaliper]      ,[Revolutions]      ,[Notes]      ,[Quantity]      ,[Location]      ,[Inactive]      ,[EnteredBy]      ,[ModifiedBy]      ,[EnteredDate]      ,[ModifiedDate]      ,[EnteredTime]      ,[ModifiedTime]      ,[PK_UUID]      ,[ToolIn]  FROM';
DECLARE @TenantName varchar(100) = 'Demo Tenant';


UPDATE odsq
set odsq.QueryText = REPLACE(odsq. QueryText,'SELECT * FROM',@AssocQuery)
FROM [batched].[dbo].[OdbcDataSourceQuery] odsq
INNER JOIN DataSource ds on ds.ID = odsq.DataSourceId
inner join Job j on ds.JobId = j.ID
inner join Agent a on j.AgentId = a.ID
inner join Tenant t on a.TenantId = t.ID
  WHERE odsq.QueryText like '%SELECT * FROM%'
and t.IsEnabled = 1
and odsq.DatasetName = 'Associate'
and (t.Name = @TenantName OR @TenantName IS NULL)


UPDATE odsq
set odsq.QueryText = REPLACE(odsq. QueryText,'SELECT * FROM',@EquipmentQuery)
FROM [batched].[dbo].[OdbcDataSourceQuery] odsq
INNER JOIN DataSource ds on ds.ID = odsq.DataSourceId
inner join Job j on ds.JobId = j.ID
inner join Agent a on j.AgentId = a.ID
inner join Tenant t on a.TenantId = t.ID
  WHERE odsq.QueryText like '%SELECT * FROM%'
and t.IsEnabled = 1
and odsq.DatasetName = 'Equipment'
and (t.Name = @TenantName OR @TenantName IS NULL)


UPDATE odsq
set odsq.QueryText = REPLACE(odsq. QueryText,'SELECT * FROM',@POQuery)
FROM [batched].[dbo].[OdbcDataSourceQuery] odsq
INNER JOIN DataSource ds on ds.ID = odsq.DataSourceId
inner join Job j on ds.JobId = j.ID
inner join Agent a on j.AgentId = a.ID
inner join Tenant t on a.TenantId = t.ID
  WHERE odsq.QueryText like '%SELECT * FROM%'
and t.IsEnabled = 1
and odsq.DatasetName = 'PurchaseOrder'
and (t.Name = @TenantName OR @TenantName IS NULL)


UPDATE odsq
set odsq.QueryText = REPLACE(odsq. QueryText,'SELECT * FROM',@RollStockQuery)
FROM [batched].[dbo].[OdbcDataSourceQuery] odsq
INNER JOIN DataSource ds on ds.ID = odsq.DataSourceId
inner join Job j on ds.JobId = j.ID
inner join Agent a on j.AgentId = a.ID
inner join Tenant t on a.TenantId = t.ID
  WHERE odsq.QueryText like '%SELECT * FROM%'
and t.IsEnabled = 1
and odsq.DatasetName = 'RollStock'
and (t.Name = @TenantName OR @TenantName IS NULL)


UPDATE odsq
set odsq.QueryText = REPLACE(odsq. QueryText,'SELECT * FROM',@StockQuery)
FROM [batched].[dbo].[OdbcDataSourceQuery] odsq
INNER JOIN DataSource ds on ds.ID = odsq.DataSourceId
inner join Job j on ds.JobId = j.ID
inner join Agent a on j.AgentId = a.ID
inner join Tenant t on a.TenantId = t.ID
  WHERE odsq.QueryText like '%SELECT * FROM%'
and t.IsEnabled = 1
and odsq.DatasetName = 'Stock'
and (t.Name = @TenantName OR @TenantName IS NULL)


UPDATE odsq
set odsq.QueryText = REPLACE(odsq. QueryText,'SELECT * FROM',@TicketQuery)
FROM [batched].[dbo].[OdbcDataSourceQuery] odsq
INNER JOIN DataSource ds on ds.ID = odsq.DataSourceId
inner join Job j on ds.JobId = j.ID
inner join Agent a on j.AgentId = a.ID
inner join Tenant t on a.TenantId = t.ID
  WHERE odsq.QueryText like '%SELECT * FROM%'
and t.IsEnabled = 1
and odsq.DatasetName = 'Ticket'
and (t.Name = @TenantName OR @TenantName IS NULL)


UPDATE odsq
set odsq.QueryText = REPLACE(odsq. QueryText,'SELECT * FROM',@ToolingQuery)
FROM [batched].[dbo].[OdbcDataSourceQuery] odsq
INNER JOIN DataSource ds on ds.ID = odsq.DataSourceId
inner join Job j on ds.JobId = j.ID
inner join Agent a on j.AgentId = a.ID
inner join Tenant t on a.TenantId = t.ID
  WHERE odsq.QueryText like '%SELECT * FROM%'
and t.IsEnabled = 1
and odsq.DatasetName ='Tooling'
and (t.Name = @TenantName OR @TenantName IS NULL)


UPDATE odsq
set odsq.QueryText = REPLACE(odsq. QueryText,'SELECT * FROM',@CustomerQuery)
FROM [batched].[dbo].[OdbcDataSourceQuery] odsq
INNER JOIN DataSource ds on ds.ID = odsq.DataSourceId
inner join Job j on ds.JobId = j.ID
inner join Agent a on j.AgentId = a.ID
inner join Tenant t on a.TenantId = t.ID
  WHERE odsq.QueryText like '%SELECT * FROM%'
and t.IsEnabled = 1
and odsq.DatasetName = 'Customer'
and (t.Name = @TenantName OR @TenantName IS NULL)

UPDATE odsq
set odsq.QueryText = REPLACE(odsq. QueryText,'SELECT * FROM',@TimecardQuery) 
FROM [batched].[dbo].[OdbcDataSourceQuery] odsq
INNER JOIN DataSource ds on ds.ID = odsq.DataSourceId
inner join Job j on ds.JobId = j.ID
inner join Agent a on j.AgentId = a.ID
inner join Tenant t on a.TenantId = t.ID
  WHERE odsq.QueryText like '%SELECT * FROM%'
and t.IsEnabled = 1
and odsq.DatasetName = 'TimeCard'
and (t.Name = @TenantName OR @TenantName IS NULL)

UPDATE odsq
set odsq.QueryText = REPLACE(odsq.QueryText,'SELECT * FROM',@InvoiceQuery)
FROM [batched].[dbo].[OdbcDataSourceQuery] odsq
INNER JOIN DataSource ds on ds.ID = odsq.DataSourceId
inner join Job j on ds.JobId = j.ID
inner join Agent a on j.AgentId = a.ID
inner join Tenant t on a.TenantId = t.ID
  WHERE odsq.QueryText like '%SELECT * FROM%'
and t.IsEnabled = 1
and odsq.DatasetName = 'Invoice'
and (t.Name = @TenantName OR @TenantName IS NULL)


UPDATE odsq
set odsq.QueryText = REPLACE(odsq.QueryText,' FROM',','''' as [UpdateTimeDateStamp] FROM')
FROM [batched].[dbo].[OdbcDataSourceQuery] odsq
INNER JOIN DataSource ds on ds.ID = odsq.DataSourceId
inner join Job j on ds.JobId = j.ID
inner join Agent a on j.AgentId = a.ID
inner join Tenant t on a.TenantId = t.ID
inner join ERPMaster erp on t.ERPId = erp.Id
WHERE erp.Name = 'LabelTraxx'
and QueryText NOT LIKE '%UpdateTimeDateStamp%'
and t.IsEnabled = 1
and odsq.DatasetName in ('Equipment',
'ProductColor',
'Product',
'PurchaseOrder',
'RollStock',
'Stock',
'StockProduct',
'Ticket',
'TicketItem',
'Ticket_UserDefined',
'Tooling',
'Customer',
'Associate',
'TimeCard',
'Invoice',
'PO_Item_Stock')
and (t.Name = @TenantName OR @TenantName IS NULL)
--Ticket Attribute Values
ALTER TABLE TicketAttributeValues_temp Drop Constraint PK_TicketAttributeValues_temp;
GO
ALTER TABLE TicketAttributeValues_temp Add Constraint PK_TicketAttributeValues_temp PRIMARY KEY CLUSTERED (ID);
GO
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_TicketAttributeValues_temp_TicketId_Name'
      AND object_id = OBJECT_ID('dbo.TicketAttributeValues_temp')
)
BEGIN
	CREATE NONCLUSTERED INDEX [IX_TicketAttributeValues_temp_TicketId_Name] ON [dbo].[TicketAttributeValues_temp]
	(
		[TicketId] ASC,
		[Name] ASC
	)
	INCLUDE([Value],[DataType],[CreatedOn],[ModifiedOn]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
	;
END
GO
---------------LAGS AND DELAY FIX------------------------------
IF EXISTS (SELECT * 
           FROM INFORMATION_SCHEMA.COLUMNS 
           WHERE TABLE_NAME = 'TicketTask' 
             AND COLUMN_NAME = 'Lag' 
             AND DATA_TYPE = 'int')
BEGIN
    ALTER TABLE TicketTask
    ALTER COLUMN Lag REAL NULL
END

GO

IF EXISTS (SELECT * 
           FROM INFORMATION_SCHEMA.COLUMNS 
           WHERE TABLE_NAME = 'TicketTask' 
             AND COLUMN_NAME = 'Delay' 
             AND DATA_TYPE = 'int')
BEGIN
    ALTER TABLE TicketTask
    ALTER COLUMN Delay REAL NULL
END

GO

IF EXISTS (SELECT * 
           FROM INFORMATION_SCHEMA.COLUMNS 
           WHERE TABLE_NAME = 'TicketTask_temp' 
             AND COLUMN_NAME = 'Lag' 
             AND DATA_TYPE = 'int')
BEGIN
    ALTER TABLE TicketTask_temp
    ALTER COLUMN Lag REAL NULL
END

GO

IF EXISTS (SELECT * 
           FROM INFORMATION_SCHEMA.COLUMNS 
           WHERE TABLE_NAME = 'TicketTask_temp' 
             AND COLUMN_NAME = 'Delay' 
             AND DATA_TYPE = 'int')
BEGIN
    ALTER TABLE TicketTask_temp
    ALTER COLUMN Delay REAL NULL
END

GO
---------------TASK NAME FIX------------------------------
IF  EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_TicketTask_TicketId_TaskName'
      AND object_id = OBJECT_ID('dbo.TicketTask')
)
DROP INDEX [IX_TicketTask_TicketId_TaskName] ON [dbo].[TicketTask]
GO

IF EXISTS (SELECT * 
           FROM INFORMATION_SCHEMA.COLUMNS 
           WHERE TABLE_NAME = 'TicketTask' 
             AND COLUMN_NAME = 'TaskName')
BEGIN
    ALTER TABLE TicketTask
    ALTER COLUMN TaskName NVARCHAR(510) NOT NULL
END
GO
------
DROP TABLE [dbo].[TicketTask_temp]

GO

/****** Object:  Table [dbo].[TicketTask_Temp]    Script Date: 20-06-2024 17:18:55 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[TicketTask_Temp](
	[Id] [varchar](36) NOT NULL,
	[TicketId] [varchar](36) NOT NULL,
	[TaskName] [nvarchar](510) NOT NULL,
	[Sequence] [smallint] NOT NULL,
	[OriginalEquipmentId] [varchar](36) NOT NULL,
	[ActualEquipmentId] [varchar](36) NULL,
	[WorkcenterId] [varchar](36) NULL,
	[IsComplete] [bit] NOT NULL,
	[EstMakeReadyHours] [real] NULL,
	[EstWashupHours] [real] NULL,
	[EstRunHours] [real] NULL,
	[EstTotalHours] [real] NULL,
	[EstMaxDueDateTime] [datetime] NULL,
	[CreatedOn] [datetime] NOT NULL,
	[ModifiedOn] [datetime] NOT NULL,
	[Pass] [int] NULL,
	[DoublePassJob] [int] NULL,
	[DoublePass_ReInsertionFlag] [int] NULL,
	[EstMeters] [real] NULL,
	[IsProductionReady] [bit] NOT NULL,
	[Lag] [real] NULL,
	[Delay] [real] NULL,
	[DependentSourceTicketId] [nvarchar](255) NULL,
	[EnforceTaskDependency] [bit] NOT NULL,
	[TaskStockStatus] [varchar](64) NULL,
	[MasterRollNumber] [varchar](255) NULL,
	[TaskClassification] [nvarchar](1090) NULL,
	[MasterRollClassification] [nvarchar](1701) NULL,
	[ActualEstTotalHours] [real] NULL,
 CONSTRAINT [PK_TicketTask_TempId] PRIMARY KEY NONCLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[TicketTask_Temp] ADD  DEFAULT ((0)) FOR [EnforceTaskDependency]
GO

ALTER TABLE [dbo].[TicketTask_Temp]  WITH CHECK ADD  CONSTRAINT [FK_TicketTask_Temp_Actual_EquipmentMasterId] FOREIGN KEY([ActualEquipmentId])
REFERENCES [dbo].[EquipmentMaster] ([ID])
GO
GO

ALTER TABLE [dbo].[TicketTask_Temp]  WITH CHECK ADD  CONSTRAINT [FK_TicketTask_Temp_Original_EquipmentMasterId] FOREIGN KEY([OriginalEquipmentId])
REFERENCES [dbo].[EquipmentMaster] ([ID])
GO


ALTER TABLE [dbo].[TicketTask_Temp]  WITH CHECK ADD  CONSTRAINT [FK_TicketTask_Temp_TicketMasterId] FOREIGN KEY([TicketId])
REFERENCES [dbo].[TicketMaster] ([ID])
GO

--add index
CREATE NONCLUSTERED INDEX [IX_TicketTask_temp_TicketId_TaskName] ON [dbo].[TicketTask_temp]
(
	[TicketId] ASC
)
INCLUDE([TaskName],[Sequence],[IsComplete],[EstMaxDueDateTime]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO



--------Unassigned Jobs---------
ALTER TABLE UnassignedJobs_temp Drop Constraint PK_UnassignedJobs_temp;
GO
ALTER TABLE UnassignedJobs_temp Add Constraint PK_UnassignedJobs_temp PRIMARY KEY CLUSTERED (ID);
GO
-----------TSA Temp table
DROP TABLE [dbo].[TicketStockAvailability_temp]
GO

/****** Object:  Table [dbo].[TicketStockAvailability_temp]    Script Date: 20-06-2024 17:28:59 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[TicketStockAvailability_temp](
	[Id] [varchar](36) NOT NULL,
	[TicketId] [varchar](36) NOT NULL,
	[FacilityId] [varchar](36) NOT NULL,
	[TaskDueDateTime] [datetime] NOT NULL,
	[OriginalStockMaterialId] [varchar](36) NOT NULL,
	[OriginalWidth] [real] NOT NULL,
	[StockStatus] [varchar](36) NOT NULL,
	[FirstAvailableTime] [datetime] NULL,
	[ActualStockMaterialId] [varchar](36) NULL,
	[ActualWidth] [real] NULL,
	[CreatedOnUTC] [datetime] NOT NULL,
	[ModifiedOnUTC] [datetime] NOT NULL,
	[OriginalLength] [real] NULL,
	[ActualLength] [real] NULL,
	[RequiredQuantity] [real] NULL,
	[TaskName] [nvarchar](255) NOT NULL,
	[Sequence] [smallint] NOT NULL,
 CONSTRAINT [PK_TicketStockAvailability_temp] PRIMARY KEY NONCLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[TicketStockAvailability_Temp] ADD  DEFAULT ((0)) FOR [RequiredQuantity]
GO

ALTER TABLE [dbo].[TicketStockAvailability_Temp] ADD  DEFAULT ('') FOR [TaskName]
GO

ALTER TABLE [dbo].[TicketStockAvailability_Temp] ADD  DEFAULT ((0)) FOR [Sequence]
GO

ALTER TABLE [dbo].[TicketStockAvailability_Temp]  WITH CHECK ADD  CONSTRAINT [FK_TicketStockAvailability_Temp_StockMaterial_ActualStockMaterialId] FOREIGN KEY([ActualStockMaterialId])
REFERENCES [dbo].[StockMaterial] ([Id])
GO

ALTER TABLE [dbo].[TicketStockAvailability_Temp]  WITH CHECK ADD  CONSTRAINT [FK_TicketStockAvailability_Temp_StockMaterial_OriginalStockMaterialId] FOREIGN KEY([OriginalStockMaterialId])
REFERENCES [dbo].[StockMaterial] ([Id])
GO

ALTER TABLE [dbo].[TicketStockAvailability_Temp]  WITH CHECK ADD  CONSTRAINT [FK_TicketStockAvailability_Temp_TicketMaster_TicketId] FOREIGN KEY([TicketId])
REFERENCES [dbo].[TicketMaster] ([ID])
GO



CREATE NONCLUSTERED INDEX [IX_TicketStockAvailability_temp_TicketId_FacilityId_StockId_Width_Length] ON [dbo].[TicketStockAvailability_temp]
(
	[TicketId] ASC
)
INCLUDE([FacilityId],[ActualStockMaterialId],[ActualWidth],[ActualLength]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
--TSA other tables
DROP TABLE [dbo].[TicketStockAvailabilityRawMaterialTickets_temp]
GO

/****** Object:  Table [dbo].[TicketStockAvailabilityRawMaterialTickets]    Script Date: 3/14/2024 1:00:04 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[TicketStockAvailabilityRawMaterialTickets_temp](
	[Id] [varchar](36) NOT NULL,
	[TicketStockAvailabilityId] [varchar](36) NOT NULL,
	[QuantityUsed] [real] NOT NULL,
	[CreatedOnUTC] [datetime] NOT NULL,
	[ModifiedOnUTC] [datetime] NOT NULL,
	[TicketItemInfoId] [varchar](36) NULL,
 CONSTRAINT [PK_TicketStockAvailabilityRawMaterialTickets_temp] PRIMARY KEY NONCLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[TicketStockAvailabilityRawMaterialTickets_temp]  WITH CHECK ADD  CONSTRAINT [FK_TSA_temp_TicketItemInfo_TicketItemInfoId] FOREIGN KEY([TicketItemInfoId])
REFERENCES [dbo].[TicketItemInfo] ([Id])
GO

ALTER TABLE [dbo].[TicketStockAvailabilityRawMaterialTickets_temp]  WITH CHECK ADD  CONSTRAINT [FK_TSA_temp_TicketStockAvailabilityId]
FOREIGN KEY([TicketStockAvailabilityId])
REFERENCES [dbo].[TicketStockAvailability] ([Id])
GO
-----
DROP TABLE [dbo].[TicketStockAvailabilityPO_temp]
GO

/****** Object:  Table [dbo].[TicketStockAvailabilityPO]    Script Date: 3/14/2024 1:15:34 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[TicketStockAvailabilityPO_temp](
	[Id] [varchar](36) NOT NULL,
	[PurchaseOrderItemId] [varchar](36) NOT NULL,
	[TicketStockAvailabilityId] [varchar](36) NOT NULL,
	[QuantityUsed] [real] NOT NULL,
	[CreatedOnUTC] [datetime] NOT NULL,
	[ModifiedOnUTC] [datetime] NOT NULL,
 CONSTRAINT [PK_TicketStockAvailabilityPO_temp] PRIMARY KEY NONCLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO


ALTER TABLE [dbo].[TicketStockAvailabilityPO_temp]  WITH CHECK ADD  CONSTRAINT [FK_PurchaseOrderItem_temp_PurchaseOrderItemId] FOREIGN KEY([PurchaseOrderItemId])
REFERENCES [dbo].[PurchaseOrderItem] ([Id])
GO

ALTER TABLE [dbo].[TicketStockAvailabilityPO_temp]  WITH CHECK ADD  CONSTRAINT [FK_TicketStockAvailabilityPO_temp_TicketStockAvailabilityId]
FOREIGN KEY([TicketStockAvailabilityId])
REFERENCES [dbo].[TicketStockAvailability] ([Id])
GO

--
-- Feasible Routes
ALTER TABLE FeasibleRoutes_temp Drop Constraint PK_FeasibleRoutes_temp;
GO
ALTER TABLE FeasibleRoutes_temp Add Constraint PK_FeasibleRoutes_temp PRIMARY KEY CLUSTERED (ID);
GO
-- Changeover Minutes

IF EXISTS (SELECT 1
           FROM INFORMATION_SCHEMA.COLUMNS 
           WHERE TABLE_NAME = 'ChangeoverMinutes_temp' 
             AND COLUMN_NAME = 'Description' 
             AND DATA_TYPE = 'nvarchar')
BEGIN
    ALTER TABLE ChangeoverMinutes_temp
    ALTER COLUMN Description VARCHAR(4000) NULL
END
GO

IF EXISTS (SELECT 1
           FROM INFORMATION_SCHEMA.COLUMNS 
           WHERE TABLE_NAME = 'ChangeoverMinutes' 
             AND COLUMN_NAME = 'Description' 
             AND DATA_TYPE = 'nvarchar')
BEGIN
    ALTER TABLE ChangeoverMinutes
    ALTER COLUMN Description VARCHAR(4000) NULL
END
GO
--exec sp_help Changeoverminutes
IF EXISTS(SELECT i.type_desc AS IndexType
FROM 
    sys.key_constraints kc
    INNER JOIN sys.tables t ON kc.parent_object_id = t.object_id
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    LEFT JOIN sys.indexes i ON kc.parent_object_id = i.object_id AND kc.unique_index_id = i.index_id
WHERE 
    kc.name = 'PK__Changeov__3214EC273B470047'
    AND t.name = 'ChangeoverMinutes'
    AND s.name = 'dbo')
BEGIN
	ALTER TABLE ChangeoverMinutes Drop Constraint PK__Changeov__3214EC273B470047;
END
GO

IF EXISTS(SELECT i.type_desc AS IndexType
FROM 
    sys.key_constraints kc
    INNER JOIN sys.tables t ON kc.parent_object_id = t.object_id
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    LEFT JOIN sys.indexes i ON kc.parent_object_id = i.object_id AND kc.unique_index_id = i.index_id
WHERE 
    kc.name = 'PK__Changeov__3214EC27DC0BE8EC'
    AND t.name = 'ChangeoverMinutes'
    AND s.name = 'dbo')
BEGIN
	ALTER TABLE ChangeoverMinutes Drop Constraint PK__Changeov__3214EC27DC0BE8EC;
END
GO


IF NOT EXISTS(SELECT i.type_desc AS IndexType
FROM 
    sys.key_constraints kc
    INNER JOIN sys.tables t ON kc.parent_object_id = t.object_id
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    LEFT JOIN sys.indexes i ON kc.parent_object_id = i.object_id AND kc.unique_index_id = i.index_id
WHERE 
    kc.name = 'PK_ChangeoverMinutes'
    AND t.name = 'ChangeoverMinutes'
    AND s.name = 'dbo')
BEGIN

--EXEC SP_HELP 'ChangeoverMinutes'

--ALTER TABLE CHANGEOVERMINUTES DROP CONSTRAINT PK__Changeov__3214EC2741D19BEC
	ALTER TABLE ChangeoverMinutes Add Constraint PK_ChangeoverMinutes PRIMARY KEY NONCLUSTERED (ID);
END
GO


IF NOT EXISTS(SELECT i.type_desc AS IndexType
FROM 
    sys.key_constraints kc
    INNER JOIN sys.tables t ON kc.parent_object_id = t.object_id
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    LEFT JOIN sys.indexes i ON kc.parent_object_id = i.object_id AND kc.unique_index_id = i.index_id
WHERE 
    kc.name = 'PK_ChangeoverMinutes_temp'
    AND t.name = 'ChangeoverMinutes_temp'
    AND s.name = 'dbo'
	and i.type_desc = 'NONCLUSTERED')
BEGIN
	ALTER TABLE ChangeoverMinutes_temp Add Constraint PK_ChangeoverMinutes_temp PRIMARY KEY NONCLUSTERED (ID);
END
----
GO
----------------------
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TicketStockAvailabilityRawMaterialTickets]') AND type in (N'U'))
DROP TABLE [dbo].[TicketStockAvailabilityRawMaterialTickets]
GO
-------------------------------
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TicketStockAvailabilityPO]') AND type in (N'U'))
DROP TABLE [dbo].[TicketStockAvailabilityPO]
GO
---------------------------------------------------------------
ALTER TABLE [dbo].[TicketStockAvailability] DROP CONSTRAINT [FK_TicketMaster_TicketId]
GO

ALTER TABLE [dbo].[TicketStockAvailability] DROP CONSTRAINT [FK_StockMaterial_OriginalStockMaterialId]
GO

ALTER TABLE [dbo].[TicketStockAvailabilityPO_temp] DROP CONSTRAINT FK_TicketStockAvailabilityPO_temp_TicketStockAvailabilityId
GO

ALTER TABLE [dbo].[TicketStockAvailabilityRawMaterialTickets_temp] DROP CONSTRAINT FK_TSA_temp_TicketStockAvailabilityId
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TicketStockAvailability]') AND type in (N'U'))
DROP TABLE [dbo].[TicketStockAvailability]
GO
---------------------TABLE CREATION************************
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[TicketStockAvailability](
	[Id] [varchar](36) NOT NULL,
	[TicketId] [varchar](36) NOT NULL,
	[FacilityId] [varchar](36) NOT NULL,
	[TaskDueDateTime] [datetime] NOT NULL,
	[OriginalStockMaterialId] [varchar](36) NOT NULL,
	[OriginalWidth] [real] NOT NULL,
	[StockStatus] [varchar](36) NOT NULL,
	[FirstAvailableTime] [datetime] NULL,
	[ActualStockMaterialId] [varchar](36) NULL,
	[ActualWidth] [real] NULL,
	[CreatedOnUTC] [datetime] NOT NULL,
	[ModifiedOnUTC] [datetime] NOT NULL,
	[OriginalLength] [real] NULL,
	[ActualLength] [real] NULL,
	[RequiredQuantity] [real] NULL,
	[TaskName] [nvarchar](255) NOT NULL,
	[Sequence] [smallint] NOT NULL,
 CONSTRAINT [PK_TicketStockAvailability] PRIMARY KEY NONCLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[TicketStockAvailability] ADD  DEFAULT ((0)) FOR [RequiredQuantity]
GO

ALTER TABLE [dbo].[TicketStockAvailability] ADD  DEFAULT ('') FOR [TaskName]
GO

ALTER TABLE [dbo].[TicketStockAvailability] ADD  DEFAULT ((0)) FOR [Sequence]
GO

ALTER TABLE [dbo].[TicketStockAvailability]  WITH CHECK ADD  CONSTRAINT [FK_StockMaterial_ActualStockMaterialId] FOREIGN KEY([ActualStockMaterialId])
REFERENCES [dbo].[StockMaterial] ([Id])
GO

ALTER TABLE [dbo].[TicketStockAvailability] CHECK CONSTRAINT [FK_StockMaterial_ActualStockMaterialId]
GO

ALTER TABLE [dbo].[TicketStockAvailability]  WITH CHECK ADD  CONSTRAINT [FK_StockMaterial_OriginalStockMaterialId] FOREIGN KEY([OriginalStockMaterialId])
REFERENCES [dbo].[StockMaterial] ([Id])
GO

ALTER TABLE [dbo].[TicketStockAvailability] CHECK CONSTRAINT [FK_StockMaterial_OriginalStockMaterialId]
GO

ALTER TABLE [dbo].[TicketStockAvailability]  WITH CHECK ADD  CONSTRAINT [FK_TicketMaster_TicketId] FOREIGN KEY([TicketId])
REFERENCES [dbo].[TicketMaster] ([ID])
GO

ALTER TABLE [dbo].[TicketStockAvailability] CHECK CONSTRAINT [FK_TicketMaster_TicketId]
GO
---------------------------

CREATE TABLE [dbo].[TicketStockAvailabilityPO](
	[Id] [varchar](36) NOT NULL,
	[PurchaseOrderItemId] [varchar](36) NOT NULL,
	[TicketStockAvailabilityId] [varchar](36) NOT NULL,
	[QuantityUsed] [real] NOT NULL,
	[CreatedOnUTC] [datetime] NOT NULL,
	[ModifiedOnUTC] [datetime] NOT NULL,
 CONSTRAINT [PK_TicketStockAvailabilityPO] PRIMARY KEY NONCLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[TicketStockAvailabilityPO]  WITH CHECK ADD  CONSTRAINT [FK_PurchaseOrderItem_PurchaseOrderItemId] FOREIGN KEY([PurchaseOrderItemId])
REFERENCES [dbo].[PurchaseOrderItem] ([Id])
GO

ALTER TABLE [dbo].[TicketStockAvailabilityPO] CHECK CONSTRAINT [FK_PurchaseOrderItem_PurchaseOrderItemId]
GO

ALTER TABLE [dbo].[TicketStockAvailabilityPO]  WITH CHECK ADD  CONSTRAINT [FK_TicketStockAvailability_TicketStockAvailabilityId] FOREIGN KEY([TicketStockAvailabilityId])
REFERENCES [dbo].[TicketStockAvailability] ([Id])
GO

ALTER TABLE [dbo].[TicketStockAvailabilityPO] CHECK CONSTRAINT [FK_TicketStockAvailability_TicketStockAvailabilityId]
GO
---------------------------------------------------

CREATE TABLE [dbo].[TicketStockAvailabilityRawMaterialTickets](
	[Id] [varchar](36) NOT NULL,
	[TicketStockAvailabilityId] [varchar](36) NOT NULL,
	[QuantityUsed] [real] NOT NULL,
	[CreatedOnUTC] [datetime] NOT NULL,
	[ModifiedOnUTC] [datetime] NOT NULL,
	[TicketItemInfoId] [varchar](36) NULL,
 CONSTRAINT [PK_TicketStockAvailabilityRawMaterialTickets] PRIMARY KEY NONCLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[TicketStockAvailabilityRawMaterialTickets]  WITH CHECK ADD  CONSTRAINT [FK_TSA_TicketItemInfo_TicketItemInfoId] FOREIGN KEY([TicketItemInfoId])
REFERENCES [dbo].[TicketItemInfo] ([Id])
GO

ALTER TABLE [dbo].[TicketStockAvailabilityRawMaterialTickets] CHECK CONSTRAINT [FK_TSA_TicketItemInfo_TicketItemInfoId]
GO

ALTER TABLE [dbo].[TicketStockAvailabilityRawMaterialTickets]  WITH CHECK ADD  CONSTRAINT [FK_TSA_TicketStockAvailabilityId] FOREIGN KEY([TicketStockAvailabilityId])
REFERENCES [dbo].[TicketStockAvailability] ([Id])
GO

ALTER TABLE [dbo].[TicketStockAvailabilityRawMaterialTickets] CHECK CONSTRAINT [FK_TSA_TicketStockAvailabilityId]
GO
------------
ALTER TABLE [dbo].[TicketStockAvailabilityRawMaterialTickets_temp]  WITH CHECK ADD  CONSTRAINT [FK_TSA_temp_TicketStockAvailabilityId]
FOREIGN KEY([TicketStockAvailabilityId])
REFERENCES [dbo].[TicketStockAvailability] ([Id])
GO

--TRUNCATE table TicketStockAvailabilityPO_temp
ALTER TABLE [dbo].[TicketStockAvailabilityPO_temp]  WITH CHECK ADD  CONSTRAINT [FK_TicketStockAvailabilityPO_temp_TicketStockAvailabilityId]
FOREIGN KEY([TicketStockAvailabilityId])
REFERENCES [dbo].[TicketStockAvailability] ([Id])
GO


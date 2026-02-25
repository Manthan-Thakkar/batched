CREATE TABLE [dbo].[TimecardInfo]
(
	Id					varchar(36),
	SourceTimecardId	varchar(4000),
	TicketId			varchar(36) NULL CONSTRAINT [FK_TimecardInfo_TicketId] FOREIGN KEY REFERENCES TicketMaster(Id),
	SourceTicketId		varchar(4000),
	EquipmentId			varchar(36) NULL CONSTRAINT [FK_TimecardInfo_EquipmentId] FOREIGN KEY REFERENCES EquipmentMaster(Id),
	SourceEquipmentId	varchar(4000),
	TaskName			nvarchar(255) NULL,
	StartedOn			datetime,
	CompletedAt			datetime,
	ElapsedTime			time,
	ActualNetQuantity	real,
	CreatedOn			datetime,
	ModifiedOn			datetime,
	Totalizer			NVARCHAR(4000) NULL,
	OperationType		NVARCHAR (255) NULL,
	Associate			NVARCHAR (300) NULL,
	ActualWasteQuantity real NULL,
	FinishedPieces		int NULL,
	ActualGrossQuantity real NULL,
	ActualGrossLength	real NULL,
	ActualCurrentSpeed	real NULL
    CONSTRAINT [PK_TimecardInfoID] PRIMARY KEY NONCLUSTERED ([Id])
)
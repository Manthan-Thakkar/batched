CREATE TABLE [dbo].[EquipmentMaster] (
    [ID]							VARCHAR (36)    NOT NULL,
	[TenantId]						VARCHAR (36)    NOT NULL,
	[Source]						NVARCHAR(23)    NOT NULL,
	[SourceEquipmentId]				NVARCHAR(64)    NOT NULL,
	[WorkcenterTypeId]				VARCHAR (36)    NULL,
	[WorkCenterName]				nvarchar(32)     null,
	[FacilityId]					VARCHAR (36)    NULL,
	[Name]							NVARCHAR (128)  NOT NULL,
	[DisplayName]					NVARCHAR (128)  NOT NULL,
	[Description]					NVARCHAR (256)  NULL,
	[IsEnabled]						BIT             NOT NULL DEFAULT 0,
	[AvailableForPlanning]			BIT             NOT NULL DEFAULT 0,
	[AvailableForScheduling]		BIT             NOT NULL DEFAULT 0,
	[IsMasterRollBatchingRequired]	BIT             NOT NULL DEFAULT 0,
	[IsInlineRewindingRequired]		BIT             NOT NULL DEFAULT 0,
	[IsInlineSheetingRequired]		BIT             NOT NULL DEFAULT 0,
	[SourceCreatedOn]				DATETIME        NULL,
	[SourceModifiedOn]				DATETIME        NULL,
	[CreatedOn]						DATETIME        NOT NULL,
	[ModifiedOn]					DATETIME        NOT NULL,
	MasterRollLength			    real			Null,
	RollingNumber					int				null,
	RollingHour						int			null,
	FacilityName					NVARCHAR(128)	NULL
    CONSTRAINT [PK_EquipmentMasterID] PRIMARY KEY NONCLUSTERED ([ID] ASC)
);


CREATE TABLE [dbo].[DatabaseInstance]
(
	[ID]						varchar(36)		NOT NULL,
	[InstanceName]				nvarchar(255)	NOT NULL,
	[InstanceTypeId]			varchar(36)		NOT NULL CONSTRAINT [FK_InstanceType_InstanceTypeId] FOREIGN KEY REFERENCES InstanceType(Id),
	[Provider]					nvarchar(255)	NOT NULL,
	[Endpoint]					nvarchar(255)	NOT NULL,
	[Port]						int				NOT NULL,
	[ApprovedTS]				datetime		NULL,
	[ApprovedBy]				varchar(36)		NULL,
	[ConnectionStringTemplate]	nvarchar(MAX)	NOT NULL,
	[ErpId] VARCHAR(36) NOT NULL, 
    [IsShared] BIT NOT NULL DEFAULT 1, 
    CONSTRAINT [PK_DatabaseInstance] PRIMARY KEY NONCLUSTERED ([Id] ASC), 
    CONSTRAINT [FK_ERPMaster_ErpId] FOREIGN KEY ([ErpId]) REFERENCES [ERPMaster]([Id])
)

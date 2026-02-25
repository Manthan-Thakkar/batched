CREATE TABLE [dbo].[Facility] (
    [ID]              VARCHAR   (36)    NOT NULL,
    [Name]            NVARCHAR (128)    NULL,
    [TenantId]        VARCHAR   (36)    NOT NULL,
    [AddressLine]     NVARCHAR (128)    NULL,
    [City]            NVARCHAR (64)     NULL,
    [StateOrProvince] NVARCHAR (64)     NULL,
    [CountryCode]     NVARCHAR (2)      NULL,
    [ZipCode]         NVARCHAR (16)     NULL,
    [TimeZone]        NVARCHAR (64)     NULL,
    [IsEnabled]       BIT               NOT NULL,
    [CreatedOn]       DATETIME          NULL,
    [ModifiedOn]      DATETIME          NULL,
	[SourceFacilityId]  NVARCHAR(255)     NULL,
    [Source]            NVARCHAR(100)     NULL,
    CONSTRAINT [PK_FacilityID] PRIMARY KEY NONCLUSTERED ([ID] ASC),
    CONSTRAINT [FK_Facility_TenantId] FOREIGN KEY ([TenantId]) REFERENCES [dbo].[Tenant] ([ID])
);


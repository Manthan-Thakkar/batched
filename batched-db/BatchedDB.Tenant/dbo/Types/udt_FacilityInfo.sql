CREATE TYPE [dbo].[udt_FacilityInfo] AS TABLE
(
	[FacilityId] varchar(36) NULL, --batched facilityId
	[SourceFacilityId] varchar(510) NULL,
	[Name] nvarchar(256) NULL
)
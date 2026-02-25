CREATE TYPE [dbo].[udt_FacilityData] AS TABLE (
	[FacilityId] [nvarchar](255),
	[Name] [nvarchar](128) NULL,
	[AddressLine] [nvarchar](128) NULL,
	[City] [nvarchar](64) NULL,
	[StateOrProvince] [nvarchar](64) NULL,
	[CountryCode] [nvarchar](2) NULL,
	[ZipCode] [nvarchar](16) NULL,
	[IsEnabled] [bit] NOT NULL,
	[SourceFacilityId] [nvarchar](255),
	[Source] [nvarchar](100)
)
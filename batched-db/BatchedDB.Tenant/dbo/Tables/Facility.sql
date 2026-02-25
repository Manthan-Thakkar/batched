CREATE TABLE Facility(
		[ID]			VARCHAR(36) PRIMARY KEY NOT NULL,
		[Name]			NVARCHAR(128) NULL,
		[TenantId]		VARCHAR(36) NOT NULL,
		[AddressLine]	NVARCHAR(128) NULL,
		[City]			NVARCHAR(64) NULL,
		[StateOrProvince] NVARCHAR(64) NULL,
		[CountryCode]	NVARCHAR(64) NULL,
		[ZipCode]		NVARCHAR(16) NULL,
		[TimeZone]		NVARCHAR(64) NULL,
		[IsEnabled]		BIT NOT NULL,
		[SourceFacilityId] NVARCHAR(255) NULL,
		[Source]		NVARCHAR(100) NULL,
		[CreatedOnUTC]	DATETIME NULL,
		[ModifiedOnUTC] DATETIME NULL
	)
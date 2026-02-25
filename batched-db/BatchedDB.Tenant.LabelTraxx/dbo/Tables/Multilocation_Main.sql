CREATE TABLE [dbo].[Multilocation_Main](
		[PK_UUID]			VARCHAR(36) PRIMARY KEY NOT NULL,
		[ID]				VARCHAR(36)				NOT NULL,
		[locationTag]		VARCHAR(36)				NOT NULL,
		[locationName]		NVARCHAR(128)			NULL,
		[Address1]			NVARCHAR(256)			NULL,
		[Address2]			NVARCHAR(256)			NULL,
		[City]				NVARCHAR(128)			NULL,
		[State_Province]	VARCHAR(36)				NULL,
		[postCode]			VARCHAR(36)				NULL,
		[Country]			VARCHAR(36)				NULL,
		[Phone]				VARCHAR(36)				NULL,
		[firstLocation]		BIT						NULL,
		[taxID]				NVARCHAR(256)			NULL,
		[mfgLogo]			VARBINARY(1)			NULL
	);
CREATE TABLE [dbo].[CustomerMaster]
	(
		[Id]								VARCHAR(36)			NOT NULL PRIMARY KEY,
		[SourceCustomerID]					NVARCHAR(4000),
		[CustomerName]						NVARCHAR(4000),
		[Source]							NVARCHAR(36)		NOT NULL,
		[DistributorNumber]					NVARCHAR(4000),
		[ManufacturingRepNumber]			NVARCHAR(4000),
		[Notes]								NVARCHAR(4000),
		[SourceSalespersonID]				NVARCHAR(4000),
		[SourceCustomerServicePersonID]		NVARCHAR(4000),
		[IsCustomer]						BIT,
		[IsDistributor]						BIT,
		[Salesperson]						NVARCHAR(4000),
		[CustomerServicePerson]				NVARCHAR(4000),
		[IsActive]							BIT,
		[CustomField1]						NVARCHAR(4000),
		[SourceRecordId]					NVARCHAR(4000),
		[CreatedOn]							DATETIME			NOT NULL,
		[ModifiedOn]						DATETIME			NOT NULL,
		[CustomerGroup]						VARCHAR(1024)		NULL
	)
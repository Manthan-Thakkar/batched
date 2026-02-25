CREATE TABLE [dbo].[PV_Address]
(
	[Address1] nvarchar(4000) NULL,
	[Address2] nvarchar(4000) NULL,
	[Address3] nvarchar(4000) NULL,
	[AddressNum] int NULL,
	[AddressType] nvarchar(4000) NULL,
	[AddrName] nvarchar(4000) NULL,
	[Country] nvarchar(4000) NULL,
	[CountryCode] nvarchar(4000) NULL,
	[County] nvarchar(4000) NULL,
	[CountyCode] nvarchar(4000) NULL,
	[DeliverySpec] nvarchar(4000) NULL,
	[DisplayAddress] nvarchar(4000) NULL,
	[Email] nvarchar(4000) NULL,
	[Fax] nvarchar(4000) NULL,
	[GLN] bigint NULL,
	[LastUserCode] nvarchar(4000) NULL,
	[Storefront] int NULL,
	[TableRecId] bigint NULL,
	[Telephone] nvarchar(4000) NULL,
	[Town] nvarchar(4000) NULL,
	[PostCode] nvarchar(4000) NULL
)
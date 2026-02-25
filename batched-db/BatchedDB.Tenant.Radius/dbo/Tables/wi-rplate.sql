CREATE TABLE [dbo].[wi-rplate]
(
	[kco] int NULL,
	[korder] nvarchar(4000) NULL,
	[k-route-seq] int NULL,
	[k-cmp-no] int NULL,
	[kdeptsn] nvarchar(4000) NULL,
	[kwcsn] nvarchar(4000) NULL,
	[kconfig] int NULL,
	[wi-rp-price-or] decimal(18, 0) NULL,
	[wi-rp-override] bit NULL,
	[wi-rp-plate-qty] decimal(18, 0) NULL,
	[wi-rp-handle] decimal(18, 0) NULL,
	[wi-rp-plate-type] nvarchar(4000) NULL,
	[wi-rp-labour-time-or] decimal(18, 0) NULL,
	[wi-rp-labour-rate-or] decimal(18, 0) NULL,
	[wi-rp-table-time-or] decimal(18, 0) NULL,
	[wi-rp-kmatcode] nvarchar(4000) NULL,
	[PlantCode] nvarchar(4000) NULL
)

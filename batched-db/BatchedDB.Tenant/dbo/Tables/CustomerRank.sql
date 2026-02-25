CREATE TABLE [dbo].[CustomerRank]
(
	[Id] [varchar](36) NOT NULL,
	[TenantId] [varchar](36) NOT NULL,
	[Source] [nvarchar](23) NOT NULL,
	[SourceCustomerId] [nvarchar](64) NOT NULL,
	[Revenue] [float] NULL,
	[TotalRevenue] [float] NULL,
	[CumulativeRevenue] [float] NULL,
	[CumulativeProportion] [float] NULL,
	[RevenuePercent] [float] NULL,
	[RevenuePercentile] [float] NULL,
	[RevenueRank] [bigint] NULL,
	[TotalCustomers] [int] NULL,
	[Rank] [char](1) NULL,
	[HasCustomRank] [bit] NOT NULL,
	[CustomRank] [bigint] NULL,
	[CreatedOn] [datetime] NOT NULL,
	[ModifiedOn] [datetime] NOT NULL,
    CONSTRAINT [PK_CustomerRankID] PRIMARY KEY NONCLUSTERED ([ID] ASC)
);
CREATE TABLE [dbo].[customerPareto] (
    [CustomerNum]          NVARCHAR (4000)   NULL,
    [customerRevenue]      FLOAT (53)       NULL,
    [totalCustomerRevenue] FLOAT (53)       NULL,
    [percOfTotalRevenue]   FLOAT (53)       NULL,
    [customerIndex]        BIGINT           NULL,
    [totalCustomers]       INT              NULL,
    [percOfTotalCustomers] NUMERIC (33, 12) NULL,
    [cumRevenue]           FLOAT (53)       NULL,
    [cumProportion]        FLOAT (53)       NULL,
    [customerRank]         VARCHAR (1)      NOT NULL,
    [lastUpdated]          DATETIME         NOT NULL
);


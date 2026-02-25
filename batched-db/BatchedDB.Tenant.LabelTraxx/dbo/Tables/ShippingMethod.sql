CREATE TABLE [dbo].[ShippingMethod] (
    [ID]                        VARCHAR (36) NOT NULL ,
    [SourceShippingMethodId]    NVARCHAR(500) NOT NULL,
    [Name]                      NVARCHAR(4000) NOT NULL ,
    [GroupName]                 NVARCHAR(500)

    CONSTRAINT [PK_ShippingMethodID] PRIMARY KEY NONCLUSTERED ([ID] ASC)
);


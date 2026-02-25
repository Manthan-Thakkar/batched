CREATE TABLE [dbo].[Country] (
    [ISOCode2] NVARCHAR (2)   NOT NULL,
    [Name]     NVARCHAR (128) NULL,
    [PhoneCode] varchar(10)
    CONSTRAINT [PK_CountryID] PRIMARY KEY NONCLUSTERED ([ISOCode2] ASC)
);


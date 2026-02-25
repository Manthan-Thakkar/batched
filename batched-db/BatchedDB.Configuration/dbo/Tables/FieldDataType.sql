CREATE TABLE [dbo].[FieldDataType](
	[ID] VARCHAR(36)  PRIMARY KEY NOT NULL,
	[JsonFieldName]   VARCHAR(255) Not NULL,
    [DataType]        NVARCHAR (16)  NULL,
	[CreatedOn]       DATETIME NOT NULL,
	[ModifiedOn]      DATETIME NOT NULL,
)
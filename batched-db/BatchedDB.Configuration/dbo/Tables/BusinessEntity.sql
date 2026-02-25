CREATE TABLE [dbo].[BusinessEntity](
    [Id]            VARCHAR(36)     CONSTRAINT [PK_BusinessEntityId] PRIMARY KEY,
    [Name]          NVARCHAR(64)    NOT NULL,
    [CategoryId]     VARCHAR(36)    Foreign key references BusinessCategory(ID),
    [CreatedOn]     [datetime]      NULL,
    [ModifiedOn]    [datetime]      NULL
)

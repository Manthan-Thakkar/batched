  CREATE TABLE [dbo].[UserHashValues] (
        [PK_UUID] NVARCHAR(4000) PRIMARY KEY,
        [SourceUserId] NVARCHAR(4000) NOT NULL,
        [HashValue] VARBINARY(32) NULL
    );
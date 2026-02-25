CREATE TABLE [dbo].[UserContext]
(
	[ID] [varchar](36) PRIMARY KEY NOT NULL,
	[UserName] [varchar](100) NOT NULL,
	[Context] [varchar](100) NOT NULL,
	[Value] [varchar](100) NOT NULL,
	CreatedOn			DATETIME		NOT NULL,
	ModifiedOn			DATETIME		NOT NULL,
)
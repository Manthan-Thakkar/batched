CREATE TYPE [dbo].[udt_User] AS TABLE(
	[Number] NVARCHAR(4000),
	[FirstName] NVARCHAR(4000),
	[LastName] NVARCHAR(4000),
	[E_Mail_Address] NVARCHAR(4000),
	[Phone] NVARCHAR(4000),
	[Inactive] BIT,
	[POPermission] INT
)
GO
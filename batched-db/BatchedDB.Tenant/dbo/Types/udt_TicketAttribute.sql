/****** Object:  UserDefinedTableType [dbo].[udt_TicketAttribute]    Script Date: 27-10-2022 09:30:08 ******/
CREATE TYPE [dbo].[udt_TicketAttribute]
AS TABLE(    [ID] [nvarchar](64) NOT NULL,  
[Name] [nvarchar](64) NULL, 
[Description] [nvarchar](256) NULL, 
[TenantId] [nvarchar](36) NULL, 
[DataType] [nvarchar](16) NULL,
[UnitOfMeasurement] [nvarchar](16) NULL,
[Scope] [nvarchar](16) NULL,
[IsEnabled] [bit] NOT NULL,
[RequiredForMaterialPlanning] [BIT] NOT NULL,
[IsProcessed] [bit] NULL DEFAULT 0)
GO
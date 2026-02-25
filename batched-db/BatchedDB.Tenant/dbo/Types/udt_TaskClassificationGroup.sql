/****** Object:  UserDefinedTableType [dbo].[udt_TaskClassificationGroup]    Script Date: 27-10-2022 10:51:02 ******/
CREATE TYPE [dbo].[udt_TaskClassificationGroup] 
AS TABLE([WorkcenterTypeId] [varchar](36) NULL,    
[TicketAttributeId] [varchar](36) NULL)
GO
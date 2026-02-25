/****** Object:  UserDefinedTableType [dbo].[udt_TicketAttributeFormula]    Script Date: 27-10-2022 10:50:41 ******/
CREATE TYPE [dbo].[udt_TicketAttributeFormula] 
AS TABLE([FormulaType] [nvarchar](20) NULL,    
[FormulaText] [nvarchar](512) NULL,    
[TicketAttributeId] [varchar](36) NULL,    
[RuleText] [nvarchar](2048) NULL)

GO
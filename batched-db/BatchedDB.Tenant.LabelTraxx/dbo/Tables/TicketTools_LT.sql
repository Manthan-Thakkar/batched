CREATE TABLE [dbo].[TicketTools_LT](
    [PKUUID]                NVARCHAR(36)        NULL,
    [TenantTag]             NVARCHAR(100)       NULL,
    [ID]                    INT                 NULL,
    [TicketNumber]          NVARCHAR(36)        NULL,
    [RoutingNo]             INT                 NULL,
    [ToolNo]                NVARCHAR(36)        NULL,
    [ToolDescr]             NVARCHAR(1000)      NULL,
    [NewTimeDateStamp]      DATETIME            NULL,
    [UpdateTimeDateStamp]   DATETIME            NULL
);
CREATE TABLE [dbo].[Ticket_UserDefined] (
    [PK_UUID]             NVARCHAR (450) NOT NULL,
    [EQUIPUSERDEFINED_ID] INT             NULL,
    [TICKETNUMBER]        NVARCHAR (4000) NULL,
    [DESCRIPTION]         NVARCHAR (4000) NULL,
    [USETHISOPTION]       BIT             NULL,
    [NOTES]               NVARCHAR (4000) NULL,
    [PRINT_ON_REPORTS]    BIT             NULL,
    [ORDER_IN_LIST]       INT             NULL,
    [PRESS_NUMBER]        NVARCHAR (4000) NULL,
    [OPTION_MULTIPLIER]   REAL            NULL,
    [UpdateTimeDateStamp]     DATETIME        NULL
);


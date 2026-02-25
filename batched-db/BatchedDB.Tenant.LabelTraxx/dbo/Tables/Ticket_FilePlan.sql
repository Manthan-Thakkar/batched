CREATE TABLE [dbo].[Ticket_FilePlan] (
    [PK_UUID]                  NVARCHAR (450) NOT NULL,
    [ID]                       NVARCHAR (4000) NULL,
    [TICKET_ID]                NVARCHAR (4000) NULL,
    [TICKETITEM_ID]            NVARCHAR (4000) NULL,
    [PRODUCT_UNIQUEID]         NVARCHAR (4000) NULL,
    [ORDER_QUANTITY]           INT             NULL,
    [PRODUCT_NUMBER]           NVARCHAR (4000) NULL,
    [PRODUCT_DESCRIPTION]      NVARCHAR (4000) NULL,
    [FILEPLATE_NAME]           NVARCHAR (4000) NULL,
    [FILEPLATE_NUMBER]         INT             NULL,
    [FILEPLATE_TOTALNUMBER]    INT             NULL,
    [ITEM_ORDER_NUMBER]        INT             NULL,
    [NUMBER_OF_ITEMS_ON_PLATE] INT             NULL
);


CREATE TABLE [dbo].[Timecard] (
    [ID]                      NVARCHAR (255)  NOT NULL,
    [AssocNo]                 NVARCHAR (4000) NULL,
    [Ticket_No]               NVARCHAR (4000) NULL,
    [WorkOperation]           NVARCHAR (4000) NULL,
    [SDate]                   DATETIME        NULL,
    [EDate]                   DATETIME        NULL,
    [STime]                   TIME (7)        NULL,
    [ETime]                   TIME (7)        NULL,
    [Elapsed]                 TIME (7)        NULL,
    [Closed]                  BIT             NULL,
    [FinishedPieces]          INT             NULL,
    [PressNo]                 NVARCHAR (4000) NULL,
    [FootUsed]                INT             NULL,
    [Totalizer]               NVARCHAR (4000) NULL,
    [Notes]                   NVARCHAR (4000) NULL,
    [OffPress]                BIT             NULL,
    [Packaged]                BIT             NULL,
    [Labels_Est_to_Produce]   REAL            NULL,
    [Labels_Act_Net]          REAL            NULL,
    [Labels_Act_Waste]        REAL            NULL,
    [Labels_Act_Gross]        REAL            NULL,
    [Length_Est_Required]     REAL            NULL,
    [Length_Act_Net]          REAL            NULL,
    [Length_Act_Waste]        REAL            NULL,
    [Length_Act_Gross]        REAL            NULL,
    [Speed_Est_Length_Min]    REAL            NULL,
    [Speed_Act_Length_Min]    REAL            NULL,
    [Speed_Act_Labels_Min]    REAL            NULL,
    [Time_Est_Total]          REAL            NULL,
    [SC_MasterEvent_Code]     NVARCHAR (4000) NULL,
    [SC_Event_ID]             INT             NULL,
    [PK_UUID]                 NVARCHAR (4000) NULL,
    [Ticket_PressEquip]       NVARCHAR (4000) NULL,
    [Ticket_PressEquip_Local] NVARCHAR (4000) NULL,
    [UpdateTimeDateStamp]     DATETIME        NULL
);


GO
CREATE NONCLUSTERED INDEX [_dta_index_Timecard_8_1619693018__K3_5_6_7_8_9_12]
    ON [dbo].[Timecard]([Ticket_No] ASC)
    INCLUDE([SDate], [EDate], [STime], [ETime], [Elapsed], [PressNo]);


CREATE TABLE [dbo].[Equip_UserDefined] (
    [ID]                  INT             NULL,
    [Press_Number]        NVARCHAR (4000) NULL,
    [Description]         NVARCHAR (4000) NULL,
    [MakeReadyHours]      REAL            NULL,
    [WashUpHours]         REAL            NULL,
    [SpeedChange]         REAL            NULL,
    [SpoilageChange]      REAL            NULL,
    [PressProfiler]       BIT             NULL,
    [Print_On_Reports]    BIT             NULL,
    [Order_in_List]       INT             NULL,
    [Add_Web_Width]       REAL            NULL,
    [Stock_SetUp_Length]  REAL            NULL,
    [Option_Multiplier]   REAL            NULL,
    [Add_Hourly_Est_Rate] REAL            NULL,
    [Add_Hourly_WIP_Rate] REAL            NULL,
    [Add_Run_Length]      REAL            NULL,
    [UpdateTimeDateStamp] DATETIME        NULL,
    [PK_UUID]             NVARCHAR (4000) NULL
);


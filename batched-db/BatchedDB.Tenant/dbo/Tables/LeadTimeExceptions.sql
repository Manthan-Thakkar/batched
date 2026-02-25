CREATE TABLE [dbo].[LeadTimeExceptions]
(
    [Id]                VARCHAR(36) PRIMARY KEY     NOT NULL,
    [Name]              NVARCHAR(100)               NOT NULL,
    [Reason]            NVARCHAR(100)               NOT NULL,
    [LeadTimeInDays]    INT                         NOT NULL,
    [CreatedBy]         NVARCHAR(50)                NOT NULL,
    [ModifiedBy]        NVARCHAR(50)                NOT NULL,
    [CreatedOnUTC]      DATETIME                    NOT NULL,
    [ModifiedOnUTC]     DATETIME                    NOT NULL
);
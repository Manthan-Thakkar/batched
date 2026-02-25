CREATE TABLE [dbo].[ApiConfigParamFresh] (
    [apiConfigParamID] INT            IDENTITY (1, 1) NOT NULL,
    [api_config_id]    INT            NULL,
    [queryConditional] NVARCHAR (255) NULL,
    [fieldName]        NVARCHAR (255) NULL,
    [queryOperator]    NVARCHAR (255) NULL,
    [queryParameter]   NVARCHAR (255) NULL,
    CONSTRAINT [PK_ApiConfigParamFreshapiConfigParamID] PRIMARY KEY CLUSTERED ([apiConfigParamID] ASC)
);


CREATE TABLE [dbo].[ApiConfigParamGenericOneFresh] (
    [apiConfigParamID] INT            IDENTITY (1, 1) NOT NULL,
    [api_config_id]    INT            NULL,
    [fieldName]        NVARCHAR (255) NULL,
    [operator]         NVARCHAR (255) NULL,
    [queryType]        NVARCHAR (255) NULL,
    [queryValue]       NVARCHAR (255) NULL,
    [startSelection]   INT            NULL,
    [endSelection]     INT            NULL
);


CREATE TABLE [dbo].[ref_api_config_param_fresh] (
    [api_config_param_id] INT            IDENTITY (1, 1) NOT NULL,
    [api_config_id]       INT            NULL,
    [api_param_name]      NVARCHAR (255) NULL,
    [api_param_value]     NVARCHAR (255) NULL
);


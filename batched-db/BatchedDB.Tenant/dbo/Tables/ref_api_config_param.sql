CREATE TABLE [dbo].[ref_api_config_param] (
    [api_config_param_id]  INT            IDENTITY (1, 1) NOT NULL,
    [api_config_id]        INT            NULL,
    [api_config_param_seq] INT            NULL,
    [api_param_name]       NVARCHAR (255) NULL,
    [api_param_value]      NVARCHAR (255) NULL,
    CONSTRAINT [PK_ref_api_config_paramapi_config_param_id] PRIMARY KEY CLUSTERED ([api_config_param_id] ASC)
);


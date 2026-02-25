CREATE TABLE [dbo].[ref_api_config] (
    [api_config_id]           INT             IDENTITY (1, 1) NOT NULL,
    [api_table_reference]     NVARCHAR (255)  NULL,
    [api_name]                NVARCHAR (255)  NULL,
    [api_endpoint]            NVARCHAR (4000) NULL,
    [api_endpoint_fresh]      NVARCHAR (4000) NULL,
    [api_sequence]            INT             NULL,
    [api_method]              NVARCHAR (255)  NULL,
    [s3_bucket_location]      NVARCHAR (4000) NULL,
    [batch_type]              NVARCHAR (4000) NULL,
    [batch_per_request]       INT             NULL,
    [total_rows]              INT             NULL,
    [initial_date]            DATE            NULL,
    [is_fresh_api]            BIT             CONSTRAINT [DF_ref_api_config_is_fresh_api] DEFAULT ((1)) NULL,
    [is_duplicate]            BIT             NULL,
    [is_active]               BIT             CONSTRAINT [DF_ref_api_config_is_active] DEFAULT ((1)) NULL,
    [truncate_eligible]       BIT             NULL,
    [requires_truncate]       BIT             NULL,
    [midnight_fresh_eligible] BIT             NULL,
    CONSTRAINT [PK_ref_api_configapi_config_id] PRIMARY KEY CLUSTERED ([api_config_id] ASC)
);


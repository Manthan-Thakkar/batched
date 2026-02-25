CREATE PROCEDURE [dbo].[spInsertUpdateFacilityData]
	@facilities     AS	[dbo].[udt_FacilityData] READONLY,	
	@TenantId		AS	NVARCHAR(36),
	@CorelationId	AS	VARCHAR(100)
AS
BEGIN

	SET NOCOUNT ON;

	BEGIN
--  ==============================logging variables=======================================
	DECLARE 
		@spName					VARCHAR(100) = 'spInsertUpdateFacilityData',
		@__ErrorInfoLog			__ErrorInfoLog,
		@maxCustomMessageSize	INT = 4000,
		@blockName				VARCHAR(100),
		@warningStr				NVARCHAR(4000),
		@infoStr				NVARCHAR(4000),
		@errorStr				NVARCHAR(4000),
		@IsError				BIT = 0,
		@startTime				DATETIME;
--  ======================================================================================================
	END

	SET NOCOUNT ON;


	DROP TABLE IF EXISTS [dbo].[#FacilitiesToBeUpdated];
	DROP TABLE IF EXISTS [dbo].[#FacilitiesToBeInserted];


	-- Fetch facilities to be updated
    SELECT [FT].*
    INTO [dbo].[#FacilitiesToBeUpdated]
    FROM @facilities [FT]
    INNER JOIN [dbo].[Facility] [F] WITH(NOLOCK) ON [FT].[FacilityId] = [F].[ID]
    WHERE
        [F].[Name]              != [FT].[Name]              OR
        [F].[City]              != [FT].[City]              OR
        [F].[ZipCode]           != [FT].[ZipCode]           OR
        [F].[AddressLine]       != [FT].[AddressLine]       OR
        [F].[CountryCode]       != [FT].[CountryCode]       OR
        [F].[StateOrProvince]   != [FT].[StateOrProvince]   OR
        [F].[SourceFacilityId]  != [FT].[SourceFacilityId];
    

    -- Fetch facilities to be inserted
    SELECT [FT].*
    INTO [dbo].[#FacilitiesToBeInserted]
    FROM @facilities [FT]
    LEFT JOIN [dbo].[Facility] [F] WITH (NOLOCK) ON [FT].[FacilityId] = [F].[ID]
    WHERE [F].[ID] IS NULL;


	-- Update matching Facilities
	IF @IsError = 0 AND EXISTS (SELECT TOP 1 [FacilityId] FROM [dbo].[#FacilitiesToBeUpdated])
	BEGIN		
		SET @blockName = 'UpdateFacilities'; SET @startTime = GETUTCDATE();
		
		BEGIN TRY	

			UPDATE [F]

			SET
				-- [Name]				=	[FT].[Name],
				[City]				=	[FT].[City],
				[ZipCode]			=	[FT].[ZipCode],
				[AddressLine]		=	[FT].[AddressLine],
				[CountryCode]		=	[FT].[CountryCode],
				[StateOrProvince]	=	[FT].[StateOrProvince],
				[SourceFacilityId]	=	[FT].[SourceFacilityId],
				[Source]			=	'LabelTraxx',
				[ModifiedOn]		=	GETUTCDATE()
			
			FROM [dbo].[Facility] [F] WITH (ROWLOCK, UPDLOCK)
			
			INNER JOIN [dbo].[#FacilitiesToBeUpdated] [FT] ON [FT].[FacilityId] = [F].[ID];
				

			SET @infoStr = 'TotalRowsAffected|' +  CONVERT(VARCHAR, @@ROWCOUNT)
			
		END TRY
		BEGIN CATCH

	--	==================================[Do not change]================================================
			SET @IsError = 1; --Rollback;
			SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(VARCHAR, ERROR_LINE())
	--	=======================[Concate more error strings after this]===================================
		
		END CATCH

		INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
	END


	-- Insert new facilities
	IF @IsError = 0 AND EXISTS (SELECT TOP 1 [FacilityId] FROM [dbo].[#FacilitiesToBeInserted])
	BEGIN		
		SET @blockName = 'InsertNewFacilities'; SET @startTime = GETDATE();

		BEGIN TRY

			INSERT INTO [dbo].[Facility]
				([ID], [Name], [TenantId], [AddressLine], [City], [StateOrProvince], [CountryCode], [ZipCode], [IsEnabled], [CreatedOn], [ModifiedOn], [SourceFacilityId], [Source])
			
			SELECT
				[FacilityId], [Name], @TenantId, [AddressLine], [City], [StateOrProvince], [CountryCode], [ZipCode], 1, GETUTCDATE(), GETUTCDATE(), [SourceFacilityId], 'LabelTraxx'
			
			FROM [dbo].[#FacilitiesToBeInserted];

				
			SET @infoStr = 'TotalRowsAffected|' +  CONVERT(VARCHAR, @@ROWCOUNT)

		END TRY
		BEGIN CATCH

	--	==================================[Do not change]================================================
			SET @IsError = 1; --Rollback;
			SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(VARCHAR, ERROR_LINE())
	--	=======================[Concate more error strings after this]===================================
		
		END CATCH
		INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
	END


	DROP TABLE IF EXISTS [dbo].[#FacilitiesToBeUpdated];
	DROP TABLE IF EXISTS [dbo].[#FacilitiesToBeInserted];


--	    ========================[final commit log (do not change)]=======================================
	IF @IsError = 0
	BEGIN
		--COMMIT;
		INSERT INTO @__ErrorInfoLog VALUES(@corelationId, 'dbLog', @tenantId, 'database', 'Commit-Applicable', 0, GETUTCDATE(), 
			@spName, 'final-commit', 'info', 'message|all blocks completed without any error')
	END
	SELECT *, 'tbl_ErrorInfoLog' AS __dataset_tableName FROM @__ErrorInfoLog AS ErrorInfoLog;
--		=================================================================================================

END
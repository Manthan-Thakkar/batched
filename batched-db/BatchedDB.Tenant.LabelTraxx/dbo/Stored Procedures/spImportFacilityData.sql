CREATE PROCEDURE [dbo].[spImportFacilityData]
	@TenantId		NVARCHAR(36),
	@CorelationId	VARCHAR(100),
	@facilityInfo	udt_FacilityInfo READONLY
AS
BEGIN

	SET NOCOUNT ON;

	BEGIN
--	==============================logging variables=======================================
	DECLARE 
		@spName					VARCHAR(100) = 'spImportFacilityData',
		@__ErrorInfoLog			__ErrorInfoLog,
		@maxCustomMessageSize	INT = 4000,
		@blockName				VARCHAR(100),
		@warningStr				NVARCHAR(4000),
		@infoStr				NVARCHAR(4000),
		@errorStr				NVARCHAR(4000),
		@IsError				BIT = 0,
		@startTime				DATETIME;
--	======================================================================================================
	END

	SET NOCOUNT ON;

    CREATE TABLE #UpdatedFacilities(
        [Id]				VARCHAR(36),
        [SourceFacilityId]	VARCHAR(36),
        [Name]				NVARCHAR(128),
        [AddressLine]		NVARCHAR(128),
        [City]				NVARCHAR(64),
        [StateOrProvince]	NVARCHAR(64),
        [CountryCode]		NVARCHAR(64),
        [ZipCode]			NVARCHAR(16),
		[IsEnabled]			BIT
    );

    CREATE TABLE #NewFacilities(
        [ID]				VARCHAR(36),
        [Name]				NVARCHAR(128),
        [AddressLine]		NVARCHAR(128),
        [City]				NVARCHAR(64),
        [StateOrProvince]	NVARCHAR(64),
        [CountryCode]		NVARCHAR(64),
        [ZipCode]			NVARCHAR(16),
        [SourceFacilityId]	VARCHAR(36)
    );

    IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'Multilocation_Main')
		BEGIN
			IF EXISTS (SELECT TOP 1 ID FROM Multilocation_Main)
			BEGIN
				INSERT INTO #UpdatedFacilities
				SELECT
					FI.[FacilityId]		AS Id,
					ML.[locationTag]	AS SourceFacilityId,
					ML.[locationName]	AS Name,
					ML.[Address1]		AS AddressLine,
					ML.[City]			AS City,
					ML.[State_Province]	AS StateOrProvince,
					ML.[Country]		AS CountryCode,
					ML.[postCode]		AS ZipCode,
					F.[IsEnabled]		AS IsEnabled
				FROM [dbo].[Facility] F WITH(NOLOCK)
					INNER JOIN @facilityInfo FI ON  FI.[FacilityId] = F.[ID]
					INNER JOIN [dbo].[Multilocation_Main] ML ON ML.[locationTag] = FI.[SourceFacilityId]
			END
			ELSE 
			BEGIN
				INSERT INTO #UpdatedFacilities
				SELECT
					F.[ID]					AS Id,
					F.[SourceFacilityId]	AS SourceFacilityId,
					F.[Name]				AS Name,
					F.[AddressLine]			AS AddressLine,
					F.[City]				AS City,
					F.[StateOrProvince]		AS StateOrProvince,
					F.[CountryCode]			AS CountryCode,
					F.[ZipCode]				AS ZipCode,
					F.[IsEnabled]			AS IsEnabled
				FROM [dbo].[Facility] F WITH(NOLOCK)
					INNER JOIN @facilityInfo FI ON  FI.[FacilityId] = F.[ID]
				END
        END
    ELSE
        BEGIN
            INSERT INTO #UpdatedFacilities
            SELECT
                F.[ID]					AS Id,
				F.[SourceFacilityId]	AS SourceFacilityId,
				F.[Name]				AS Name,
				F.[AddressLine]			AS AddressLine,
				F.[City]				AS City,
				F.[StateOrProvince]		AS StateOrProvince,
				F.[CountryCode]			AS CountryCode,
				F.[ZipCode]				AS ZipCode,
				F.[IsEnabled]			AS IsEnabled
            FROM [dbo].[Facility] F WITH(NOLOCK)
				INNER JOIN @facilityInfo FI ON  FI.[FacilityId] = F.[ID]
        END

    IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'Multilocation_Main')
		BEGIN
			IF EXISTS (SELECT TOP 1 ID FROM Multilocation_Main)
			BEGIN
				INSERT INTO #NewFacilities
				SELECT
					FI.[FacilityId]		AS ID,
					ML.[locationName]	AS Name,
					ML.[Address1]		AS AddressLine,
					ML.[City]			AS City,
					ML.[State_Province]	AS StateOrProvince,
					ML.[Country]		AS CountryCode,
					ML.[postCode]		AS ZipCode,
					ML.[locationTag]	AS SourceFacilityId
				FROM [dbo].[Multilocation_Main] ML
					INNER JOIN @facilityInfo FI ON  FI.[SourceFacilityId] = ML.[locationTag]
					WHERE FI.[FacilityId] NOT IN (SELECT [ID] FROM [dbo].[Facility] WITH(NOLOCK))
			END
			ELSE 
			BEGIN
				INSERT INTO #NewFacilities
				SELECT
					[FacilityId]		AS ID,
					[Name]				AS Name,
					NULL				AS AddressLine,
					NULL				AS City,
					NULL				AS StateOrProvince,
					NULL				AS CountryCode,
					NULL				AS ZipCode,
					[SourceFacilityId]	AS SourceFacilityId
				FROM @facilityInfo
			    WHERE [FacilityId] NOT IN (SELECT [ID] FROM [dbo].[Facility] WITH(NOLOCK))
			END
        END
    ELSE
        BEGIN
            INSERT INTO #NewFacilities
            SELECT
				[FacilityId]		AS ID,
				[Name]				AS Name,
				NULL				AS AddressLine,
				NULL				AS City,
				NULL				AS StateOrProvince,
				NULL				AS CountryCode,
				NULL				AS ZipCode,
				[SourceFacilityId]	AS SourceFacilityId
			FROM @facilityInfo
			    WHERE [FacilityId] NOT IN (SELECT [ID] FROM [dbo].[Facility] WITH(NOLOCK))
        END


	--Update matching Facilities
	IF @IsError = 0
		BEGIN		
			SET @blockName = 'UpdateFacilities'; SET @startTime = GETDATE();
			BEGIN TRY	

				UPDATE F 
				SET
					[Id] = F.[Id],
					[SourceFacilityId] = UF.[SourceFacilityId],
					--[Name] = UF.[Name],
					[AddressLine] = UF.[AddressLine],
					[City] = UF.[City],
					[StateOrProvince] = UF.[StateOrProvince],
					[CountryCode] = UF.[CountryCode],
					[ZipCode] = UF.[ZipCode],
					[Source] = 'LabelTraxx',
					[ModifiedOnUTC] = GETUTCDATE()
				FROM [dbo].[Facility] F WITH(NOLOCK)
				    INNER JOIN #UpdatedFacilities UF ON UF.[Id] = F.[ID]
					
			SET @infoStr = 'TotalRowsAffected|' +  CONVERT(VARCHAR, @@ROWCOUNT)
				
			END TRY
			BEGIN CATCH
	--		==================================[Do not change]================================================
				SET @IsError = 1; --Rollback;
				SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(VARCHAR, ERROR_LINE())
	--		=======================[Concate more error strings after this]===================================

			END CATCH
			INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
		END

	--Insert new facilities
	IF @IsError = 0
		BEGIN		
			SET @blockName = 'Insert New Facilities'; SET @startTime = GETDATE();
			BEGIN TRY	
				
				INSERT INTO [dbo].[Facility]
					   ([ID],[Name],[TenantId],[AddressLine],[City],[StateOrProvince],[CountryCode],[ZipCode],[TimeZone],[IsEnabled],[SourceFacilityId],[Source],[CreatedOnUTC],[ModifiedOnUTC])
				SELECT
						 [ID],					--id
						 [Name],				--name
						 @TenantId,				--tenantid
						 [AddressLine],			--addressline
						 [City],				--city
						 [StateOrProvince],		--sop
						 [CountryCode],			--countrycode
						 [ZipCode],				--zipcode
						 NULL,					--timezone
						 1,						--isEnabled
						 [SourceFacilityId],	--sourceFacilityId
						 'LabelTraxx',			--source
						 GETUTCDATE(),			--createdOnUTC
						 GETUTCDATE()			--modifiedOnUTC
				FROM #NewFacilities

					
			SET @infoStr = 'TotalRowsAffected|' +  CONVERT(VARCHAR, @@ROWCOUNT)

			END TRY
			BEGIN CATCH
	--		==================================[Do not change]================================================
				SET @IsError = 1; --Rollback;
				SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(VARCHAR, ERROR_LINE())
	--		=======================[Concate more error strings after this]===================================
			END CATCH
			INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
	END
	

--	    ========================[final commit log (do not change)]=======================================
	IF @IsError = 0
	BEGIN
		--COMMIT;
		INSERT INTO @__ErrorInfoLog VALUES(@corelationId, 'dbLog', @tenantId, 'database', 'Commit-Applicable', 0, GETUTCDATE(), 
			@spName, 'final-commit', 'info', 'message|all blocks completed without any error')
	END
	SELECT *, 'tbl_ErrorInfoLog' as __dataset_tableName FROM @__ErrorInfoLog AS ErrorInfoLog;
--		=================================================================================================
END
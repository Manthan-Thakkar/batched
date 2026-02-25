CREATE PROCEDURE [dbo].[spGetFacilityData]
	-- Standard parameters for all stored procedures
	@TenantId		NVARCHAR(36),
	@CorelationId   VARCHAR(100)
AS	
BEGIN

	SET NOCOUNT ON;

	BEGIN
--	==============================logging variables (do not change)=======================================
	DECLARE 
		@spName					VARCHAR(100) = 'spGetFacilityData',
		@__ErrorInfoLog			__ErrorInfoLog,
		@maxCustomMessageSize	INT = 4000, --keep this exactly same as 4000
		@blockName				VARCHAR(100),
		@warningStr				NVARCHAR(4000),
		@infoStr				NVARCHAR(4000),
		@errorStr				NVARCHAR(4000),
		@IsError				BIT = 0,
		@startTime				DATETIME;
--	======================================================================================================
	END

	IF @IsError = 0	
	BEGIN
		SET @blockName = 'GetFacilityData'; SET @startTime = GETUTCDATE();
		BEGIN TRY

		IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'Multilocation_Main')
			BEGIN
				IF EXISTS (SELECT TOP 1 ID FROM Multilocation_Main)
				BEGIN
					SELECT
						ISNULL(F.[ID], FL.[ID])	AS Id,
						ML.[locationTag]		AS SourceFacilityId,
						ML.[locationName]		AS Name,
						ML.[Address1]			AS AddressLine,
						ML.[State_Province]		AS StateOrProvince,
						ML.[Country]			AS CountryCode,
						ML.[postCode]			AS ZipCode,
						ML.[City]				AS City,
						'tbl_Facility'			AS __dataset_tableName
					FROM [dbo].[Multilocation_Main] ML
						LEFT JOIN [dbo].[Facility] F ON ML.[locationTag] = F.[SourceFacilityId]
						LEFT JOIN [dbo].[Facility] FL ON ML.[locationName] = FL.[Name]
				END
				ELSE 
				BEGIN
					SELECT
					[ID]					AS Id,
					[SourceFacilityId]		AS SourceFacilityId,
					[Name]					AS Name,
					[AddressLine]			AS AddressLine,
					[StateOrProvince]		AS StateOrProvince,
					[CountryCode]			AS CountryCode,
					[ZipCode]				AS ZipCode,
					[City]					AS City,
					'tbl_Facility'			AS __dataset_tableName
					FROM [dbo].[Facility]
				END
			END
		ELSE
			BEGIN
				SELECT
					[ID]					AS Id,
					[SourceFacilityId]		AS SourceFacilityId,
					[Name]					AS Name,
					[AddressLine]			AS AddressLine,
					[StateOrProvince]		AS StateOrProvince,
					[CountryCode]			AS CountryCode,
					[ZipCode]				AS ZipCode,
					[City]					AS City,
					'tbl_Facility'			AS __dataset_tableName
				FROM [dbo].[Facility]
			END
		
		SET @infoStr = 'TotalRowsAffected|' +  CONVERT(VARCHAR, @@ROWCOUNT)

		END TRY
		BEGIN CATCH
--		==================================[Do not change]================================================
			SET @IsError = 1; ROLLBACK;
			SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(VARCHAR, ERROR_LINE())
--		=======================[Concate more error strings after this]===================================
        --	SET @ErrorStr = @ErrorStr + '#Some_More_Infos|Some_Useful_value'	
		END CATCH
		INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
	END

	
--	    ========================[final commit log (do not change)]=======================================
	IF @IsError = 0
	BEGIN
		INSERT INTO @__ErrorInfoLog VALUES(@corelationId, 'dbLog', @tenantId, 'database', 'Commited', 0, GETUTCDATE(), 
			@spName, 'final-commit', 'info', 'message|all blocks completed without any error')
	END
	SELECT *, 'tbl_ErrorInfoLog' AS __dataset_tableName FROM @__ErrorInfoLog AS ErrorInfoLog;
--		=================================================================================================

END
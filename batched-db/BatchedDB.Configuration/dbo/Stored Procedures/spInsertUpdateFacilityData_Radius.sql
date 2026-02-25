CREATE PROCEDURE [dbo].[spInsertUpdateFacilityData_Radius]
	@facilities AS [dbo].[udt_FacilityData] readonly,	
	@TenantId		nvarchar(36),
	@CorelationId	varchar(100)
AS
BEGIN

	SET NOCOUNT ON;

	BEGIN
--	==============================logging variables=======================================
	DECLARE 
		@spName					varchar(100) = 'spInsertUpdateFacilityData_Radius',
		@__ErrorInfoLog			__ErrorInfoLog,
		@maxCustomMessageSize	int = 4000,
		@blockName				varchar(100),
		@warningStr				nvarchar(4000),
		@infoStr				nvarchar(4000),
		@errorStr				nvarchar(4000),
		@IsError				bit = 0,
		@startTime				datetime;
--	======================================================================================================
	END

	SET NOCOUNT ON;

	
	--Identify matching users
	SELECT F.* 
		INTO #MatchingFacilities
		FROM Facility F WITH(NOLOCK)
		INNER JOIN @facilities FT ON f.SourceFacilityId = ft.SourceFacilityId AND F.Source = 'Radius'


	--Update matching Facilities
	IF @IsError = 0
		BEGIN		
			SET @blockName = 'UpdateFacilities'; SET @startTime = GETUTCDATE();
			Begin TRY	

				UPDATE F 
				SET
					[Name] = FT.Name,
					[AddressLine] = FT.AddressLine,
					[City] = FT.City,
					[StateOrProvince] = FT.StateOrProvince,
					[CountryCode] = FT.CountryCode,
					[ZipCode] = FT.ZipCode,
					[ModifiedOn] = GETUTCDATE()
				FROM Facility F
				INNER JOIN #MatchingFacilities MFT ON MFT.SourceFacilityId = F.SourceFacilityId
				INNER JOIN @facilities FT on FT.SourceFacilityId = F.SourceFacilityId
					
			SET @infoStr = 'TotalRowsAffected|' +  CONVERT(varchar, @@ROWCOUNT)
				
			END TRY
			Begin CATCH
	--		==================================[Do not change]================================================
				SET @IsError = 1; --Rollback;
				SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
	--		=======================[Concate more error strings after this]===================================

			END CATCH
			INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
		END

	--Insert new facilities
	IF @IsError = 0
		BEGIN		
			SET @blockName = 'Insert New Facilities'; SET @startTime = GETUTCDATE();
			Begin TRY	
				SELECT
					[FacilityId],
					[Name],
					[AddressLine],
					[City],
					[StateOrProvince],
					[CountryCode],
					[ZipCode],
					[SourceFacilityId]
				INTO #NewFacilities
				FROM @facilities f
				WHERE f.SourceFacilityId NOT IN (SELECT SourceFacilityId from Facility where Source = 'Radius')

				
				INSERT INTO [dbo].[Facility]
					   ([ID],
					   [Name],
					   [TenantId],
					   [AddressLine],
					   [City],
					   [StateOrProvince],
					   [CountryCode],
					   [ZipCode],
					   [IsEnabled],
					   [CreatedOn],
					   [ModifiedOn],
					   [SourceFacilityId],
					   [Source])
				 SELECT
						[FacilityId],
						[Name],
						@TenantId,
						[AddressLine],
						[City],
						[StateOrProvince],
						[CountryCode],
						[ZipCode],
						1,
						GETUTCDATE(),
						GETUTCDATE(),
						SourceFacilityId,
						'Radius'
				FROM #NewFacilities

					
			SET @infoStr = 'TotalRowsAffected|' +  CONVERT(varchar, @@ROWCOUNT)

			END TRY
			Begin CATCH
	--		==================================[Do not change]================================================
				SET @IsError = 1; --Rollback;
				SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
	--		=======================[Concate more error strings after this]===================================
			--	SET @ErrorStr = @ErrorStr + '#Some_More_Infos|Some_Useful_value'	
			END CATCH
			INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
	END
	
	DROP TABLE IF exists #MatchingFacilities
	DROP TABLE IF EXISTS #NewFacilities

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
CREATE PROCEDURE [dbo].[spImportFacilityData_Radius]
	@TenantId		nvarchar(36),
	@CorelationId	varchar(100),
	@facilityInfo	udt_FacilityInfo READONLY
AS
BEGIN

	SET NOCOUNT ON;

	BEGIN
--	==============================logging variables=======================================
	DECLARE 
		@spName					varchar(100) = 'spImportFacilityData_Radius',
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

	--Update matching Facilities
	IF @IsError = 0
		BEGIN		
			SET @blockName = 'UpdateFacilities'; SET @startTime = GETUTCDATE();
			Begin TRY	

				UPDATE F 
				SET
					[Id] = FI.FacilityId,
					[Name] = P.PlantName,
					[AddressLine] = A.Address1,
					[City] = A.Town,
					[StateOrProvince] = A.CountyCode,
					[CountryCode] = A.CountyCode,
					[ZipCode] = A.PostCode,
					[Source] = 'Radius',
					[ModifiedOnUTC] = GETUTCDATE()
				FROM Facility F
				INNER JOIN PM_Plant P ON P.PlantCode = F.SourceFacilityId
				INNER JOIN PV_Address A ON P.AddressNum = A.AddressNum
				INNER JOIN @facilityInfo FI ON  FI.SourceFacilityId = F.SourceFacilityId 
					
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
				
				INSERT INTO [dbo].[Facility]
					   ([ID],[Name],[TenantId],[AddressLine],[City],[StateOrProvince],[CountryCode],[ZipCode],[TimeZone],[IsEnabled],[SourceFacilityId],[Source],[CreatedOnUTC],[ModifiedOnUTC])
				SELECT
						 FI.FacilityId, --id
						 P.PlantName, --name
						 @TenantId, --tenantid
						 A.Address1, --addressline
						 A.Town, --city
						 A.CountyCode, --sop
						 A.CountryCode, --countrycode
						 A.PostCode, --zipcode
						 null, --timezone
						 1,
						 P.PlantCode, --sourceFacilityId
						 'Radius', --source
						 GETUTCDATE(),
						 GETUTCDATE()
				FROM PM_Plant P
				INNER JOIN PV_Address A ON P.AddressNum = A.AddressNum
				INNER JOIN @facilityInfo FI ON  FI.SourceFacilityId = P.PlantCode
				WHERE P.PlantCode NOT IN (SELECT SourceFacilityId from Facility where Source = 'Radius')

					
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
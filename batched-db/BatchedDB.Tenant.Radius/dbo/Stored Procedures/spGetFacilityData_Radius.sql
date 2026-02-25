CREATE PROCEDURE [dbo].[spGetFacilityData_Radius]
	-- Standard parameters for all stored procedures
	@TenantId		NVARCHAR(36),
	@CorelationId   VARCHAR(100)
AS	
BEGIN

	SET NOCOUNT ON;

	BEGIN
--	==============================logging variables (do not change)=======================================
	DECLARE 
		@spName					VARCHAR(100) = 'spGetFacilityData_Radius',
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
		SET @blockName = 'Get Facility Data'; SET @startTime = GETDATE();
		BEGIN TRY		
		 SELECT
			P.PlantCode as SourcefacilityId,
			P.PlantName as Name,
			A.Address1 as AddressLine,
			A.CountyCode as StateOrProvince,
			A.CountryCode,
			A.PostCode as ZipCode,
			A.Town as City,
			'tbl_Facility' as __dataset_tableName
		 FROM PM_Plant P
		 INNER JOIN PV_Address A ON P.AddressNum = A.AddressNum
		
		SET @infoStr = 'TotalRowsAffected|' +  CONVERT(varchar, @@ROWCOUNT)

		END TRY
		BEGIN CATCH
--		==================================[Do not change]================================================
			SET @IsError = 1; Rollback;
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
	SELECT *, 'tbl_ErrorInfoLog' as __dataset_tableName FROM @__ErrorInfoLog AS ErrorInfoLog;
--		=================================================================================================


	DROP TABLE IF EXISTS #FilteredEquipments


END
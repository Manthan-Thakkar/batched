CREATE PROCEDURE [dbo].[spGetRawUserData_Radius]
	-- Standard parameters for all stored procedures
	@TenantId		nvarchar(36),
	@CorelationId	varchar(100)
AS
BEGIN

	SET NOCOUNT ON;

	BEGIN
--	==============================logging variables (do not change)=======================================
	DECLARE 
		@spName					varchar(100) = 'spGetRawUserData_Radius',
		@__ErrorInfoLog			__ErrorInfoLog,
		@maxCustomMessageSize	int = 4000, --keep this exactly same as 4000
		@blockName				varchar(100),
		@warningStr				nvarchar(4000),
		@infoStr				nvarchar(4000),
		@errorStr				nvarchar(4000),
		@IsError				bit = 0,
		@startTime				datetime;
--	======================================================================================================
	END
	
	SET NOCOUNT ON;
	BEGIN TRANSACTION;
	
	IF @IsError = 0	
		BEGIN		
			SET @blockName = 'GetUserList'; SET @startTime = GETDATE();
			Begin TRY	

				TRUNCATE TABLE PM_User_Temp

				INSERT INTO PM_User_Temp
				SELECT
					PU.UserCode,
					PU.UserName,
					PU.Email,
					PU.OfficePhone,
					PU.TableRecId,
					HASHBYTES(
						'SHA2_256',
						CONCAT(
							ISNULL(PU.UserCode,''), '|',
							ISNULL(PU.UserName,''), '|',
							ISNULL(PU.Email,''), '|',
							ISNULL(PU.OfficePhone,''), '|',
							ISNULL(PU.TableRecId,''), '|'
						)
					) AS HASHVALUE
				FROM PM_User PU
				WHERE NOT(LEN(ISNULL(PU.UserName,'')) <= 1);

				SELECT	UserCode AS Number, 
						LEFT(UserName, CHARINDEX(' ', UserName + ' ')) as FirstName,
						SUBSTRING(UserName, CHARINDEX(' ', UserName + ' '), LEN(UserName)) as LastName,
						Email AS E_Mail_Address,
						OfficePhone AS Phone,
						CONVERT(bit, 0) AS Inactive,
						TableRecId AS SourceRecordId,
						NULL AS PurchaseBtn, 
						'tbl_PM_User' as __dataset_tableName
				FROM  #PM_User_temp PU
				LEFT JOIN UserHashValues UHV
						   ON UHV.SourceRecordId = PU.TableRecId
				WHERE (UHV.HashValue IS NULL OR PU.HashValue <> UHV.HashValue);

				SET @infoStr = 'TotalRowsAffected|' +  CONVERT(varchar, @@ROWCOUNT)


				--- Invalid User null check
				Declare @FirstNameNull int, @LastNameNull int

				SELECT	
					@FirstNameNull = ISNULL(SUM(CASE WHEN LEN(IsNull(LEFT(UserName, CHARINDEX(' ', UserName + ' ')), '')) <=1 THEN 1 ELSE 0 END),0),
					@LastNameNull = ISNULL(SUM(CASE WHEN LEN(IsNull(SUBSTRING(UserName, CHARINDEX(' ', UserName + ' '), LEN(UserName)), '')) <=1 THEN 1 ELSE 0 END),0) 
				FROM PM_User 
				WHERE NOT(LEN(ISNULL(UserName,'')) <= 1);
			
				IF(@FirstNameNull > 0 OR @LastNameNull > 0)
					BEGIN
						SET  @warningStr = @infoStr 
											+ '#' + 'TotalFirstNamesNull_PM_User|'+ Convert(varchar, @FirstNameNull)
											+ '#' + 'TotalLastNamesNull_PM_User|'+ Convert(varchar, @LastNameNull)
					END
				-----
			

			END TRY
			Begin CATCH
	--		==================================[Do not change]================================================
				SET @IsError = 1; Rollback;
				SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
	--		=======================[Concate more error strings after this]===================================
			--	SET @ErrorStr = @ErrorStr + '#Some_More_Infos|Some_Useful_value'	
			END CATCH
			INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
		END
	
--	    ========================[final commit log (do not change)]=======================================
	IF @IsError = 0
	BEGIN
		COMMIT;
		INSERT INTO @__ErrorInfoLog VALUES(@corelationId, 'dbLog', @tenantId, 'database', 'Commited', 0, GETUTCDATE(), 
			@spName, 'final-commit', 'info', 'message|all blocks completed without any error')
	END
	SELECT *, 'tbl_ErrorInfoLog' as __dataset_tableName FROM @__ErrorInfoLog AS ErrorInfoLog;
--		=================================================================================================
END



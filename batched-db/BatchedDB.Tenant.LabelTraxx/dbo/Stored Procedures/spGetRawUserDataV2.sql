CREATE PROCEDURE [dbo].[spGetRawUserDataV2]
	-- Standard parameters for all stored procedures
	@TenantId		nvarchar(36),
	@CorelationId	varchar(100)
AS
BEGIN

	SET NOCOUNT ON;

	BEGIN
--	==============================logging variables (do not change)=======================================
	DECLARE 
		@spName					varchar(100) = 'spGetRawUserDataV2',
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
			TRUNCATE TABLE [AssociateTemp]
					INSERT INTO [AssociateTemp] 
					SELECT 
						A.PK_UUID,
						A.NUMBER,
						A.FIRSTNAME,
						A.LASTNAME,
						A.E_MAIL_ADDRESS,
						A.PHONE,
						A.INACTIVE,
						A.PURCHASEBTN,
						HASHBYTES(
							'SHA2_256',
							CONCAT(
								ISNULL(A.FIRSTNAME,''), '|',
								ISNULL(A.LASTNAME,''), '|',
								ISNULL(A.E_MAIL_ADDRESS,''), '|',
								ISNULL(A.PHONE,''), '|',
								ISNULL(A.INACTIVE,''), '|',
								ISNULL(A.PURCHASEBTN,'')
							)
						) AS HASHVALUE
					FROM ASSOCIATE A
					WHERE NOT (LEN(ISNULL(A.FirstName,'')) <= 1 OR LEN(ISNULL(A.LastName,'')) <= 1);
		
					SELECT 
						A.PK_UUID,
						A.Number,
						A.FirstName,
						A.LastName,
						A.E_Mail_Address,
						A.Phone,
						A.Inactive,
						A.PurchaseBtn,    
						A.HashValue,
						'tbl_Associate' AS __dataset_tableName
					FROM [AssociateTemp] A
					LEFT JOIN UserHashValues UHV
						   ON UHV.PK_UUID = A.PK_UUID
					WHERE (UHV.HashValue IS NULL OR A.HashValue <> UHV.HashValue);

					SET @infoStr = 'TotalRowsAffected|' +  CONVERT(varchar, @@ROWCOUNT)


					--- Invalid User null check
					Declare @FirstNameNull int, @LastNameNull int

					SELECT	
						@FirstNameNull = ISNULL(SUM(CASE WHEN LEN(IsNull(FirstName,'')) <=1 THEN 1 ELSE 0 END),0),
						@LastNameNull = ISNULL(SUM(CASE WHEN LEN(IsNull(LastName,'')) <=1 THEN 1 ELSE 0 END),0) 
					from Associate 
					where LEN(IsNull(FirstName,'')) <=1 or LEN(IsNull(LastName,'')) <=1
			
					IF(@FirstNameNull > 0 OR @LastNameNull > 0)
						BEGIN
							SET  @warningStr = @infoStr 
												+ '#' + 'TotalFirstNamesNull_Associate|'+ Convert(varchar, @FirstNameNull)
												+ '#' + 'TotalLastNamesNull_Associate|'+ Convert(varchar, @LastNameNull)
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

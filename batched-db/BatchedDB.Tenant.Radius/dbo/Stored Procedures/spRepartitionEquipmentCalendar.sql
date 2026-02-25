CREATE PROCEDURE [dbo].[spRepartitionEquipmentCalendar]
AS			
BEGIN
	SET NOCOUNT ON;
		
	BEGIN TRANSACTION;

	Begin TRY	
	
	DROP TABLE IF EXISTS EquipmentCalendar

	IF EXISTS (SELECT * FROM sys.partition_schemes WHERE name = N'sEquipmentCalendar')
	DROP PARTITION SCHEME sEquipmentCalendar;
	IF EXISTS (SELECT * FROM sys.partition_functions WHERE name = N'pfEquipmentCalendar')
	DROP PARTITION FUNCTION pfEquipmentCalendar;
	

	DECLARE @sqlcmd nvarchar(MAX),@ids nvarchar(MAX);
	SELECT @IDS = coalesce(@IDS + ',', '') + a.ID FROM 
				(Select TOP 1000  '''' + EM.ID  + '''' as ID FROM EquipmentMaster EM
				WHERE 
					EM.IsEnabled = 1
					ORDER BY EM.SourceEquipmentId
				) a

	PRINT @IDS
	SET @sqlcmd = N'CREATE PARTITION FUNCTION pfEquipmentCalendar(varchar(36)) AS RANGE LEFT FOR VALUES (' + @ids + N')' ;
	PRINT @sqlcmd
	EXEC SP_EXECUTESQL @sqlcmd 

	CREATE PARTITION SCHEME sEquipmentCalendar
	AS PARTITION pfEquipmentCalendar
	ALL TO ([Primary]);

	CREATE TABLE EquipmentCalendar
	(
		EquipmentId			VARCHAR(36)			NOT NULL,
		SourceEquipmentId	NVARCHAR(4000)		NOT NULL,
		TheDateTime			DATETIME			NOT NULL, 
		TimeIndex			BIGINT				NOT NULL,
		AdjustedTimeIndex	BIGINT				NULL,
		Available			BIT					NOT NULL,
		DowntimeReason		VARCHAR(100)		NULL
	) ON sEquipmentCalendar(EquipmentId)

	CREATE NONCLUSTERED INDEX [IX_EquipmentCalendar_EquipmentId_TheDateTime_Available] ON [dbo].[EquipmentCalendar] (
		[EquipmentId],
		[TheDateTime] DESC,
		[Available]
		) INCLUDE (
		[AdjustedTimeIndex]
		);
		
		COMMIT;
	END TRY
	Begin CATCH
		Rollback;
	END CATCH
END



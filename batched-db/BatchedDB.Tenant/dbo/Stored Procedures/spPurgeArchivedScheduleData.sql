CREATE PROCEDURE [dbo].[spPurgeArchivedScheduleData] 
	@RetentionDays int, 
	@CurrentTime datetime, 
	@facilities AS UDT_SINGLEFIELDFILTER readonly
AS 
BEGIN  
	DECLARE @DeletedRecordsCount int;

	DELETE sa FROM ScheduleArchive sa
	INNER JOIN EquipmentMaster em on sa.OriginalEquipmentId = em.ID 
    WHERE (DATEDIFF(DAY, ArchivedOn, @CurrentTime) > @RetentionDays) 
		AND ((SELECT Count(1) FROM @facilities) = 0  OR em.FacilityId IN (SELECT field FROM @facilities))
	
	SET @DeletedRecordsCount = @@ROWCOUNT;

	SELECT 
		@DeletedRecordsCount AS DeletedRecordsCount, 
		'tbl_purgeArchivedScheduleResult' AS __dataset_tableName
END
CREATE PROCEDURE [dbo].[spUpdateTicketMovement]
	@ticketMovement udt_ScheduleReportUpdate ReadOnly
AS
BEGIN

BEGIN TRY
    BEGIN TRANSACTION
				
				---- Update the ticket movement
				UPDATE SR
				set
					SR.StartsAt = TM.StartsAt,
					SR.EndsAt = TM.EndsAt,
					SR.EquipmentId = TM.EquipmentId,
					SR.FeasibilityOverride = TM.FeasibilityOverride,
					SR.IsUpdated = TM.IsUpdated,
					SR.IsPinned = TM.IsPinned,
					SR.PinType = TM.PinType,
					SR.MasterRollNumber = TM.MasterRollNumber,
					SR.ModifiedOn = TM.ModifiedOn
				from
				ScheduleReport SR
				inner join @ticketMovement TM on SR.Id = TM.Id
				Where Tm.IsNew = 0

				--- Insert if new
				Insert into ScheduleReport  ([Id],[EquipmentId],[SourceTicketId],[TaskName],[StartsAt],[EndsAt],[ChangeoverMinutes],[TaskMinutes],[IsPinned],[FeasibilityOverride],[IsUpdated],[IsCalculated],[MasterRollNumber],[CreatedOn],[ModifiedOn],[PinType],[ChangeoverCount],[ChangeoverDescription])    
                Select
                T.Id,
                T.EquipmentId,
                T.SourceTicketId,
                T.TaskName,
                T.StartsAt,
                T.EndsAt,
                T.ChangeoverMinutes,
                T.TaskMinutes,
                T.IsPinned,
                CASE
                    WHEN T.FeasibilityOverride = 1 THEN 1
                    ELSE IIF(FR.RouteFeasible = 0, 1, 0)
                END,
                T.IsUpdated,
                T.IsCalculated,
                T.MasterRollNumber,
                T.CreatedOn,
                T.ModifiedOn,
                T.PinType,
                T.ChangeoverCount,
                T.ChangeoverDescription
                from     
                @ticketMovement T
                LEFT JOIN TicketMaster TM on T.SourceTicketId = TM.SourceTicketId
                LEFT JOIN TicketTask TT on TM.ID = TT.TicketId and T.TaskName = TT.TaskName
                LEFT JOIN FeasibleRoutes FR on FR.TicketId = TM.ID and FR.EquipmentId = T.EquipmentId and FR.TaskId = TT.Id
                Where IsNew = 1

			    select 1 AS IsSuccessfull ,  'tbl_status' AS __dataset_tableName

	 
					COMMIT TRANSACTION;
END TRY
BEGIN CATCH 

						ROLLBACK TRANSACTION;

 select 0 AS IsSuccessfull ,  'tbl_status' AS __dataset_tableName

END CATCH

END

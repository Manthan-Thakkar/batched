CREATE   PROCEDURE [dbo].[proc_OpenTickets_Table]
AS 
BEGIN -- begin procedure

	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION

	---- clear out the All Open Ticket Tasks Table, and load the new data
	--	IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'AllOpenTicketTasks_Table')
	--		BEGIN

				
	--				print 'truncate and insert new records...';
	--				truncate table dbo.AllOpenTicketTasks_Table;
	--				insert into
	--					dbo.AllOpenTicketTasks_Table
	--				select 
	--					*
 --                       , Getdate() as [Last Refresh Time]
	--				from 
	--					[dbo].[AllOpenTicketTasks]
	--				;


	--		END -- end the clause to truncate old data
	--	ELSE -- if the table does not exist, create a new table
	--		BEGIN

	--			print 'creating new table';
	--			select 
	--				*
 --                   , Getdate() as [Last Refresh Time]
	--			into 
	--				dbo.AllOpenTicketTasks_Table
	--			from 
	--				[dbo].[AllOpenTicketTasks]
	--		END 


            -- clear out the open Tickets table, and load the new data
		DECLARE @counter int

	Set @counter = (Select count(*)
From TaskBatch
Where DataImportCompleteTS IS NULL and DataImportTS IS NOT NULL and TaskBatchTS > DATEADD(ss, -60*30, getdate()) and TriggerType='APP')

	WHILE @counter > 0
		BEGIN
			WAITFOR DELAY '00:00:30'
			Set @counter = (Select count(*)
From TaskBatch
Where DataImportCompleteTS IS NULL and DataImportTS IS NOT NULL and TaskBatchTS > DATEADD(ss, -60*30, getdate()) and TriggerType='APP')
		END
		
		IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'OpenTickets_Table')
			BEGIN

				
					print 'truncate and insert new records...';
					drop table dbo.OpenTickets_Table;
					select 
						*
                        , Getdate() as [Last Refresh Time]
					Into dbo.OpenTickets_Table
					from 
						[dbo].[openTickets]
					;


			END -- end the clause to truncate old data
		ELSE -- if the table does not exist, create a new table
			BEGIN

				print 'creating new table';
				select 
					*
                    , Getdate() as [Last Refresh Time]
				into 
					dbo.OpenTickets_Table
				from 
					[dbo].[openTickets]
			END 

		print 'COMPLETE!';

		IF XACT_STATE() > 0 COMMIT TRANSACTION
	
	END TRY

	BEGIN CATCH
		IF XACT_STATE() <> 0 ROLLBACK TRANSACTION
	END CATCH
END -- end procedure

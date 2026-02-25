CREATE TYPE [dbo].[udt_ScheduleOverride] AS TABLE(
  TicketId varchar(36) NOT NULL,
  TaskName nvarchar(255) NOT NULL,
  EquipmentId varchar(36)  NULL,
  StartsAt datetime  NULL,
  EndsAt datetime  NULL,
  Notes nvarchar(4000) NOT NULL
)
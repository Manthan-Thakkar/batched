CREATE VIEW view_ScheduleReportData AS
SELECT DISTINCT
    -- Ticket Fields 
	SR.Id AS ScheduleId,
    SR.SourceTicketId AS TicketNumber,
	SR.TaskName as TaskName,
	EM.Name as EquipmentName,
	Em.ID as EquipentId,
	em.FacilityId as FacilityId,
	EM.WorkcenterTypeId AS WorkcenterId,
	SR.StartsAt as StartsAt,
	SR.EndsAt as EndsAt,
	SR.ChangeoverMinutes as ChangeoverMinutes,
	SR.TaskMinutes as TaskMinutes,
	TTT.IsComplete AS IsComplete,
	TS.ShipByDateTime,
	TTT.EstMaxDueDateTime,
	em.WorkCenterName as WorkcenterName,
	SO.Notes as SchedulingNotes,
	SR.ForcedGroup as ForcedGroup,
	SR.IsPinned as IsPinned,
	SR.PinType as PinType,
    Case When Sr.IsPinned = 1 Then  'Locked' Else 'Unlocked' END as LockStatus,
    Case When Sr.IsPinned = 1 Then  Sr.PinType Else NULL END as LockType,
	CASE WHEN SO.ID is not null THEN 1 ELSE 0 END as ManuallyScheduled,
	SR.FeasibilityOverride as FeasibilityOverride,
	SR.MasterRollNumber as MasterRollNumber,
	(CASE WHEN SR.MasterRollNumber is not null THEN CAST(1 as BIT) ELSE CAST(0 as BIT) END) IsMasterRoll,
	CASE 
		WHEN SR.MasterRollNumber is not null AND (TTT.Sequence <> 1 OR SR.MasterRollNumber like 'PRINTED_%') THEN (CAST(1 as bit))
		ELSE (CAST(0 as bit))
	END IsMasterRollGroup,
	em.ID as EquipmentId,
	SR.CreatedOn as RecordCreatedOn
FROM ScheduleReport SR	
INNER JOIN EquipmentMaster EM with (nolock) ON SR.EquipmentId = EM.ID
INNER JOIN TicketMaster TM with (nolock) ON TM.SourceTicketId = SR.SourceTicketId
INNER JOIN ticketshipping ts with (nolock) ON ts.ticketid = TM.ID
LEFT JOIN TicketTask TTT WITH (NOLOCK) ON TTT.TicketId = TM.ID AND TTT.TaskName = SR.TaskName
LEFT join ScheduleOverride SO with (nolock) on TM.ID = SO.TicketId and SR.TaskName = SO.TaskName and SO.IsScheduled = 1





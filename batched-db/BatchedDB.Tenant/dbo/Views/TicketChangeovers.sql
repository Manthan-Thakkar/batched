CREATE View dbo.TicketChangeovers


AS

SELECT 
      TM1.SourceTicketId as NumberFrom 
      ,TM2.SourceTicketId as NumberTo 
      ,MER.[SourceEquipmentId] as PressNumberFrom
      ,cm.[ChangeoverMinutes] as changeoverMinutes
      ,0 as fixedchangeoverMinutes -- update if used based on client needs 
	  ,cm.[SavedChangeoverMinutes] as savedchangeoverMinutes
      ,MER.workcentername as TaskWorkCenterFrom
  FROM [ChangeoverMinutes] CM
  left join [EquipmentMaster] MER on MER.ID = cm.EquipmentId
  left join TicketMaster TM1 on TM1.ID = TicketIdFrom
  left join TicketMaster TM2 on TM2.ID = TicketIdTo

Create table TaskClassificationGroup
(
  Id					VARCHAR(36)	 CONSTRAINT [PK_TaskClassificationGroupID] PRIMARY KEY NOT NULL, 
  WorkcenterTypeId		VARCHAR(36)  CONSTRAINT [FK_TaskClassificationGroup_WorkcenterTypeId] FOREIGN KEY REFERENCES WorkcenterType(Id),
  TicketAttributeId		VARCHAR(36)  CONSTRAINT [FK_TaskClassificationGroup_TicketAttributeId] FOREIGN KEY REFERENCES TicketAttribute(Id),
  CreatedOn				DATETIME,
  ModifiedOn			DATETIME
)
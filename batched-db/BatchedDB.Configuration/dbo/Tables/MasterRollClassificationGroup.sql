Create table MasterRollClassificationGroup(
  Id					VARCHAR(36)  CONSTRAINT [PK_MasterRollClassificationGroupId] PRIMARY KEY NOT NULL, 
  WorkcenterTypeId		VARCHAR(36)  CONSTRAINT [FK_MasterRollClassificationGroup_WorkcenterTypeId] FOREIGN KEY REFERENCES WorkcenterType(Id),
  TicketAttributeId		VARCHAR(36)  CONSTRAINT [FK_MasterRollClassificationGroup_TicketAttributeId] FOREIGN KEY REFERENCES TicketAttribute(Id),
  CreatedOn				DATETIME,
  ModifiedOn			DATETIME
)

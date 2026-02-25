  CREATE TABLE ChangeoverMinutes(
  ID VARCHAR(36)  PRIMARY KEY NOT NULL,
  TicketIdFrom varchar(36) NOT NULL,
  TicketIdTo varchar(36) NOT NULL,
  EquipmentId varchar(36) NOT NULL,
  ChangeoverMinutes FLOAT NULL, 
  SavedChangeoverMinutes FLOAT NULL,
  CreatedOn DATETIME,
  ModifiedOn DATETIME,
  [Count] int ,
  Description varchar(4000)
  );
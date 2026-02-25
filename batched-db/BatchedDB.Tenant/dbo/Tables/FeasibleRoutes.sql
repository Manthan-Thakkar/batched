  CREATE TABLE FeasibleRoutes(
  ID VARCHAR(36)  PRIMARY KEY NOT NULL,
  TicketId varchar(36) NOT NULL,
  TaskId varchar(36) NOT NULL,
  EquipmentId varchar(36) NOT NULL,
  CreatedOn DATETIME,
  ModifiedOn DATETIME,
  RouteFeasible bit,
  ConstraintDescription nvarchar(max),
  EstHoursBySpeed REAL NULL
  );
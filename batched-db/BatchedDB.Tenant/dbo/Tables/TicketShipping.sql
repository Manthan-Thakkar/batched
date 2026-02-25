

CREATE TABLE TicketShipping(
  Id VARCHAR(36)  PRIMARY KEY ,
  TicketId VARCHAR(36) UNIQUE FOREIGN KEY REFERENCES TicketMaster(Id),
  Source NVARCHAR(64) ,
  ShipByDateTime datetime NULL,-- Can be null
  ShippedOnDate datetime NULL,-- Can be NULL
  SourceShipAddressId nvarchar(4000) NULL,-- Can be Null
  SourceShipVia nvarchar(4000) NULL,
  DueOnSiteDate DATETIME NULL,
  ShipState NVARCHAR (4000) NULL,
  CreatedOn DATETIME,
  ModifiedOn DATETIME,
  ShippingStatus nvarchar(4000) null,
  ShippingAddress nvarchar(4000) NULL,
  ShippingCity nvarchar(1000) NULL,
  ShippingInstruc nvarchar(4000) Null,
  ShipAttnEmailAddress nvarchar(1000) Null,
  ShipLocation nvarchar(1000) Null,
  ShipZip nvarchar(255) Null,
  BillLocation nvarchar(1000) Null,
  BillAddr1 nvarchar(1000) Null,
  BillAddr2 nvarchar(1000) Null,
  BillCity nvarchar(255) Null,
  BillZip nvarchar(255) Null,
  BillCountry nvarchar(255) Null,
  BillState nvarchar(255) Null,
  ShipCounty nvarchar(255) Null
  )
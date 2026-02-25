CREATE TABLE ClientIPWhiteList(
  Id VARCHAR(36)  PRIMARY KEY NOT NULL,
  ClientId VARCHAR(36) foreign key references Client (Id),
  IpAddressFrom NVARCHAR(100) NOT NULL,
  IpAddressTo NVARCHAR(100) NULL,
  IsAllowed bit NOT NULL,
  IsIpv4 bit NOT NULL,
  Roles NVARCHAR(1000) NULL,
  CreatedOn DATETIME,
  ModifiedOn DATETIME
  );
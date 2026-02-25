CREATE TABLE TicketPreProcess(
  TicketId VARCHAR(36) UNIQUE FOREIGN KEY REFERENCES TicketMaster(Id),
  CreatedOn DATETIME,
  ModifiedOn DATETIME,
  ArtStatus NVARCHAR(4000) NULL, 
  ProofStatus NVARCHAR(4000) NULL,
  ToolStatus NVARCHAR(4000) NULL,

  ArtWorkComplete bit NOT NULL, --received Artwork/full form
  ArtWorkStaged bit NULL, --Artwork/full form

  ProofComplete bit NOT NULL, --received
  ProofStaged bit NULL,

  PlateComplete bit NOT NULL, --received
  PlateStaged bit NULL,

  ToolsReceived bit NOT NULL, --tool/die
  ToolsStaged bit NULL,

  InkReceived bit NOT NULL,
  InkStaged bit NULL,

  StockReceived nvarchar(255) NULL,
  StockStaged nvarchar(255) NULL
  )